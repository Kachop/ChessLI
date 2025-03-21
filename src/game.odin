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
get_pawn_moves_and_captures :: proc() {
  if state.to_move == .WHITE {
    if get_empty_squares() & (state.selected_square >> 8) != 0 {
      state.move_options |= PAWN_MOVES_W[square_to_index(state.selected_square)] & get_empty_squares()
    }
    black_pieces := get_black_pieces()
    state.capture_options |= black_pieces & (state.selected_square >> 9)
    state.capture_options |= black_pieces & (state.selected_square >> 7)
  } else {
    if get_empty_squares() & (state.selected_square << 8) != 0 {
      state.move_options |= PAWN_MOVES_B[square_to_index(state.selected_square)] & get_empty_squares()
    }
    white_pieces := get_white_pieces()
    state.capture_options |= white_pieces & (state.selected_square << 9)
    state.capture_options |= white_pieces & (state.selected_square << 7)
  }
}

get_knight_moves_and_captures :: proc() {
  state.move_options |= KNIGHT_MOVES[square_to_index(state.selected_square)] & get_empty_squares()
  if state.to_move == .WHITE {
    state.capture_options |= KNIGHT_MOVES[square_to_index(state.selected_square)] & get_black_pieces()
  } else {
    state.capture_options |= KNIGHT_MOVES[square_to_index(state.selected_square)] & get_white_pieces()
  }
}

get_bishop_moves_and_captures :: proc() {
  blocked_UL: bool
  blocked_UR: bool
  blocked_DR: bool
  blocked_DL: bool

  state.move_options |= BISHOP_MOVES[square_to_index(state.selected_square)] & get_empty_squares()
  if state.to_move == .WHITE {
    state.capture_options |= BISHOP_MOVES[square_to_index(state.selected_square)] & get_black_pieces()
  } else {
    state.capture_options |= BISHOP_MOVES[square_to_index(state.selected_square)] & get_white_pieces()
  }
  for i in 1 ..< 8 {
    if blocked_UL {
      state.move_options ~= (state.selected_square >> (9 * cast(u8)i) & state.move_options)
      state.capture_options ~= (state.selected_square >> (9 * cast(u8)i) & state.capture_options)
    }
    if blocked_UR {
      state.move_options ~= (state.selected_square >> (7 * cast(u8)i) & state.move_options)
      state.capture_options ~= (state.selected_square >> (7 * cast(u8)i) & state.capture_options)
    }
    if blocked_DR {
      state.move_options ~= (state.selected_square << (9 * cast(u8)i) & state.move_options)
      state.capture_options ~= (state.selected_square << (9 * cast(u8)i) & state.capture_options)
    }
    if blocked_DL {
      state.move_options ~= (state.selected_square << (7 * cast(u8)i) & state.move_options)
      state.capture_options ~= (state.selected_square << (7 * cast(u8)i) & state.capture_options)
    }

    if state.move_options & (state.selected_square >> (9 * cast(u8)i)) == 0 {
      blocked_UL = true
    }
    if state.move_options & (state.selected_square >> (7 * cast(u8)i)) == 0 {
      blocked_UR = true
    }
    if state.move_options & (state.selected_square << (9 * cast(u8)i)) == 0 {
      blocked_DR = true
    }
    if state.move_options & (state.selected_square << (7 * cast(u8)i)) == 0 {
      blocked_DL = true
    }
  }
}

get_rook_moves_and_captures :: proc() {
  blocked_U: bool
  blocked_R: bool
  blocked_D: bool
  blocked_L: bool

  state.move_options |= ROOK_MOVES[square_to_index(state.selected_square)] & get_empty_squares()
  if state.to_move == .WHITE {
    state.capture_options |= ROOK_MOVES[square_to_index(state.selected_square)] & get_black_pieces()
  } else {
    state.capture_options |= ROOK_MOVES[square_to_index(state.selected_square)] & get_white_pieces()
  }
  for i in 1 ..< 8 {
    if blocked_U {
      state.move_options ~= (state.selected_square >> (8 * cast(u8)i) & state.move_options)
      state.capture_options ~= (state.selected_square >> (8 * cast(u8)i) & state.capture_options)
    }
    if blocked_R {
      state.move_options ~= (state.selected_square >> cast(u8)i & state.move_options)
      state.capture_options ~= (state.selected_square >> cast(u8)i & state.capture_options)
    }
    if blocked_D {
      state.move_options ~= (state.selected_square << (8 * cast(u8)i) & state.move_options)
      state.capture_options ~= (state.selected_square << (8 * cast(u8)i) & state.capture_options)
    }
    if blocked_L {
      state.move_options ~= (state.selected_square << cast(u8)i & state.move_options)
      state.capture_options ~= (state.selected_square << cast(u8)i & state.capture_options)
    }

    if state.move_options & (state.selected_square >> (8 * cast(u8)i)) == 0 {
      blocked_U = true
    }
    if state.move_options & (state.selected_square >> cast(u8)i) == 0 {
      blocked_R = true
    }
    if state.move_options & (state.selected_square << (8 * cast(u8)i)) == 0 {
      blocked_D = true
    }
    if state.move_options & (state.selected_square << cast(u8)i) == 0 {
      blocked_L = true
    }
  }
}

get_queen_moves_and_captures :: proc() {
  blocked_U: bool
  blocked_R: bool
  blocked_D: bool
  blocked_L: bool

  blocked_UL: bool
  blocked_UR: bool
  blocked_DR: bool
  blocked_DL: bool
  
  state.move_options |= QUEEN_MOVES[square_to_index(state.selected_square)] & get_empty_squares()
  if state.to_move == .WHITE {
    state.capture_options |= QUEEN_MOVES[square_to_index(state.selected_square)] & get_black_pieces()
  } else {
    state.capture_options |= QUEEN_MOVES[square_to_index(state.selected_square)] & get_white_pieces()
  }
  file := get_file(state.selected_square)
  loop_limit_L := 7 if (file == 8) else 6
  loop_limit_R := 7 if (file == 1) else 6
  for i in 1 ..= 7 {
    if blocked_U {
      state.move_options ~= (state.selected_square >> (8 * cast(u8)i) & state.move_options)
      state.capture_options ~= (state.selected_square >> (8 * cast(u8)i) & state.capture_options)
    }
    if blocked_R && i <= loop_limit_R {
      state.move_options ~= (state.selected_square >> cast(u8)i & state.move_options)
      state.capture_options ~= (state.selected_square >> cast(u8)i & state.capture_options)
    }
    if blocked_D {
      state.move_options ~= (state.selected_square << (8 * cast(u8)i) & state.move_options)
      state.capture_options ~= (state.selected_square << (8 * cast(u8)i) & state.capture_options)
    }
    if blocked_L && i <= loop_limit_L {
      state.move_options ~= (state.selected_square << cast(u8)i & state.move_options)
      state.capture_options ~= (state.selected_square << cast(u8)i & state.capture_options)
    }

    if blocked_UL {
      state.move_options ~= (state.selected_square >> (9 * cast(u8)i) & state.move_options)
      state.capture_options ~= (state.selected_square >> (9 * cast(u8)i) & state.capture_options)
    }
    if blocked_UR {
      state.move_options ~= (state.selected_square >> (7 * cast(u8)i) & state.move_options)
      state.capture_options ~= (state.selected_square >> (7 * cast(u8)i) & state.capture_options)
    }
    if blocked_DR {
      state.move_options ~= (state.selected_square << (9 * cast(u8)i) & state.move_options)
      state.capture_options ~= (state.selected_square << (9 * cast(u8)i) & state.capture_options)
    }
    if blocked_DL {
      state.move_options ~= (state.selected_square << (7 * cast(u8)i) & state.move_options)
      state.capture_options ~= (state.selected_square << (7 * cast(u8)i) & state.capture_options)
    }

    if state.move_options & (state.selected_square >> (8 * cast(u8)i)) == 0 {
      blocked_U = true
    }
    if state.move_options & (state.selected_square >> cast(u8)i) == 0 {
      blocked_R = true
    }
    if state.move_options & (state.selected_square << (8 * cast(u8)i)) == 0 {
      blocked_D = true
    }
    if state.move_options & (state.selected_square << cast(u8)i) == 0 {
      blocked_L = true
    }

    if state.move_options & (state.selected_square >> (9 * cast(u8)i)) == 0 {
      blocked_UL = true
    }
    if state.move_options & (state.selected_square >> (7 * cast(u8)i)) == 0 {
      blocked_UR = true
    }
    if state.move_options & (state.selected_square << (9 * cast(u8)i)) == 0 {
      blocked_DR = true
    }
    if state.move_options & (state.selected_square << (7 * cast(u8)i)) == 0 {
      blocked_DL = true
    }
  } 
}

get_king_moves_and_captures :: proc() {
  state.move_options |= KING_MOVES[square_to_index(state.selected_square)] & get_empty_squares()
  if state.to_move == .WHITE {
    state.capture_options |= KING_MOVES[square_to_index(state.selected_square)] & get_black_pieces()
  } else {
    state.capture_options |= KING_MOVES[square_to_index(state.selected_square)] & get_white_pieces()
  }
}

/*
Checks a given board state (current board state by default) and for a given colour pieces if the opposing king is in check
Loops through all of the pieces of a given colour and accumulates all of the available captures.
If one of those avaialble captures is the king then returns true. If not returns false
*/
/*
is_check :: proc(board: map[rune][dynamic]PieceInfo = state.board.piece_map, colour: Colour = state.to_move) -> bool {
  clear(&state.capture_option_files)
  clear(&state.capture_option_ranks)
  for file := 'a'; file <= 'h'; file += 1 {
    for rank: uint = 0; rank <= 7; rank += 1 {
      piece := board[file][rank]

      if piece.colour == colour {
        #partial switch piece.piece {
        case .PAWN:
          get_pawn_moves_and_captures(file, rank, colour)
        case .KNIGHT:
          get_knight_moves_and_captures(file, rank, colour)
        case .BISHOP:
          get_bishop_moves_and_captures(file, rank, colour)
        case .ROOK:
          get_rook_moves_and_captures(file, rank, colour)
        case .QUEEN:
          get_bishop_moves_and_captures(file, rank, colour)
          get_rook_moves_and_captures(file, rank, colour)
        }
      }
    }
  }

  clear(&state.move_option_files)
  clear(&state.move_option_ranks)
  
  for i in 0 ..< len(state.capture_option_files) {
    if board[state.capture_option_files[i]][state.capture_option_ranks[i]].piece == .KING {
      clear(&state.capture_option_files)
      clear(&state.capture_option_ranks)
      return true
    }
  }
  clear(&state.capture_option_files)
  clear(&state.capture_option_ranks)
  return false
}

/*
Checks if the current board state is checkmate.

Loops through all possible moves and captures of the checked player.
If any of those board states result in no check then returns false.
If none of the available moves or captures stop the check then returns true.
*/
is_checkmate :: proc() -> bool {
  original_board := make(map[rune][dynamic]PieceInfo)
  defer delete(original_board)
  copy_board(&original_board, state.board.piece_map)

  if state.to_move == .WHITE {
    state.to_move = .BLACK
    for file := 'a'; file <= 'h'; file += 1 {
      for rank : uint = 0; rank <= 7; rank += 1 {
        piece := state.board.piece_map[file][rank]
        if piece.colour == .BLACK {
          clear(&state.move_option_files)
          clear(&state.move_option_ranks)
          clear(&state.capture_option_files)
          clear(&state.capture_option_ranks)

          #partial switch piece.piece {
          case .PAWN:
            get_pawn_moves_and_captures(file, rank)
          case .KNIGHT:
            get_knight_moves_and_captures(file, rank)
          case .BISHOP:
            get_bishop_moves_and_captures(file, rank)
          case .ROOK:
            get_rook_moves_and_captures(file, rank)
          case .QUEEN:
            get_bishop_moves_and_captures(file, rank)
            get_rook_moves_and_captures(file, rank)
          case.KING:
            get_king_moves_and_captures(file, rank)
          }

          for i in 0 ..< len(state.move_option_files) {
            state.board.piece_map[state.move_option_files[i]][state.move_option_ranks[i]] = piece
            state.board.piece_map[file][rank] = PieceInfo{}

            old_move_files: [dynamic]rune
            old_move_ranks: [dynamic]uint
            old_capture_files: [dynamic]rune
            old_capture_ranks: [dynamic]uint
            copy(old_move_files[:], state.move_option_files[:]) 
            copy(old_move_ranks[:], state.move_option_ranks[:])
            copy(old_capture_files[:], state.capture_option_files[:])
            copy(old_capture_ranks[:], state.capture_option_ranks[:])

            if !is_check(colour = .WHITE) {
              state.to_move = .WHITE
              copy_board(&state.board.piece_map, original_board)
              return false
            }
            copy_board(&state.board.piece_map, original_board)
            copy(state.move_option_files[:], old_move_files[:])
            copy(state.move_option_ranks[:], old_move_ranks[:])
            copy(state.capture_option_files[:], old_capture_files[:])
            copy(state.capture_option_ranks[:], old_capture_ranks[:])
          }

          for i in 0 ..< len(state.capture_option_files) {
            state.board.piece_map[state.capture_option_files[i]][state.capture_option_ranks[i]] = piece
            state.board.piece_map[file][rank] = PieceInfo{}
            
            old_move_files: [dynamic]rune
            old_move_ranks: [dynamic]uint
            old_capture_files: [dynamic]rune
            old_capture_ranks: [dynamic]uint
            copy(old_move_files[:], state.move_option_files[:]) 
            copy(old_move_ranks[:], state.move_option_ranks[:])
            copy(old_capture_files[:], state.capture_option_files[:])
            copy(old_capture_ranks[:], state.capture_option_ranks[:])

            if !is_check(colour = .WHITE) { 
              state.to_move = .WHITE
              copy_board(&state.board.piece_map, original_board)
              return false
            }
            copy_board(&state.board.piece_map, original_board)
            copy(state.move_option_files[:], old_move_files[:])
            copy(state.move_option_ranks[:], old_move_ranks[:])
            copy(state.capture_option_files[:], old_capture_files[:])
            copy(state.capture_option_ranks[:], old_capture_ranks[:])

          }
        }
      }
    }
    state.to_move = .WHITE
  } else {
    state.to_move = .WHITE
    for file := 'a'; file <= 'h'; file += 1 {
      for rank : uint = 0; rank <= 7; rank += 1 {
        piece := state.board.piece_map[file][rank]
        if piece.colour == .WHITE {
          clear(&state.move_option_files)
          clear(&state.move_option_ranks)
          clear(&state.capture_option_files)
          clear(&state.capture_option_ranks)

          #partial switch piece.piece {
          case .PAWN:
            get_pawn_moves_and_captures(file, rank)
          case .KNIGHT:
            get_knight_moves_and_captures(file, rank)
          case .BISHOP:
            get_bishop_moves_and_captures(file, rank)
          case .ROOK:
            get_rook_moves_and_captures(file, rank)
          case .QUEEN:
            get_bishop_moves_and_captures(file, rank)
            get_rook_moves_and_captures(file, rank)
          case.KING:
            get_king_moves_and_captures(file, rank)
          }

          for i in 0 ..< len(state.move_option_files) {
            state.board.piece_map[state.move_option_files[i]][state.move_option_ranks[i]] = piece
            state.board.piece_map[file][rank] = PieceInfo{}
            
            old_move_files: [dynamic]rune
            old_move_ranks: [dynamic]uint
            old_capture_files: [dynamic]rune
            old_capture_ranks: [dynamic]uint
            copy(old_move_files[:], state.move_option_files[:]) 
            copy(old_move_ranks[:], state.move_option_ranks[:])
            copy(old_capture_files[:], state.capture_option_files[:])
            copy(old_capture_ranks[:], state.capture_option_ranks[:])
            
            if !is_check(colour = .BLACK) {
              state.to_move = .BLACK
              copy_board(&state.board.piece_map, original_board)
              return false
            }
            copy_board(&state.board.piece_map, original_board)
            copy(state.move_option_files[:], old_move_files[:])
            copy(state.move_option_ranks[:], old_move_ranks[:])
            copy(state.capture_option_files[:], old_capture_files[:])
            copy(state.capture_option_ranks[:], old_capture_ranks[:])

          }

          for i in 0 ..< len(state.capture_option_files) {
            state.board.piece_map[state.capture_option_files[i]][state.capture_option_ranks[i]] = piece
            state.board.piece_map[file][rank] = PieceInfo{}
            
            old_move_files: [dynamic]rune
            old_move_ranks: [dynamic]uint
            old_capture_files: [dynamic]rune
            old_capture_ranks: [dynamic]uint
            copy(old_move_files[:], state.move_option_files[:]) 
            copy(old_move_ranks[:], state.move_option_ranks[:])
            copy(old_capture_files[:], state.capture_option_files[:])
            copy(old_capture_ranks[:], state.capture_option_ranks[:])

            if !is_check(colour = .BLACK) {
              state.to_move = .BLACK
              copy_board(&state.board.piece_map, original_board)
              return false
            }
            copy_board(&state.board.piece_map, original_board)
            copy(state.move_option_files[:], old_move_files[:])
            copy(state.move_option_ranks[:], old_move_ranks[:])
            copy(state.capture_option_files[:], old_capture_files[:])
            copy(state.capture_option_ranks[:], old_capture_ranks[:])

          }
        }
      }
    }
    state.to_move = .BLACK
  }
  return true
}
*/
