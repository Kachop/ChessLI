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
  hovered_square: u64,
  selected_square: u64,
  selected_piece: PieceInfo,
  move_options: u64,
  capture_options: u64,
  last_move: Move,
  can_castle_white_qs: bool,
  can_castle_white_ks: bool,
  can_castle_black_qs: bool,
  can_castle_black_ks: bool,
}

s := t.init_screen()
state := GameState{}

BOARD_WIDTH  :: 130
BOARD_HEIGHT :: 64

PAWN_MOVES_W := precompute_pawn_moves_w()
PAWN_MOVES_B := precompute_pawn_moves_b()
KNIGHT_MOVES := precompute_knight_moves()
BISHOP_MOVES := precompute_bishop_moves()
ROOK_MOVES := precompute_rook_moves()
QUEEN_MOVES := precompute_queen_moves()
KING_MOVES := precompute_king_moves()

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
  state.hovered_square = (1 << 4) << (8 * 7)
  state.can_castle_white_qs = true
  state.can_castle_white_ks = true
  state.can_castle_black_qs = true
  state.can_castle_black_ks = true

  defer t.destroy_screen(&s)
  t.set_term_mode(&s, .Cbreak)
  t.hide_cursor(true)
  t.clear_screen(&s, .Everything)
  t.blit_screen(&s)

  draw_board(&s)
  draw_info(&s)

  for state.running {
    defer free_all(context.temp_allocator)
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
  free_all(context.temp_allocator)
  t.hide_cursor(false)
  t.set_term_mode(&s, .Restored)
  state.board.piece_map[PAWN_B] ~= (1 << 18)
  state.board.piece_map[PAWN_B] ~= (1 << 10)
  get_bishop_moves_and_captures(square=(1 << 25), colour=.WHITE)
  fmt.println(state.capture_options)
}

draw_info :: proc(win: ^t.Screen) {
  x : uint = 2
  y : uint = 70
  
  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Go: %v", state.to_move))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Check: %v", state.check))
  y += 1
  
  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Hover file: %v", get_file(state.hovered_square)))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Hover rank: %v", get_rank(state.hovered_square)))
  y += 1

  t.move_cursor(win, y, x)
  //t.write(win, fmt.aprintf("Selected file: %v", state.selected_file))
  y += 1

  t.move_cursor(win, y, x)
//  t.write(win, fmt.aprintf("Selected rank: %v", state.selected_rank))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Move options: %v", state.move_options))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Capture options: %v", state.capture_options))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("File diff: %v", abs(cast(int)'d' - cast(int)'e')))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Mode: %v", state.mode))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Moves:"))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Test: %v", ~cast(u64)5))
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
    decrement_file_selected()
  case .S, .Arrow_Down:
    if state.to_move == .WHITE {
      decrement_rank_selected()
    } else {
      increment_rank_selected()
    }
  case .D, .Arrow_Right:
    increment_file_selected()
  case .Enter:
    state.selected_square = state.hovered_square
    state.selected_piece = get_piece(state.selected_square)

    state.move_options = 0
    state.capture_options = 0

    index := square_to_index(state.selected_square)

    #partial switch state.selected_piece.piece {
    case .PAWN:
      get_pawn_moves_and_captures()
    case .KNIGHT:
      get_knight_moves_and_captures()
    case .BISHOP:
      get_bishop_moves_and_captures()
    case .ROOK:
      get_rook_moves_and_captures()
    case .QUEEN:
      get_queen_moves_and_captures()
    case .KING:
      get_king_moves_and_captures()
    }

    if state.move_options > 0 || state.capture_options > 0 {
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
    decrement_file_move()
  case .S, .Arrow_Down:
    if state.to_move == .WHITE {
      decrement_rank_move()
    } else {
      increment_rank_move()
    }
  case .D, .Arrow_Right:
    increment_file_move()
  case .Enter:
    saved_board := make(map[PieceInfo]u64)
    defer delete(saved_board)
    copy_board(&saved_board, state.board.piece_map)

    if state.hovered_square != state.selected_square {
      state.board.piece_map[state.selected_piece] ~= state.selected_square
      state.board.piece_map[state.selected_piece] ~= state.hovered_square
 
      if state.to_move == .WHITE {
        state.board.piece_map[PAWN_B] ~= (state.board.piece_map[PAWN_B] & state.hovered_square)
        state.board.piece_map[KNIGHT_B] ~= (state.board.piece_map[KNIGHT_B] & state.hovered_square)
        state.board.piece_map[BISHOP_B] ~= (state.board.piece_map[BISHOP_B] & state.hovered_square)
        state.board.piece_map[ROOK_B] ~= (state.board.piece_map[ROOK_B] & state.hovered_square)
        state.board.piece_map[QUEEN_B] ~= (state.board.piece_map[QUEEN_B] & state.hovered_square)
        state.board.piece_map[KING_B] ~= (state.board.piece_map[KING_B] & state.hovered_square)
      } else {
        state.board.piece_map[PAWN_W] ~= (state.board.piece_map[PAWN_W] & state.hovered_square)
        state.board.piece_map[KNIGHT_W] ~= (state.board.piece_map[KNIGHT_W] & state.hovered_square)
        state.board.piece_map[BISHOP_W] ~= (state.board.piece_map[BISHOP_W] & state.hovered_square)
        state.board.piece_map[ROOK_W] ~= (state.board.piece_map[ROOK_W] & state.hovered_square)
        state.board.piece_map[QUEEN_W] ~= (state.board.piece_map[QUEEN_W] & state.hovered_square)
        state.board.piece_map[KING_W] ~= (state.board.piece_map[KING_W] & state.hovered_square)
      }

      //Checking if move results in current player being in check
      if is_check() {
        copy_board(&state.board.piece_map, saved_board)
        state.mode = .SELECT
        state.hovered_square = state.selected_square
        state.move_options = 0
        state.capture_options = 0
        state.selected_square = 0
        state.selected_piece = PieceInfo{}
        break
      } else {
        state.check = false
        state.move_options = 0
        state.capture_options = 0
      }

      //Moves that stop future castling
      if state.selected_piece == KING_W {
        state.can_castle_white_qs = false
        state.can_castle_white_ks = false
      } else if state.selected_piece == KING_B {
        state.can_castle_black_qs = false
        state.can_castle_black_ks = false
      }

      if state.selected_piece == ROOK_W {
        if state.selected_square == (1 << 56) {
          state.can_castle_white_qs = false
        } else if state.selected_square == (1 << 63) {
          state.can_castle_white_ks = false
        }
      } else if state.selected_piece == ROOK_B {
        if state.selected_square == (1) {
          state.can_castle_black_qs = false
        } else if state.selected_square == (1 << 7) {
          state.can_castle_black_ks = false
        }
      }

      //Castling
      if state.to_move == .WHITE {
        if state.selected_piece == KING_W && state.hovered_square == (1 << 58) {
          state.board.piece_map[ROOK_W] ~= (1 << 56)
          state.board.piece_map[ROOK_W] ~= (1 << 59)
        } else if state.selected_piece == KING_W && state.hovered_square == (1 << 62) {
          state.board.piece_map[ROOK_W] ~= (1 << 63)
          state.board.piece_map[ROOK_W] ~= (1 << 61)
        }
      } else {
        if state.selected_piece == KING_B && state.hovered_square == (1 << 2) {
          state.board.piece_map[ROOK_W] ~= (1)
          state.board.piece_map[ROOK_W] ~= (1 << 3)
        } else if state.selected_piece == KING_B && state.hovered_square == (1 << 6) {
          state.board.piece_map[ROOK_W] ~= (1 << 7)
          state.board.piece_map[ROOK_W] ~= (1 << 6)
        }
      }

      //Pawn promotion
      if state.to_move == .WHITE {
        if state.board.piece_map[PAWN_W] & ((1) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) | (1 << 6) | (1 << 7)) != 0 {
          handle_promotion_input()
        }
      } else {
        if state.board.piece_map[PAWN_B] & ((1 << 56) | (1 << 57) | (1 << 58) | (1 << 59) | (1 << 60) | (1 << 61) | (1 << 62) | (1 << 63)) != 0 {
          handle_promotion_input()
        }
      }

      if is_check(colour =.WHITE if state.to_move == .BLACK else .BLACK) {
        state.check = true
        if is_checkmate(colour =.WHITE if state.to_move == .BLACK else .BLACK) {
          state.running = false
        }
      } else {
        state.check = false
      }

      if state.to_move == .WHITE {
       state.to_move = .BLACK
      } else {
        state.to_move = .WHITE
        state.move_no += 1
      }
      temp_square := find_closest_piece(1, 8, 1, 8, state.to_move)
      if temp_square != 0 {
        state.hovered_square = temp_square
      }
    }
    state.mode = .SELECT
    state.move_options = 0
    state.capture_options = 0
    state.selected_square = 0
    state.selected_piece = PieceInfo{}
  case .Tab:
  case .Escape:
    state.mode = .SELECT
    state.hovered_square = state.selected_square
    state.move_options = 0
    state.capture_options = 0
    state.selected_square = 0
    state.selected_piece = PieceInfo{}
  }
}

handle_promotion_input :: proc() {
  input, has_input := t.read(&s)
  keys := t.parse_keyboard_input(input)
  promotion_handled := false
  promotion_options_w := []PieceInfo{QUEEN_W, ROOK_W, BISHOP_W, KNIGHT_W}
  promotion_options_b := []PieceInfo{QUEEN_B, ROOK_B, BISHOP_B, KNIGHT_B}
  selected_piece_index := 0
  
  state.board.piece_map[PAWN_W if state.to_move == .WHITE else PAWN_B] ~= state.hovered_square
  state.board.piece_map[promotion_options_w[selected_piece_index] if state.to_move == .WHITE else promotion_options_b[selected_piece_index]] ~= state.hovered_square

  for !promotion_handled {
    defer t.blit_screen(&s)
    t.clear_screen(&s, .Everything)
    #partial switch keys.key {
    case .Tab:
      //Switch which piece to promote to
      selected_piece_index += 1
      if selected_piece_index == len(promotion_options_w) {
        selected_piece_index = 0
      }
      if state.to_move == .WHITE {
        if selected_piece_index > 0 {
          state.board.piece_map[promotion_options_w[selected_piece_index-1]] ~= state.hovered_square
        } else {
          state.board.piece_map[promotion_options_w[len(promotion_options_w)-1]] ~= state.hovered_square
        }
        state.board.piece_map[promotion_options_w[selected_piece_index]] ~= state.hovered_square
      } else {
        if selected_piece_index > 0 {
          state.board.piece_map[promotion_options_b[selected_piece_index-1]] ~= state.hovered_square
        } else {
          state.board.piece_map[promotion_options_b[len(promotion_options_w)-1]] ~= state.hovered_square
        }
        state.board.piece_map[promotion_options_b[selected_piece_index]] ~= state.hovered_square
      }
    case .Enter:
      promotion_handled = true
    }
    input, has_input = t.read(&s)
    keys = t.parse_keyboard_input(input)
    draw_board(&s)
  }
}

increment_file_selected :: proc() {
  original_square := state.hovered_square
  file := get_file(original_square)
  if get_file(state.hovered_square) != 8 {
    state.hovered_square <<= 1
    for !check_square_for_piece(state.hovered_square, state.to_move) {
      if get_file(state.hovered_square) == 8 {
        state.hovered_square = original_square
        temp_square := find_closest_piece(file+1, 8, 1, 8, state.to_move)
        if temp_square != 0 {
          state.hovered_square = temp_square
        }
        break
      }
      state.hovered_square <<= 1
    }
  }
}

decrement_file_selected :: proc() {
  original_square := state.hovered_square
  file := get_file(original_square)
  if get_file(state.hovered_square) != 1 {
    state.hovered_square >>= 1
    for !check_square_for_piece(state.hovered_square, state.to_move) {
      if get_file(state.hovered_square) == 1 {
        state.hovered_square = original_square
        temp_square := find_closest_piece(file-1, 1, 1, 8, state.to_move)
        if temp_square != 0 {
          state.hovered_square = temp_square
        }
        break
      }
      state.hovered_square >>= 1
    }
  } 
}

increment_rank_selected :: proc() {
  original_square := state.hovered_square
  rank := get_rank(original_square)
  if get_rank(state.hovered_square) != 8 {
    state.hovered_square >>= 8
    for !check_square_for_piece(state.hovered_square, state.to_move) {
      if get_rank(state.hovered_square) == 8 {
        state.hovered_square = original_square
        temp_square := find_closest_piece(1, 8, rank+1, 8, state.to_move)
        if temp_square != 0 {
          state.hovered_square = temp_square
        }
        break
      }
      state.hovered_square >>= 8
    }
  }
}

decrement_rank_selected :: proc() {
  original_square := state.hovered_square
  rank := get_rank(original_square)
  if get_rank(state.hovered_square) != 1 {
    state.hovered_square <<= 8
    for !check_square_for_piece(state.hovered_square, state.to_move) {
      if get_rank(state.hovered_square) == 1 {
        state.hovered_square = original_square
        temp_square := find_closest_piece(1, 8, rank-1, 1, state.to_move)
        if temp_square != 0 {
          state.hovered_square = temp_square
        }
        break
      }
      state.hovered_square <<= 8
    }
  } 
}

increment_file_move :: proc() {
  original_square := state.hovered_square
  file := get_file(original_square)
  if get_file(state.hovered_square) != 8 {
    state.hovered_square <<= 1
    for !check_valid_move_or_capture(state.hovered_square) {
      if get_file(state.hovered_square) == 8 {
        state.hovered_square = original_square
        temp_square := find_closest_move_or_capture(get_file(state.hovered_square)+1, 8, 1, 8)

        if temp_square != 0 {
          if check_valid_move_or_capture(temp_square) {
            state.hovered_square = temp_square
          }
        }
        break
      }
      state.hovered_square <<= 1
    }
  }
}

decrement_file_move :: proc() {
  original_square := state.hovered_square
  file := get_file(original_square)
  if get_file(state.hovered_square) != 1 {
    state.hovered_square >>= 1
    for !check_valid_move_or_capture(state.hovered_square) {
      if get_file(state.hovered_square) == 1 {
        state.hovered_square = original_square
        temp_square := find_closest_move_or_capture(get_file(state.hovered_square)-1, 1, 1, 8)

        if temp_square != 0 {
          if check_valid_move_or_capture(temp_square) {
            state.hovered_square = temp_square
          }
        }
        break
      }
      state.hovered_square >>= 1
    }
  }
}

increment_rank_move :: proc() {
  original_square := state.hovered_square
  rank := get_rank(original_square)
  if get_rank(state.hovered_square) != 8 {
    state.hovered_square >>= 8
    for !check_valid_move_or_capture(state.hovered_square) {
      if get_rank(state.hovered_square) == 8 {
        state.hovered_square = original_square
        temp_square := find_closest_move_or_capture(1, 8, get_rank(state.hovered_square)+1, 8)

        if temp_square != 0 {
          if check_valid_move_or_capture(temp_square) {
            state.hovered_square = temp_square
          }
        }
        break
      }
      state.hovered_square >>= 8
    }
  }
}

decrement_rank_move :: proc() {
  original_square := state.hovered_square
  rank := get_rank(original_square)
  if get_rank(state.hovered_square) != 1 {
    state.hovered_square <<= 8
    for !check_valid_move_or_capture(state.hovered_square) {
      if get_rank(state.hovered_square) == 1 {
        state.hovered_square = original_square
        temp_square := find_closest_move_or_capture(1, 8, get_rank(state.hovered_square)-1, 1)

        if temp_square != 0 {
          if check_valid_move_or_capture(temp_square) {
            state.hovered_square = temp_square
          }
        }
        break
      }
      state.hovered_square <<= 8
    }
  }
}

find_closest_piece :: proc(start_file, end_file, start_rank, end_rank: u8, colour: Colour) -> (square: u64) {
  square_to_check: u64 = 0

  squares: [dynamic]u64
  defer delete(squares)

  start_file := start_file
  end_file := end_file
  start_rank := start_rank
  end_rank := end_rank

  if start_file > end_file {
    temp_file := start_file
    start_file = end_file
    end_file = temp_file
  }

  if start_rank < end_rank {
    temp_start := start_rank
    start_rank = end_rank
    end_rank = temp_start
  }
  
  file: u8 = start_file
  rank: u8 = start_rank
  start_square := (8 * (8 - start_rank)) + start_file - 1
  square_to_check |= 1 << start_square

  for rank >= end_rank {
    piece_loop: for piece, piece_map in state.board.piece_map {
      if square_to_check & piece_map != 0 && piece.colour == colour {
        if square_to_check != state.hovered_square {
          append(&squares, square_to_check)
          break piece_loop
        }
      }
    }
    
    if file < end_file {
      file += 1
      square_to_check <<= 1
    } else {
      file = start_file
      square_to_check <<= 8 - (end_file - start_file)
      rank -= 1
    }
  }
  
  closest_piece: u64 = 0
  lowest_dist : f32 = 100

  for i in 0..< len(squares) {
    dist := calc_squares_distance(state.hovered_square, squares[i])

    if dist < lowest_dist {
      closest_piece = squares[i]
      lowest_dist = dist
    }
  }
  if len(squares) == 0 {
    return 0
  }
  return closest_piece
}

find_closest_move_or_capture :: proc(start_file, end_file, start_rank, end_rank: u8) -> (square: u64) {
  square_to_check: u64 = 0

  squares: [dynamic]u64
  defer delete(squares)

  start_file := start_file
  end_file := end_file
  start_rank := start_rank
  end_rank := end_rank

  if start_file > end_file {
    temp_file := start_file
    start_file = end_file
    end_file = temp_file
  }

  if start_rank < end_rank {
    temp_start := start_rank
    start_rank = end_rank
    end_rank = temp_start
  }

  file: u8 = start_file
  rank: u8 = start_rank
  start_square := (8 * (8 - start_rank)) + start_file - 1
  square_to_check |= 1 << start_square

  for rank >= end_rank {
    if square_to_check & state.move_options != 0 {
      if square_to_check != state.hovered_square {
        append(&squares, square_to_check)
      }
    }
    if square_to_check & state.capture_options != 0 {
      if square_to_check != state.hovered_square {
        append(&squares, square_to_check)
      }
    }

    if file < end_file {
      file += 1
      square_to_check <<= 1
    } else {
      file = start_file
      square_to_check <<= 8 - (end_file - start_file)
      rank -= 1
    }
  }
  
  closest_piece: u64 = 0
  lowest_dist : f32 = 100
  
  for i in 0..< len(squares) {
    dist := calc_squares_distance(state.hovered_square, squares[i])

    if dist < lowest_dist {
      closest_piece = squares[i]
      lowest_dist = dist
    }
  }
  if len(squares) == 0 {
    return 0
  }
  return closest_piece
}
