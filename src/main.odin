package main

import "core:fmt"
import "core:os/os2"
import "core:strings"
import "core:encoding/ansi"
import "core:unicode/utf8"

import nc "shared:ncurses/src"
import "core:c"
import "core:math"

Mode :: enum {
  SELECT,
  MOVE,
}

GameState :: struct {
  running: bool,
  move_no: u8,
  to_move: Colour,
  mode: Mode,
  board: Board,
  hovered_file: rune,
  hovered_rank: c.int,
  selected_file: rune,
  selected_rank: c.int,
  move_option_files: [dynamic]rune,
  move_option_ranks: [dynamic]c.int,
  capture_option_files: [dynamic]rune,
  capture_option_ranks: [dynamic]c.int,
}

state := GameState{}

BOARD_WIDTH  :: 130
BOARD_HEIGHT :: 64

main :: proc() {
  state.running = true
  state.move_no = 1
  state.to_move = .WHITE
  state.mode = .SELECT
  state.board = getDefaultBoard()
  state.hovered_file = 'a'
  state.move_option_files = [dynamic]rune{}
  state.move_option_ranks = [dynamic]c.int{}

  nc.initscr()
  nc.cbreak()
  nc.noecho()
  nc.use_default_colors()
  colour_support := nc.has_colors()
  if colour_support {
    nc.start_color()
    nc.init_pair(1, nc.COLOR_WHITE, nc.COLOR_WHITE)
    nc.init_pair(2, nc.COLOR_BLACK, nc.COLOR_BLACK)
    nc.init_pair(3, nc.COLOR_BLACK, nc.COLOR_CYAN)
    nc.init_pair(4, nc.COLOR_BLACK, nc.COLOR_BLUE)
    nc.init_pair(5, nc.COLOR_RED, nc.COLOR_RED)
    nc.init_pair(6, nc.COLOR_GREEN, nc.COLOR_GREEN)
  }
    
  WHITE_BACKGROUND_COLOUR := nc.COLOR_PAIR(1)
  BROWN := nc.COLOR_PAIR(2)

  nc.curs_set(0)
  nc.refresh()

  board_window := nc.newwin(BOARD_HEIGHT, BOARD_WIDTH, 1, 2)
  info_window := nc.newwin(40, 120, 66, 2)

  nc.keypad(board_window, true)
  nc.keypad(info_window, true)
  nc.refresh()
  draw_board(board_window)
  draw_info(info_window)

  for state.running {
    ch := nc.wgetch(board_window)
    if state.mode == .SELECT {
      handle_select_input(ch)
    } else if state.mode == .MOVE {
      //Cycle through the available moves and move the piece
      handle_move_input(ch)
    }

    draw_board(board_window)
    draw_info(info_window)
    nc.refresh()
  }
    
  nc.endwin()
  fmt.println("Closing program")
}

draw_info :: proc(win: ^nc.Window) {
  x : c.int = 2
  y : c.int = 1
  nc.box(win, 0, 0)
  
  nc.mvwaddstr(win, y, x, fmt.ctprintf("Go: %v", state.to_move))
  y += 1

  nc.mvwaddstr(win, y, x, fmt.ctprintf("Hover file: %v", state.hovered_file))
  y += 1
  nc.mvwaddstr(win, y, x, fmt.ctprintf("Hover rank: %v", state.hovered_rank))
  y += 1
  nc.mvwaddstr(win, y, x, fmt.ctprintf("Mode: %v", state.mode))
  y += 1
  nc.mvwaddstr(win, y, x, fmt.ctprintf("Available moves: %v", len(state.move_option_files)))
  y += 1

  //ch := nc.wgetch(win)

  //nc.mvwaddstr(win, y, x, fmt.ctprintf("Last key pressed: %3d", ch))
  //y += 1
  
  nc.mvwaddstr(win, y, x, fmt.ctprintf("Moves:"))
  y += 1

  for i in 0 ..< len(state.move_option_files) {
    nc.mvwaddstr(win, y, x, fmt.ctprintf("%v%v", state.move_option_files[i], state.move_option_ranks[i]+1))
    y += 1
  }

  y += 1

  nc.mvwaddstr(win, y, x, fmt.ctprintf("Available captures: %v", len(state.capture_option_files)))
  y += 1

  nc.wrefresh(win)
}

handle_select_input :: proc(ch: i32) {
  switch ch {
  case 'w', nc.KEY_UP:
    if state.to_move == .WHITE {
      increment_rank_selected()
    } else {
      decrement_rank_selected()
    }
  case 'a', nc.KEY_LEFT:
    if state.to_move == .WHITE {
      decrement_file_selected()
    } else {
      increment_file_selected()
    }
  case 's', nc.KEY_DOWN:
    if state.to_move == .WHITE {
      decrement_rank_selected()
    } else {
      increment_rank_selected()
    }
  case 'd', nc.KEY_RIGHT:
    if state.to_move == .WHITE {
      increment_file_selected()
    } else {
      decrement_file_selected()
    }
  case 10:
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
  case:
    nc.refresh()
  }
}

handle_move_input :: proc(ch: i32) {
  switch ch {
  case 'w', nc.KEY_UP:
    if state.to_move == .WHITE {
      increment_rank_move()
    } else {
      decrement_rank_move()
    }
  case 'a', nc.KEY_LEFT:
    if state.to_move == .WHITE {
      decrement_file_move()
    } else {
      increment_file_move()
    }
  case 's', nc.KEY_DOWN:
    if state.to_move == .WHITE {
      decrement_rank_move()
    } else {
      increment_rank_move()
    }
  case 'd', nc.KEY_RIGHT:
    if state.to_move == .WHITE {
      increment_file_move()
    } else {
      decrement_file_move()
    }
  case 10://Enter
    if check_valid_move_or_capture(state.hovered_file, state.hovered_rank) {
      state.board.piece_map[state.hovered_file][state.hovered_rank] = state.board.piece_map[state.selected_file][state.selected_rank]
      state.board.piece_map[state.selected_file][state.selected_rank] = PieceInfo{}
      state.mode = .SELECT
      if state.to_move == .WHITE {
        state.to_move = .BLACK
      } else {
        state.to_move = .WHITE
        state.move_no += 1
      }
      temp_file, temp_rank := find_closest_piece('a', 'h', 0, 7, state.to_move)
      if temp_file != -1 && temp_rank != -1 {
        state.hovered_file = temp_file
        state.hovered_rank = temp_rank
      }
    }
  case 9://TAB
  case 27://ESC
    state.mode = .SELECT
    temp_file: rune
    temp_rank: c.int
    if state.to_move == .WHITE {
      temp_file, temp_rank = find_closest_piece('a', 'h', 0, 7, .WHITE)
    } else {
      temp_file, temp_rank = find_closest_piece('a', 'h', 0, 7, .BLACK)
    }
    if temp_file != -1 && temp_rank != -1 {
      state.hovered_file = temp_file
      state.hovered_rank = temp_rank
    }
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
        if temp_file != -1 && temp_rank != -1 {
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
        if temp_file != -1 && temp_rank != -1 {
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
        if temp_file != -1 && temp_rank != -1 {
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
        if temp_file != -1 && temp_rank != -1 {
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

        if temp_file != -1 && temp_rank != -1 {
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

        if temp_file != -1 && temp_rank != -1 {
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

        if temp_file != -1 && temp_rank != -1 {
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

        if temp_file != -1 && temp_rank != -1 {
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

find_closest_piece :: proc(start_file, end_file: rune, start_rank, end_rank: c.int, colour: Colour) -> (file: rune, rank: c.int) {
  piece_files := [dynamic]rune{}
  piece_ranks := [dynamic]c.int{}

  file_increment: rune
  rank_increment: c.int

  if start_file == end_file {
    if start_rank < end_rank {
      rank_increment = 1
    } else {
      rank_increment = -1
    }
    
    file := start_file
    for rank := start_rank; rank <= end_rank if (start_rank <= end_rank) else rank >= end_rank; rank += rank_increment {
      piece := state.board.piece_map[file][rank]
      if piece.colour == colour {
        if !(file == state.hovered_file && rank == state.hovered_rank) {
          append(&piece_files, file)
          append(&piece_ranks, rank)
        }
      }
    }
  } else if start_rank == end_rank {
    if start_file < end_file {
      file_increment = 1
    } else {
      file_increment = -1
    }
    rank := start_rank
    for file := start_file; file <= end_file if (start_file <= end_file) else file >= end_file; file += file_increment {
      piece := state.board.piece_map[file][rank]
      if piece.colour == colour {
        if !(file == state.hovered_file && rank == state.hovered_rank) {
          append(&piece_files, file)
          append(&piece_ranks, rank)
        }
      }
    }
  } else {
    if start_file < end_file {
      file_increment = 1
    } else {
      file_increment = -1
    }

    if start_rank < end_rank {
      rank_increment = 1
    } else {
      rank_increment = -1
    }

    for file := start_file; file <= end_file if (start_file <= end_file) else file >= end_file; file += file_increment {
      for rank := start_rank; rank <= end_rank if (start_rank <= end_rank) else rank >= end_rank; rank += rank_increment {
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
  piece_rank: c.int

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
    return -1, -1
  }
  return piece_file, piece_rank
}

find_closest_move_or_capture :: proc(start_file, end_file: rune, start_rank, end_rank: c.int) -> (file: rune, rank: c.int) {
  piece_files := [dynamic]rune{}
  piece_ranks := [dynamic]c.int{}

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
  piece_rank: c.int

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
    return -1, -1
  }
  return piece_file, piece_rank
}
