package main

/*
Returns the u64 containing all of the combined locations of any white pieces on a given board.
*/
get_white_pieces :: proc(board: map[PieceInfo]u64 = state.board.piece_map) -> u64 {
  positions: u64 = 0
  positions |= board[PAWN_W]
  positions |= board[KNIGHT_W]
  positions |= board[BISHOP_W]
  positions |= board[ROOK_W]
  positions |= board[QUEEN_W]
  positions |= board[KING_W]
  return positions
}

/*
Returns all combined positions of the black pieces on a given board.
*/
get_black_pieces :: proc(board: map[PieceInfo]u64 = state.board.piece_map) -> u64 {
  positions: u64 = 0
  positions |= board[PAWN_B]
  positions |= board[KNIGHT_B]
  positions |= board[BISHOP_B]
  positions |= board[ROOK_B]
  positions |= board[QUEEN_B]
  positions |= board[KING_B]
  return positions
}

/*
Returns all of the combined empty squares on a given board.
*/
get_empty_squares :: proc(board: map[PieceInfo]u64 = state.board.piece_map) -> u64 {
  positions: u64 = 0
  positions |= (~get_white_pieces(board) & (~get_black_pieces(board)))
  return positions
}

/*
Functons for calculating all of the possible piece moves and captures.
board: board to evaluate the moves and captures for.
square: the location of the piece to evaluate.
colour: the colour of the piece which is being evaluated.

Work from the pre-calculated list of all available moves and captures for that given piece type and piece location and narrows down from that list based on the specific board properties.
*/
get_pawn_moves_and_captures :: proc(board: map[PieceInfo]u64 = state.board.piece_map, square: u64 = state.selected_square, colour: Colour = state.to_move) {
  if colour == .WHITE {
    if get_empty_squares(board) & (square >> 8) != 0 {
      state.move_options |= PAWN_MOVES_W[square_to_index(square)] & get_empty_squares(board)
    }
    black_pieces := get_black_pieces(board)
    state.capture_options |= black_pieces & (square >> 9)
    state.capture_options |= black_pieces & (square >> 7)
    if get_rank(square) == 5 && state.last_move.piece == .PAWN {
      file_diff: i8 = cast(i8)state.last_move.start_file - cast(i8)get_file(square)
      if file_diff == 1 || file_diff == -1 {
        if state.last_move.start_rank == 7 && state.last_move.end_rank == 5 {
          if file_diff == -1 {
            state.capture_options |= square >> 9
          } else {
            state.capture_options |= square >> 7
          }
        }
      }
    }
  } else {
    if get_empty_squares(board) & (square << 8) != 0 {
      state.move_options |= PAWN_MOVES_B[square_to_index(square)] & get_empty_squares(board)
    }
    white_pieces := get_white_pieces(board)
    state.capture_options |= white_pieces & (square << 9)
    state.capture_options |= white_pieces & (square << 7)
    if get_rank(square) == 4 && state.last_move.piece == .PAWN {
      file_diff: i8 = cast(i8)state.last_move.start_file - cast(i8)get_file(square)
      if file_diff == 1 || file_diff == -1 {
        if state.last_move.start_rank == 2 && state.last_move.end_rank == 4 {
          if file_diff == -1 {
            state.capture_options |= square << 7
          } else {
            state.capture_options |= square << 9
          }
        }
      }
    }
  }
}

get_knight_moves_and_captures :: proc(board: map[PieceInfo]u64 = state.board.piece_map, square: u64 = state.selected_square, colour: Colour = state.to_move) {
  state.move_options |= KNIGHT_MOVES[square_to_index(square)] & get_empty_squares(board)
  if colour == .WHITE {
    state.capture_options |= KNIGHT_MOVES[square_to_index(square)] & get_black_pieces(board)
  } else {
    state.capture_options |= KNIGHT_MOVES[square_to_index(square)] & get_white_pieces(board)
  }
}

get_bishop_moves_and_captures :: proc(board: map[PieceInfo]u64 = state.board.piece_map, square: u64 = state.selected_square, colour: Colour = state.to_move) {
  blocked_UL: bool
  blocked_UR: bool
  blocked_DR: bool
  blocked_DL: bool

  state.move_options |= BISHOP_MOVES[square_to_index(square)] & get_empty_squares(board)
  if colour == .WHITE {
    state.capture_options |= BISHOP_MOVES[square_to_index(square)] & get_black_pieces(board)
  } else {
    state.capture_options |= BISHOP_MOVES[square_to_index(square)] & get_white_pieces(board)
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

get_rook_moves_and_captures :: proc(board: map[PieceInfo]u64 = state.board.piece_map, square: u64 = state.selected_square, colour: Colour = state.to_move) {
  blocked_U: bool
  blocked_R: bool
  blocked_D: bool
  blocked_L: bool

  state.move_options |= ROOK_MOVES[square_to_index(square)] & get_empty_squares(board)
  if colour == .WHITE {
    state.capture_options |= ROOK_MOVES[square_to_index(square)] & get_black_pieces(board)
  } else {
    state.capture_options |= ROOK_MOVES[square_to_index(square)] & get_white_pieces(board)
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

get_queen_moves_and_captures :: proc(board: map[PieceInfo]u64 = state.board.piece_map, square: u64 = state.selected_square, colour: Colour = state.to_move) {
  blocked_U: bool
  blocked_R: bool
  blocked_D: bool
  blocked_L: bool

  blocked_UL: bool
  blocked_UR: bool
  blocked_DR: bool
  blocked_DL: bool
  
  state.move_options |= QUEEN_MOVES[square_to_index(square)] & get_empty_squares(board)
  if colour == .WHITE {
    state.capture_options |= QUEEN_MOVES[square_to_index(square)] & get_black_pieces(board)
  } else {
    state.capture_options |= QUEEN_MOVES[square_to_index(square)] & get_white_pieces(board)
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

get_king_moves_and_captures :: proc(board: map[PieceInfo]u64 = state.board.piece_map, square: u64 = state.selected_square, colour: Colour = state.to_move) {
  empty_squares := get_empty_squares(board)
  state.move_options |= KING_MOVES[square_to_index(square)] & empty_squares
  if colour == .WHITE {
    state.capture_options |= KING_MOVES[square_to_index(square)] & get_black_pieces(board)
    if state.can_castle_white_qs {
      if (empty_squares & (1 << 57) != 0) && (empty_squares & (1 << 58) != 0) && (empty_squares & (1 << 59) != 0) {
        temp_board := make(map[PieceInfo]u64)
        defer delete(temp_board)
        copy_board(&temp_board, state.board.piece_map)

        temp_board[KING_W] ~= (1 << 59)
        temp_board[KING_W] ~= (1 << 58)
        temp_board[KING_W] ~= (1 << 57)
        if !is_check(temp_board, .WHITE) {
          state.move_options |= (1 << 58)
        }
      }
    }
    if state.can_castle_white_ks {
      if (empty_squares & (1 << 61) != 0) && (empty_squares & (1 << 62) != 0) {
        temp_board := make(map[PieceInfo]u64)
        defer delete(temp_board)
        copy_board(&temp_board, state.board.piece_map)

        temp_board[KING_W] ~= (1 << 61)
        temp_board[KING_W] ~= (1 << 62)
        if !is_check(temp_board, .WHITE) {
          state.move_options |= (1 << 62)
        }
      }
    }
  } else {
    state.capture_options |= KING_MOVES[square_to_index(square)] & get_white_pieces(board)
    if state.can_castle_black_qs {
      if (empty_squares & (1 << 1) != 0) && (empty_squares & (1 << 2) != 0) && (empty_squares & (1 << 3) != 0) {
        temp_board := make(map[PieceInfo]u64)
        defer delete(temp_board)
        copy_board(&temp_board, state.board.piece_map)

        temp_board[KING_W] ~= (1 << 1)
        temp_board[KING_W] ~= (1 << 2)
        temp_board[KING_W] ~= (1 << 3)
        if !is_check(temp_board, .BLACK) {
          state.move_options |= (1 << 2)
        }
      }
    }
    if state.can_castle_black_ks {
      if (empty_squares & (1 << 5) != 0) && (empty_squares & (1 << 6) != 0) {
        temp_board := make(map[PieceInfo]u64)
        defer delete(temp_board)
        copy_board(&temp_board, state.board.piece_map)

        temp_board[KING_W] ~= (1 << 5)
        temp_board[KING_W] ~= (1 << 6)
        if !is_check(temp_board, .BLACK) {
          state.move_options |= (1 << 6)
        }
      }
    }

  }
}
/*
Checks a given board state (current board state by default) and for a given colour pieces if the king is in check
Loops through all of the pieces of the opposite colour and evaluates the available captures one by one. If any piece can capture the king, the function returns true.
*/

is_check :: proc(board: map[PieceInfo]u64 = state.board.piece_map, colour: Colour = state.to_move) -> bool {
  saved_moves := state.move_options
  saved_captures := state.capture_options
  state.capture_options = 0
  state.move_options = 0
  to_check: u64 = 1

  for i in 1 ..= 64 {
    for piece_info, piece_map in board {
      if piece_info.colour != colour {
        if piece_map & to_check != 0 {
          #partial switch piece_info.piece {
          case .PAWN:
            get_pawn_moves_and_captures(board, to_check, .WHITE if colour == .BLACK else .BLACK)
          case .KNIGHT:
            get_knight_moves_and_captures(board, to_check, .WHITE if colour == .BLACK else .BLACK)
          case .BISHOP:
            get_bishop_moves_and_captures(board, to_check, .WHITE if colour == .BLACK else .BLACK)
          case .ROOK:
            get_rook_moves_and_captures(board, to_check, .WHITE if colour == .BLACK else .BLACK)
          case .QUEEN:
            get_queen_moves_and_captures(board, to_check, .WHITE if colour == .BLACK else .BLACK)
          }
          if state.capture_options & board[KING_W if colour == .WHITE else KING_B] != 0 {
            state.move_options = saved_moves
            state.capture_options = saved_captures
            return true
          }
          state.move_options = 0
          state.capture_options = 0
        }
      }
    }
    to_check <<= 1
  }
  state.move_options = saved_moves
  state.capture_options = saved_captures
  return false
}

/*
For a given piece type and location calculate all of the possible moves and capture for that piece and perform each individual move and capture. For each given board state, checks if the position results in check or not.

Returns true if for all moves and captures of a given piece the board states still result in check. Returns false otherwise.

Used to determine if a piece could be used to remove the check.
*/
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
        state.move_options = 0
        state.capture_options = 0
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
        state.move_options = 0
        state.capture_options = 0
        return false
      }
      copy_board(&state.board.piece_map, original_board)
    }
    to_move_to <<= 1
  }
  state.move_options = 0
  state.capture_options = 0
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
            get_pawn_moves_and_captures(square=to_check, colour=colour)
            if !check_moves_and_captures(piece_info, to_check) {
              return false
            }
          case .KNIGHT:
            get_knight_moves_and_captures(square=to_check, colour=colour)
            if !check_moves_and_captures(piece_info, to_check) {
              return false
            }
          case .BISHOP:
            get_bishop_moves_and_captures(square=to_check, colour=colour)
            if !check_moves_and_captures(piece_info, to_check) {
              return false
            }
          case .ROOK:
            get_rook_moves_and_captures(square=to_check, colour=colour)
            if !check_moves_and_captures(piece_info, to_check) {
              return false
            }
          case .QUEEN:
            get_queen_moves_and_captures(square=to_check, colour=colour)
            if !check_moves_and_captures(piece_info, to_check) {
              return false
            }
          case .KING:
            get_king_moves_and_captures(square=to_check, colour=colour)
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
