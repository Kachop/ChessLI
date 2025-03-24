package main

import "core:fmt"
import "core:strconv"
import "core:unicode/utf8"

/*
File for all of the game logic.
-Moving pieces
-Captures
-Check / checkmate
*/

files_str_set :: bit_set['a'..='h']
ranks_str_set :: bit_set['1'..='8']
ranks_num_set :: bit_set[1..=8]

files_str :: files_str_set{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'}
ranks_str :: ranks_str_set{'1', '2', '3', '4', '5', '6', '7', '8'}
ranks_num :: ranks_num_set{1, 2, 3, 4, 5, 6, 7, 8}

/*
Returns all combined positions of the white pieces
*/

get_white_pieces :: proc() -> u64 {
  positions: u64 = 0
  positions |= state.board.piece_map[PAWN_W]
  positions |= state.board.piece_map[KNIGHT_W]
  positions |= state.board.piece_map[BISHOP_W]
  positions |= state.board.piece_map[ROOK_W]
  positions |= state.board.piece_map[QUEEN_W]
  positions |= state.board.piece_map[KING_W]
  return positions
}

/*
Returns all combined positions of the black pieces
*/

get_black_pieces :: proc() -> u64 {
  positions: u64 = 0
  positions |= state.board.piece_map[PAWN_B]
  positions |= state.board.piece_map[KNIGHT_B]
  positions |= state.board.piece_map[BISHOP_B]
  positions |= state.board.piece_map[ROOK_B]
  positions |= state.board.piece_map[QUEEN_B]
  positions |= state.board.piece_map[KING_B]
  return positions
}

get_empty_squares :: proc() -> u64 {
  positions: u64 = 0
  positions |= (~get_white_pieces() & (~get_black_pieces()))
  return positions
}

/*
Based on the currently selected piece find possible moves and captures.
All available moves pre-calculated. This narrows down the moves and finds the captures.
*/
get_pawn_moves_and_captures :: proc(square: u64 = state.selected_square, colour: Colour = state.to_move) {
  if colour == .WHITE {
    if get_empty_squares() & (square >> 8) != 0 {
      state.move_options |= PAWN_MOVES_W[square_to_index(square)] & get_empty_squares()
    }
    black_pieces := get_black_pieces()
    state.capture_options |= black_pieces & (square >> 9)
    state.capture_options |= black_pieces & (square >> 7)
  } else {
    if get_empty_squares() & (square << 8) != 0 {
      state.move_options |= PAWN_MOVES_B[square_to_index(square)] & get_empty_squares()
    }
    white_pieces := get_white_pieces()
    state.capture_options |= white_pieces & (square << 9)
    state.capture_options |= white_pieces & (square << 7)
  }
}

get_knight_moves_and_captures :: proc(square: u64 = state.selected_square, colour: Colour = state.to_move) {
  state.move_options |= KNIGHT_MOVES[square_to_index(square)] & get_empty_squares()
  if colour == .WHITE {
    state.capture_options |= KNIGHT_MOVES[square_to_index(square)] & get_black_pieces()
  } else {
    state.capture_options |= KNIGHT_MOVES[square_to_index(square)] & get_white_pieces()
  }
}

get_bishop_moves_and_captures :: proc(square: u64 = state.selected_square, colour: Colour = state.to_move) {
  blocked_UL: bool
  blocked_UR: bool
  blocked_DR: bool
  blocked_DL: bool

  state.move_options |= BISHOP_MOVES[square_to_index(square)] & get_empty_squares()
  if colour == .WHITE {
    state.capture_options |= BISHOP_MOVES[square_to_index(square)] & get_black_pieces()
  } else {
    state.capture_options |= BISHOP_MOVES[square_to_index(square)] & get_white_pieces()
  }
  for i in 1 ..< 8 {
    if blocked_UL {
      state.move_options ~= (square >> (9 * cast(u8)i) & state.move_options)
      state.capture_options ~= (square >> (9 * cast(u8)i) & state.capture_options)
    }
    if blocked_UR {
      state.move_options ~= (square >> (7 * cast(u8)i) & state.move_options)
      state.capture_options ~= (square >> (7 * cast(u8)i) & state.capture_options)
    }
    if blocked_DR {
      state.move_options ~= (square << (9 * cast(u8)i) & state.move_options)
      state.capture_options ~= (square << (9 * cast(u8)i) & state.capture_options)
    }
    if blocked_DL {
      state.move_options ~= (square << (7 * cast(u8)i) & state.move_options)
      state.capture_options ~= (square << (7 * cast(u8)i) & state.capture_options)
    }

    if state.move_options & (square >> (9 * cast(u8)i)) == 0 {
      blocked_UL = true
    }
    if state.move_options & (square >> (7 * cast(u8)i)) == 0 {
      blocked_UR = true
    }
    if state.move_options & (square << (9 * cast(u8)i)) == 0 {
      blocked_DR = true
    }
    if state.move_options & (square << (7 * cast(u8)i)) == 0 {
      blocked_DL = true
    }
  }
}

get_rook_moves_and_captures :: proc(square: u64 = state.selected_square, colour: Colour = state.to_move) {
  blocked_U: bool
  blocked_R: bool
  blocked_D: bool
  blocked_L: bool

  state.move_options |= ROOK_MOVES[square_to_index(square)] & get_empty_squares()
  if colour == .WHITE {
    state.capture_options |= ROOK_MOVES[square_to_index(square)] & get_black_pieces()
  } else {
    state.capture_options |= ROOK_MOVES[square_to_index(square)] & get_white_pieces()
  }
  for i in 1 ..< 8 {
    if blocked_U {
      state.move_options ~= (square >> (8 * cast(u8)i) & state.move_options)
      state.capture_options ~= (square >> (8 * cast(u8)i) & state.capture_options)
    }
    if blocked_R {
      state.move_options ~= (square >> cast(u8)i & state.move_options)
      state.capture_options ~= (square >> cast(u8)i & state.capture_options)
    }
    if blocked_D {
      state.move_options ~= (square << (8 * cast(u8)i) & state.move_options)
      state.capture_options ~= (square << (8 * cast(u8)i) & state.capture_options)
    }
    if blocked_L {
      state.move_options ~= (square << cast(u8)i & state.move_options)
      state.capture_options ~= (square << cast(u8)i & state.capture_options)
    }

    if state.move_options & (square >> (8 * cast(u8)i)) == 0 {
      blocked_U = true
    }
    if state.move_options & (square >> cast(u8)i) == 0 {
      blocked_R = true
    }
    if state.move_options & (square << (8 * cast(u8)i)) == 0 {
      blocked_D = true
    }
    if state.move_options & (square << cast(u8)i) == 0 {
      blocked_L = true
    }
  }
}

get_queen_moves_and_captures :: proc(square: u64 = state.selected_square, colour: Colour = state.to_move) {
  blocked_U: bool
  blocked_R: bool
  blocked_D: bool
  blocked_L: bool

  blocked_UL: bool
  blocked_UR: bool
  blocked_DR: bool
  blocked_DL: bool
  
  state.move_options |= QUEEN_MOVES[square_to_index(square)] & get_empty_squares()
  if colour == .WHITE {
    state.capture_options |= QUEEN_MOVES[square_to_index(square)] & get_black_pieces()
  } else {
    state.capture_options |= QUEEN_MOVES[square_to_index(square)] & get_white_pieces()
  }
  file := get_file(square)
  loop_limit_L := 7 if (file == 8) else 6
  loop_limit_R := 7 if (file == 1) else 6
  for i in 1 ..= 7 {
    if blocked_U {
      state.move_options ~= (square >> (8 * cast(u8)i) & state.move_options)
      state.capture_options ~= (square >> (8 * cast(u8)i) & state.capture_options)
    }
    if blocked_R && i <= loop_limit_R {
      state.move_options ~= (square >> cast(u8)i & state.move_options)
      state.capture_options ~= (square >> cast(u8)i & state.capture_options)
    }
    if blocked_D {
      state.move_options ~= (square << (8 * cast(u8)i) & state.move_options)
      state.capture_options ~= (square << (8 * cast(u8)i) & state.capture_options)
    }
    if blocked_L && i <= loop_limit_L {
      state.move_options ~= (square << cast(u8)i & state.move_options)
      state.capture_options ~= (square << cast(u8)i & state.capture_options)
    }

    if blocked_UL {
      state.move_options ~= (square >> (9 * cast(u8)i) & state.move_options)
      state.capture_options ~= (square >> (9 * cast(u8)i) & state.capture_options)
    }
    if blocked_UR {
      state.move_options ~= (square >> (7 * cast(u8)i) & state.move_options)
      state.capture_options ~= (square >> (7 * cast(u8)i) & state.capture_options)
    }
    if blocked_DR {
      state.move_options ~= (square << (9 * cast(u8)i) & state.move_options)
      state.capture_options ~= (square << (9 * cast(u8)i) & state.capture_options)
    }
    if blocked_DL {
      state.move_options ~= (square << (7 * cast(u8)i) & state.move_options)
      state.capture_options ~= (square << (7 * cast(u8)i) & state.capture_options)
    }

    if state.move_options & (square >> (8 * cast(u8)i)) == 0 {
      blocked_U = true
    }
    if state.move_options & (square >> cast(u8)i) == 0 {
      blocked_R = true
    }
    if state.move_options & (square << (8 * cast(u8)i)) == 0 {
      blocked_D = true
    }
    if state.move_options & (square << cast(u8)i) == 0 {
      blocked_L = true
    }

    if state.move_options & (square >> (9 * cast(u8)i)) == 0 {
      blocked_UL = true
    }
    if state.move_options & (square >> (7 * cast(u8)i)) == 0 {
      blocked_UR = true
    }
    if state.move_options & (square << (9 * cast(u8)i)) == 0 {
      blocked_DR = true
    }
    if state.move_options & (square << (7 * cast(u8)i)) == 0 {
      blocked_DL = true
    }
  } 
}

get_king_moves_and_captures :: proc(square: u64 = state.selected_square, colour: Colour = state.to_move) {
  state.move_options |= KING_MOVES[square_to_index(square)] & get_empty_squares()
  if colour == .WHITE {
    state.capture_options |= KING_MOVES[square_to_index(square)] & get_black_pieces()
  } else {
    state.capture_options |= KING_MOVES[square_to_index(square)] & get_white_pieces()
  }
}
/*
Checks a given board state (current board state by default) and for a given colour pieces if the king is in check
Loops through all of the pieces of a given colour and accumulates all of the available captures.
If one of those avaialble captures is the king then returns true. If not returns false
*/

is_check :: proc(board: map[PieceInfo]u64 = state.board.piece_map, colour: Colour = state.to_move) -> bool {
  state.capture_options = 0
  state.move_options = 0
  to_check: u64 = 1

  for i in 1 ..= 64 {
    for piece_info, piece_map in board {
      if piece_info.colour != colour {
        if piece_map & to_check != 0 {
          #partial switch piece_info.piece {
          case .PAWN:
            get_pawn_moves_and_captures(to_check, .WHITE if colour == .BLACK else .BLACK)
          case .KNIGHT:
            get_knight_moves_and_captures(to_check, .WHITE if colour == .BLACK else .BLACK)
          case .BISHOP:
            get_bishop_moves_and_captures(to_check, .WHITE if colour == .BLACK else .BLACK)
          case .ROOK:
            get_rook_moves_and_captures(to_check, .WHITE if colour == .BLACK else .BLACK)
          case .QUEEN:
            get_queen_moves_and_captures(to_check, .WHITE if colour == .BLACK else .BLACK)
          }
          if state.capture_options & state.board.piece_map[KING_W if colour == .WHITE else KING_B] != 0 {
            state.move_options = 0
            state.capture_options = 0
            return true
          }
          state.move_options = 0
          state.capture_options = 0
        }
      }
    }
    to_check <<= 1
  }
  return false
}

check_moves_and_captures :: proc(piece_info: PieceInfo, to_move_from: u64) -> bool {
  original_board := make(map[PieceInfo]u64)
  defer delete(original_board)
  copy_board(&original_board, state.board.piece_map)

  move_options := state.move_options
  capture_options := state.capture_options

  to_move_to: u64 = 1
  
  for i in 1 ..= 64 {
    if to_move_to & move_options != 0 {
      state.board.piece_map[piece_info] ~= to_move_from
      state.board.piece_map[piece_info] ~= to_move_to
      if !is_check(colour=piece_info.colour) {
        copy_board(&state.board.piece_map, original_board)
        return false
      }
      copy_board(&state.board.piece_map, original_board)
    }
    if to_move_to & capture_options != 0 {
      state.board.piece_map[piece_info] ~= to_move_from
      state.board.piece_map[piece_info] ~= to_move_to

      if piece_info.colour == .WHITE {
        state.board.piece_map[PAWN_B] ~= (state.board.piece_map[PAWN_B] & to_move_to)
        state.board.piece_map[KNIGHT_B] ~= (state.board.piece_map[KNIGHT_B] & to_move_to)
        state.board.piece_map[BISHOP_B] ~= (state.board.piece_map[BISHOP_B] & to_move_to)
        state.board.piece_map[ROOK_B] ~= (state.board.piece_map[ROOK_B] & to_move_to)
        state.board.piece_map[QUEEN_B] ~= (state.board.piece_map[QUEEN_B] & to_move_to)
      } else {
        state.board.piece_map[PAWN_W] ~= (state.board.piece_map[PAWN_W] & to_move_to)
        state.board.piece_map[KNIGHT_W] ~= (state.board.piece_map[KNIGHT_W] & to_move_to)
        state.board.piece_map[BISHOP_W] ~= (state.board.piece_map[BISHOP_W] & to_move_to)
        state.board.piece_map[ROOK_W] ~= (state.board.piece_map[ROOK_W] & to_move_to)
        state.board.piece_map[QUEEN_W] ~= (state.board.piece_map[QUEEN_W] & to_move_to)
      }
      if !is_check(colour=piece_info.colour) {
        copy_board(&state.board.piece_map, original_board)
        return false
      }
      copy_board(&state.board.piece_map, original_board)
    }
    to_move_to <<= 1
  }
  return true
}

/*
Checks if the current board state is checkmate for the given colour.

Loops through all possible moves and captures of the checked player.
If any of those board states result in no check then returns false.
If none of the available moves or captures stop the check then returns true.
*/

is_checkmate :: proc(colour: Colour = state.to_move) -> bool {
  to_check: u64 = 1

  for i in 1 ..= 64 {
    for piece_info, piece_map in state.board.piece_map {
      if piece_info.colour == colour {
        if to_check & piece_map != 0 {
          state.move_options = 0
          state.capture_options = 0
          #partial switch piece_info.piece {
          case .PAWN:
            get_pawn_moves_and_captures(to_check, colour)
            if !check_moves_and_captures(piece_info, to_check) {
              return false
            }
          case .KNIGHT:
            get_knight_moves_and_captures(to_check, colour)
            if !check_moves_and_captures(piece_info, to_check) {
              return false
            }
          case .BISHOP:
            get_bishop_moves_and_captures(to_check, colour)
            if !check_moves_and_captures(piece_info, to_check) {
              return false
            }
          case .ROOK:
            get_rook_moves_and_captures(to_check, colour)
            if !check_moves_and_captures(piece_info, to_check) {
              return false
            }
          case .QUEEN:
            get_queen_moves_and_captures(to_check, colour)
            if !check_moves_and_captures(piece_info, to_check) {
              return false
            }
          case .KING:
            get_king_moves_and_captures(to_check, colour)
            if !check_moves_and_captures(piece_info, to_check) {
              return false
            }
          }
        }
      }
    }
    to_check <<= 1
  }
  return true
}
