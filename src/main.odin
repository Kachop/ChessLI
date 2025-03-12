package main

import "core:fmt"
import "core:os/os2"
import "core:strings"
import "core:encoding/ansi"
import "core:unicode/utf8"

import t "shared:TermCL"
import "core:math"

Mode :: enum {
  SELECT,
  MOVE,
}

GameState :: struct {
  running: bool,
  move_no: u8,
  check: bool,
  to_move: Colour,
  mode: Mode,
  board: Board,
  hovered_file: rune,
  hovered_rank: uint,
  selected_file: rune,
  selected_rank: uint,
  move_option_files: [dynamic]rune,
  move_option_ranks: [dynamic]uint,
  capture_option_files: [dynamic]rune,
  capture_option_ranks: [dynamic]uint,
  last_move: Move,
}

state := GameState{}

BOARD_WIDTH  :: 130
BOARD_HEIGHT :: 64

COLOURS := [][2]t.Color_8{
  {.White, .White},
  {.Black, .Black},
  {.Black, .Cyan},
  {.Black, .Blue},
  {.Red, .Red},
  {.Green, .Green}
}

main :: proc() {
  state.running = true
  state.move_no = 1
  state.to_move = .WHITE
  state.mode = .SELECT
  state.board = getDefaultBoard()
  state.hovered_file = 'a'
  state.move_option_files = [dynamic]rune{}
  state.move_option_ranks = [dynamic]uint{}
  
  s := t.init_screen()
  defer t.destroy_screen(&s)
  t.set_term_mode(&s, .Cbreak)
  t.hide_cursor(true)
  t.clear_screen(&s, .Everything)
  t.blit_screen(&s)

  draw_board(&s)
  draw_info(&s)

  for state.running {
    defer t.blit_screen(&s)

    t.clear_screen(&s, .Everything)

    input, has_input := t.read(&s)
    keys := t.parse_keyboard_input(input)

    if keys.key == .Q {
      state.running = false
    }

    if state.mode == .SELECT {
      handle_select_input(keys.key)
    } else if state.mode == .MOVE {
      //Cycle through the available moves and move the piece
      handle_move_input(keys.key)
    }

    draw_board(&s)
    draw_info(&s)
  }
  //t.clear_screen(&s, .Everything)
  t.hide_cursor(false)
  t.set_term_mode(&s, .Restored)
  fmt.println("Closing program")
}

draw_info :: proc(win: ^t.Screen) {
  x : uint = 2
  y : uint = 70
  
  t.move_cursor(win, y, x)
  t.write(win, fmt.tprintf("Go: %v", state.to_move))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.tprintf("Check: %v", state.check))
  y += 1
  
  t.move_cursor(win, y, x)
  t.write(win, fmt.tprintf("Hover file: %v", state.hovered_file))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.tprintf("Hover rank: %v", state.hovered_rank))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.tprintf("Selected file: %v", state.selected_file))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.tprintf("Selected rank: %v", state.selected_rank))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.tprintf("File diff: %v", abs(cast(int)'d' - cast(int)'e')))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.tprintf("Mode: %v", state.mode))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.tprintf("Available moves: %v", len(state.move_option_files)))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.tprintf("Moves:"))
  y += 1

  for i in 0 ..< len(state.move_option_files) {
    t.move_cursor(win, y, x)
    t.write(win, fmt.tprintf("%v%v", state.move_option_files[i], state.move_option_ranks[i]+1))
    y += 1
  }

  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.tprintf("Available captures: %v", len(state.capture_option_files)))
  y += 1

  t.blit_screen(win)
}

handle_select_input :: proc(key: t.Key) {
  #partial switch key {
  case .W, .Arrow_Up:
    if state.to_move == .WHITE {
      increment_rank_selected()
    } else {
      decrement_rank_selected()
    }
  case .A, .Arrow_Left:
    if state.to_move == .WHITE {
      decrement_file_selected()
    } else {
      increment_file_selected()
    }
  case .S, .Arrow_Down:
    if state.to_move == .WHITE {
      decrement_rank_selected()
    } else {
      increment_rank_selected()
    }
  case .D, .Arrow_Right:
    if state.to_move == .WHITE {
      increment_file_selected()
    } else {
      decrement_file_selected()
    }
  case .Enter:
    state.selected_file = state.hovered_file
    state.selected_rank = state.hovered_rank
    clear(&state.move_option_files)
    clear(&state.move_option_ranks)
    clear(&state.capture_option_files)
    clear(&state.capture_option_ranks)
    switch state.board.piece_map[state.selected_file][state.selected_rank].piece {
    case .PAWN:
      get_pawn_moves_and_captures()
    case .KNIGHT:
      get_knight_moves_and_captures()
    case .BISHOP:
      get_bishop_moves_and_captures()
    case .ROOK:
      get_rook_moves_and_captures()
    case .QUEEN:
      get_bishop_moves_and_captures()
      get_rook_moves_and_captures()
    case .KING:
      get_king_moves_and_captures()
    case .NONE:
    }
    if len(state.move_option_files) > 0 || len(state.capture_option_files) > 0 {
      state.mode = .MOVE
    }
  }
}

handle_move_input :: proc(key: t.Key) {
  #partial switch key {
  case .W, .Arrow_Up:
    if state.to_move == .WHITE {
      increment_rank_move()
    } else {
      decrement_rank_move()
    }
  case .A, .Arrow_Left:
    if state.to_move == .WHITE {
      decrement_file_move()
    } else {
      increment_file_move()
    }
  case .S, .Arrow_Down:
    if state.to_move == .WHITE {
      decrement_rank_move()
    } else {
      increment_rank_move()
    }
  case .D, .Arrow_Right:
    if state.to_move == .WHITE {
      increment_file_move()
    } else {
      decrement_file_move()
    }
  case .Enter:
    saved_state := make(map[rune][dynamic]PieceInfo)
    copy_board(&saved_state, state.board.piece_map)

    if !state.check {
      if check_valid_move_or_capture(state.hovered_file, state.hovered_rank) {
        if state.board.piece_map[state.selected_file][state.selected_rank].piece == .PAWN {
          if abs(cast(int)state.selected_file - cast(int)state.hovered_file) == 1 && abs(cast(int)state.selected_rank - cast(int)state.hovered_rank) == 1 {
            if !check_square_for_piece(state.hovered_file, state.hovered_rank, .WHITE) && !check_square_for_piece(state.hovered_file, state.hovered_rank, .BLACK) {
              state.board.piece_map[state.hovered_file][state.hovered_rank-1 if (state.to_move == .WHITE) else state.hovered_rank+1] = PieceInfo{}
            }
          }
        }
        captured_piece := state.board.piece_map[state.hovered_file][state.hovered_rank]
        state.board.piece_map[state.hovered_file][state.hovered_rank] = state.board.piece_map[state.selected_file][state.selected_rank]
        state.board.piece_map[state.selected_file][state.selected_rank] = PieceInfo{}

        colour: Colour

        if state.to_move == .WHITE {
          colour = .BLACK
        } else {
          colour = .WHITE
        }

        if is_check(colour = colour) {
          state.mode = .SELECT
          state.board.piece_map = saved_state
          state.hovered_file = state.selected_file
          state.hovered_rank = state.selected_rank
        } else {
          state.last_move = Move{
            state.board.piece_map[state.hovered_file][state.hovered_rank].piece,
            state.selected_file,
            state.hovered_file,
            state.selected_rank,
            state.hovered_rank,
          }
          if is_check() {
            state.check = true
            if is_checkmate() {
              state.running = false
            }
          }

          state.mode = .SELECT
          if state.to_move == .WHITE {
            state.to_move = .BLACK
          } else {
            state.to_move = .WHITE
            state.move_no += 1
          }
          temp_file, temp_rank := find_closest_piece('a', 'h', 0, 7, state.to_move)
          if temp_file != -1 {
            state.hovered_file = temp_file
            state.hovered_rank = temp_rank
          }
        }
      }
    } else {
      if check_valid_move_or_capture(state.hovered_file, state.hovered_rank) {
        if state.board.piece_map[state.selected_file][state.selected_rank].piece == .PAWN {
          if abs(cast(int)state.selected_file - cast(int)state.hovered_file) == 1 && abs(cast(int)state.selected_rank - cast(int)state.hovered_rank) == 1 {
            if !check_square_for_piece(state.hovered_file, state.hovered_rank, .WHITE) && !check_square_for_piece(state.hovered_file, state.hovered_rank, .BLACK) {
              state.board.piece_map[state.hovered_file][state.hovered_rank-1 if (state.to_move == .WHITE) else state.hovered_rank+1] = PieceInfo{}
            }
          }
        }
        captured_piece := state.board.piece_map[state.hovered_file][state.hovered_rank]
        state.board.piece_map[state.hovered_file][state.hovered_rank] = state.board.piece_map[state.selected_file][state.selected_rank]
        state.board.piece_map[state.selected_file][state.selected_rank] = PieceInfo{}
        
        colour: Colour

        if state.to_move == .WHITE {
          colour = .BLACK
        } else {
          colour = .WHITE
        }

        if is_check(colour = colour) {
          state.mode = .SELECT
          state.board.piece_map = saved_state
          state.hovered_file = state.selected_file
          state.hovered_rank = state.selected_rank
        } else {
          state.last_move = Move{
            state.board.piece_map[state.hovered_file][state.hovered_rank].piece,
            state.selected_file,
            state.hovered_file,
            state.selected_rank,
            state.hovered_rank,
          }

          state.check = false
          state.mode = .SELECT
          
          if is_check() {
            state.check = true
            if is_checkmate() {
              state.running = false
            }
          }

          if state.to_move == .WHITE {
            state.to_move = .BLACK
          } else {
            state.to_move = .WHITE
            state.move_no += 1
          }
          temp_file, temp_rank := find_closest_piece('a', 'h', 0, 7, state.to_move)
          if temp_file != -1 {
            state.hovered_file = temp_file
            state.hovered_rank = temp_rank
          }
        }
      }
    }
  case .Tab:
  case .Escape:
    state.mode = .SELECT
    state.hovered_file = state.selected_file
    state.hovered_rank = state.selected_rank
  }
}

increment_file_selected :: proc() {
  original_file := state.hovered_file
  if state.hovered_file != 'h' {
    state.hovered_file += 1
    for !check_square_for_piece(state.hovered_file, state.hovered_rank, state.to_move) {
      if state.hovered_file == 'h' {
        state.hovered_file = original_file
        temp_file, temp_rank := find_closest_piece(original_file+1, 'h', 0, 7, state.to_move)
        if temp_file != -1 {
          state.hovered_file = temp_file
          state.hovered_rank = temp_rank
        }
        break
      }
      state.hovered_file += 1
    }
  }
}

decrement_file_selected :: proc() {
  original_file := state.hovered_file
  if state.hovered_file != 'a' {
    state.hovered_file -= 1
    for !check_square_for_piece(state.hovered_file, state.hovered_rank, state.to_move) {
      if state.hovered_file == 'a' {
        state.hovered_file = original_file
        temp_file, temp_rank := find_closest_piece(original_file-1, 'a', 0, 7, state.to_move)
        if temp_file != -1 {
          state.hovered_file = temp_file
          state.hovered_rank = temp_rank
        }
        break
      }
      state.hovered_file -= 1
    }
  } 
}

increment_rank_selected :: proc() {
  original_rank := state.hovered_rank
  if state.hovered_rank != 7 {
    state.hovered_rank += 1
    for !check_square_for_piece(state.hovered_file, state.hovered_rank, state.to_move) {
      if state.hovered_rank == 7 {
        state.hovered_rank = original_rank
        temp_file, temp_rank := find_closest_piece('a', 'h', original_rank+1, 7, state.to_move)
        if temp_file != -1 {
          state.hovered_file = temp_file
          state.hovered_rank = temp_rank
        }
        break
      }
      state.hovered_rank += 1
    }
  }
}

decrement_rank_selected :: proc() {
  original_rank := state.hovered_rank
  if state.hovered_rank != 0 {
    state.hovered_rank -= 1
    for !check_square_for_piece(state.hovered_file, state.hovered_rank, state.to_move) {
      if state.hovered_rank == 0 {
        state.hovered_rank = original_rank
        temp_file, temp_rank := find_closest_piece('a', 'h', original_rank-1, 0, state.to_move)
        if temp_file != -1 {
          state.hovered_file = temp_file
          state.hovered_rank = temp_rank
        }
        break
      }
      state.hovered_rank -= 1
    }
  } 
}

increment_file_move :: proc() {
  original_file := state.hovered_file
  if state.hovered_file != 'h' {
    state.hovered_file += 1
    for !check_valid_move_or_capture(state.hovered_file, state.hovered_rank) {
      if state.hovered_file == 'h' {
        state.hovered_file = original_file
        temp_file, temp_rank := find_closest_move_or_capture(original_file+1, 'h', 0, 7)

        if temp_file != -1 {
          if check_valid_move_or_capture(temp_file, temp_rank) {
            state.hovered_file = temp_file
            state.hovered_rank = temp_rank
          }
        }
        break
      }
      state.hovered_file += 1
    }
  }
}

decrement_file_move :: proc() {
  original_file := state.hovered_file
  if state.hovered_file != 'a' {
    state.hovered_file -= 1
    for !check_valid_move_or_capture(state.hovered_file, state.hovered_rank) {
      if state.hovered_file == 'a' {
        state.hovered_file = original_file
        temp_file, temp_rank := find_closest_move_or_capture(original_file-1, 'a', 0, 7)

        if temp_file != -1 {
          if check_valid_move_or_capture(temp_file, temp_rank) {
            state.hovered_file = temp_file
            state.hovered_rank = temp_rank
          }
        }
        break
      }
      state.hovered_file -= 1
    }
  }
}

increment_rank_move :: proc() {
  original_rank := state.hovered_rank
  if state.hovered_rank != 7 {
    state.hovered_rank += 1
    for !check_valid_move_or_capture(state.hovered_file, state.hovered_rank) {
      if state.hovered_rank == 7 {
        state.hovered_rank = original_rank
        temp_file, temp_rank := find_closest_move_or_capture('a', 'h', original_rank+1, 7)

        if temp_file != -1 {
          if check_valid_move_or_capture(temp_file, temp_rank) {
            state.hovered_file = temp_file
            state.hovered_rank = temp_rank
          }
        }
        break
      }
      state.hovered_rank += 1
    }
  }
}

decrement_rank_move :: proc() {
  original_rank := state.hovered_rank
  if state.hovered_rank != 0 {
    state.hovered_rank -= 1
    for !check_valid_move_or_capture(state.hovered_file, state.hovered_rank) {
      if state.hovered_rank == 0 {
        state.hovered_rank = original_rank
        temp_file, temp_rank := find_closest_move_or_capture('a', 'h', original_rank-1, 0)

        if temp_file != -1 {
          if check_valid_move_or_capture(temp_file, temp_rank) {
            state.hovered_file = temp_file
            state.hovered_rank = temp_rank
          }
        }
        break
      }
      state.hovered_rank -= 1
    }
  }
}

find_closest_piece :: proc(start_file, end_file: rune, start_rank, end_rank: uint, colour: Colour) -> (file: rune, rank: uint) {
  start_file := start_file
  end_file := end_file
  start_rank := start_rank
  end_rank := end_rank

  piece_files := [dynamic]rune{}
  piece_ranks := [dynamic]uint{}

  if start_file > end_file {
    temp_file := start_file
    start_file = end_file
    end_file = temp_file
  }

  if start_rank > end_rank {
    temp_start := start_rank
    start_rank = end_rank
    end_rank = temp_start
  }

  if start_file == end_file {
    file := start_file
    for rank := start_rank; rank <= end_rank; rank += 1 {
      piece := state.board.piece_map[file][rank]
      if piece.colour == colour {
        if !(file == state.hovered_file && rank == state.hovered_rank) {
          append(&piece_files, file)
          append(&piece_ranks, rank)
        }
      }
    }
  } else if start_rank == end_rank {
    rank := start_rank
    for file := start_file; file <= end_file; file += 1 {
      piece := state.board.piece_map[file][rank]
      if piece.colour == colour {
        if !(file == state.hovered_file && rank == state.hovered_rank) {
          append(&piece_files, file)
          append(&piece_ranks, rank)
        }
      }
    }
  } else {
    for file := start_file; file <= end_file; file += 1 {
      for rank := start_rank; rank <= end_rank; rank += 1 {
        piece := state.board.piece_map[file][rank]
        if piece.colour == colour {
          if !(file == state.hovered_file && rank == state.hovered_rank) {
            append(&piece_files, file)
            append(&piece_ranks, rank)
          }
        }
      }
    }
  }

  piece_file: rune
  piece_rank: uint

  lowest_dist : f32 = 100

  for i in 0..< len(piece_files) {
    x_dist : f32 = abs(cast(f32)state.hovered_file - cast(f32)piece_files[i])
    y_dist : f32 = abs(cast(f32)state.hovered_rank - cast(f32)piece_ranks[i])
    dist := math.sqrt((x_dist * x_dist) + (y_dist * y_dist))

    if dist < lowest_dist {
      piece_file = piece_files[i]
      piece_rank = piece_ranks[i]
      lowest_dist = dist
    }
  }
  if len(piece_files) == 0 {
    return -1, 0
  }
  return piece_file, piece_rank
}

find_closest_move_or_capture :: proc(start_file, end_file: rune, start_rank, end_rank: uint) -> (file: rune, rank: uint) {
  piece_files := [dynamic]rune{}
  piece_ranks := [dynamic]uint{}

  for i in 0 ..< len(state.move_option_files) {
    file := state.move_option_files[i]
    rank := state.move_option_ranks[i]

    if start_file == end_file {
      if rank >= start_rank if (start_rank < end_rank) else rank <= start_rank {
        if file == start_file {
          append(&piece_files, file)
          append(&piece_ranks, rank)
        }
      }
    } else if start_rank == end_rank {
      if file >= start_file if (start_file < end_file) else file <= start_file {
        if rank == start_rank {
          append(&piece_files, file)
          append(&piece_ranks, rank)
        }
      }
    } else {
      if file >= start_file if (start_file < end_file) else file <= start_file {
        if rank >= start_rank if (start_rank < end_rank) else rank <= start_rank {
          append(&piece_files, file)
          append(&piece_ranks, rank)
        }
      }
    }
  }

  for i in 0 ..< len(state.capture_option_files) {
    file := state.capture_option_files[i]
    rank := state.capture_option_ranks[i]

    if start_file == end_file {
      if rank >= start_rank if (start_rank < end_rank) else rank <= start_rank {
        if file == start_file {
          append(&piece_files, file)
          append(&piece_ranks, rank)
        }
      }
    } else if start_rank == end_rank {
      if file >= start_file if (start_file < end_file) else file <= start_file {
        if rank == start_rank {
          append(&piece_files, file)
          append(&piece_ranks, rank)
        }
      }
    } else {
      if file >= start_file if (start_file < end_file) else file <= start_file {
        if rank >= start_rank if (start_rank < end_rank) else rank <= start_rank {
          append(&piece_files, file)
          append(&piece_ranks, rank)
        }
      }
    }
  }

  piece_file: rune
  piece_rank: uint

  lowest_dist : f32 = 100

  for i in 0 ..< len(piece_files) {
    x_dist : f32 = abs(cast(f32)state.hovered_file - cast(f32)piece_files[i])
    y_dist : f32 = abs(cast(f32)state.hovered_rank - cast(f32)piece_ranks[i])
    dist := math.sqrt((x_dist * x_dist) + (y_dist * y_dist))

    if dist < lowest_dist {
      piece_file = piece_files[i]
      piece_rank = piece_ranks[i]
      lowest_dist = dist
    }
  }
  if len(piece_files) == 0 {
    return -1, 0
  }
  return piece_file, piece_rank
}
