package main

/*
Converts a given array of 64 numbers (0's and 1's) to a single u64. Used to lazily convert the default tile layout instead of hardcoding it.
*/
array_64_to_u64 :: proc(array: [64]u8) -> u64 {
  result: u64 = 0

  for val, i in array {
    if val == 1 {
      to_append: u64 = 1 << cast(u8)(63 - i)
      result |= to_append
    }
  }
  return result
}

/*
Returns the index (0-63) of any given square.
*/
square_to_index :: proc(square: u64) -> uint {
  square := square
  index: uint = 0
  for square > 1 {
    square >>= 1
    index += 1
  }
  return index
}

/*
Functions for precomputing all possible moves for each piece type for each board location.
Returns an array with all possible moves (u64) for each square. Index 0 is all moves for a piece in square 0, index 63 is all moves for a piece in square 63, and so on.
*/
precompute_pawn_moves_w :: proc() -> [64]u64 {
  pawn_moves: [64]u64
  for i in 0 ..< 64 {
    moves: u64 = 0
    pawn_board: u64 = 1 << cast(u8)i
      moves |= pawn_board >> 8
      if 48 <= i && i <= 55 {
        moves |= pawn_board >> 16
      }
    pawn_moves[i] = moves
  }
  return pawn_moves
}

precompute_pawn_moves_b :: proc() -> [64]u64 {
  pawn_moves: [64]u64
  for i in 0 ..< 64 {
    moves: u64 = 0
    pawn_board: u64 = 1 << cast(u8)i
      moves |= pawn_board << 8
      if 8 <= i && i <= 15 {
        moves |= pawn_board << 16
      }
    pawn_moves[i] = moves
  }
  return pawn_moves
}

precompute_knight_moves :: proc() -> [64]u64 {
  knight_moves: [64]u64
  for i in 0 ..< 64 {
    moves: u64 = 0
    knight_board: u64 = 1 << cast(u8)i
    if get_file(knight_board) > 2 && get_file(knight_board) < 7 {
      moves |= knight_board >> 17
      moves |= knight_board >> 15
      moves |= knight_board >> 10
      moves |= knight_board >> 6
      moves |= knight_board << 6
      moves |= knight_board << 10
      moves |= knight_board << 15
      moves |= knight_board << 17
    } else if get_file(knight_board) == 1 {
      moves |= knight_board >> 15
      moves |= knight_board >> 6
      moves |= knight_board << 10
      moves |= knight_board << 15
    } else if get_file(knight_board) == 2 {
      moves |= knight_board >> 17
      moves |= knight_board >> 15
      moves |= knight_board >> 6
      moves |= knight_board << 10
      moves |= knight_board << 15
      moves |= knight_board << 17
    } else if get_file(knight_board) == 7 {
      moves |= knight_board >> 17
      moves |= knight_board >> 15
      moves |= knight_board >> 10
      moves |= knight_board << 6
      moves |= knight_board << 15
      moves |= knight_board << 17
    } else if get_file(knight_board) == 8 {
      moves |= knight_board >> 17
      moves |= knight_board >> 10
      moves |= knight_board << 6
      moves |= knight_board << 17
    }
    knight_moves[i] = moves
  }
  return knight_moves
}

precompute_bishop_moves :: proc() -> [64]u64 {
  bishop_moves: [64]u64
  left_moves, right_moves := true, true
  for i in 0 ..< 64 {
    moves: u64 = 0
    bishop_board: u64 = 1 << cast(u8)i
    left_moves, right_moves = true, true
    for j in 1 ..< 8 {
      if get_file(bishop_board) != 1 && left_moves {
        moves |= bishop_board << cast(u8)(j * 7)
        moves |= bishop_board >> cast(u8)(j * 9)

        if get_file(bishop_board << cast(u8)(j * 7)) == 1 || get_file(bishop_board >> cast(u8)(j * 9)) == 1 {
          left_moves = false
        }
      }
      if get_file(bishop_board) != 8 && right_moves {
        moves |= bishop_board << cast(u8)(j * 9)
        moves |= bishop_board >> cast(u8)(j * 7)

        if get_file(bishop_board << cast(u8)(j * 9)) == 8 || get_file(bishop_board >> cast(u8)(j * 7)) == 8 {
          right_moves = false
        }
      }
    }
    bishop_moves[i] = moves
  }
  return bishop_moves
}

precompute_rook_moves :: proc() -> [64]u64 {
  rook_moves: [64]u64
  left_moves, right_moves := true, true
  for i in 0 ..< 64 {
    moves: u64 = 0
    rook_board: u64 = 1 << cast(u8)i
    left_moves, right_moves = true, true
    for j in 1 ..< 8 {
      moves |= rook_board << cast(u8)(j * 8)
      moves |= rook_board >> cast(u8)(j * 8)

      if get_file(rook_board) != 1 && left_moves {
        moves |= rook_board >> cast(u8)j
        if get_file(rook_board >> cast(u8)j) == 1 {
          left_moves = false
        }
      }
      if get_file(rook_board) != 8 && right_moves {
        moves |= rook_board << cast(u8)j
        if get_file(rook_board << cast(u8)j) == 8 {
          right_moves = false
        }
      }
    }
    rook_moves[i] = moves
  }
  return rook_moves
}

precompute_queen_moves :: proc() -> [64]u64 {
  queen_moves: [64]u64
  left_moves, right_moves := true, true
  for i in 0 ..< 64 {
    moves: u64 = 0
    queen_board: u64 = 1 << cast(u8)i
    left_moves, right_moves = true, true
    for j in 1 ..< 8 {
      if get_file(queen_board) != 1 && left_moves {
        moves |= queen_board << cast(u8)(j * 7)
        moves |= queen_board >> cast(u8)(j * 9)

        if get_file(queen_board << cast(u8)(j * 7)) == 1 || get_file(queen_board >> cast(u8)(j * 9)) == 1 {
          left_moves = false
        }
      }
      if get_file(queen_board) != 8 && right_moves {
        moves |= queen_board << cast(u8)(j * 9)
        moves |= queen_board >> cast(u8)(j * 7)

        if get_file(queen_board << cast(u8)(j * 9)) == 8 || get_file(queen_board >> cast(u8)(j * 7)) == 8 {
          right_moves = false
        }
      }
    }
    left_moves, right_moves = true, true
    for j in 1 ..< 8 {
      moves |= queen_board << cast(u8)(j * 8)
      moves |= queen_board >> cast(u8)(j * 8)

      if get_file(queen_board) != 1 && left_moves {
        moves |= queen_board >> cast(u8)j
        if get_file(queen_board >> cast(u8)j) == 1 {
          left_moves = false
        }
      }
      if get_file(queen_board) != 8 && right_moves {
        moves |= queen_board << cast(u8)j
        if get_file(queen_board << cast(u8)j) == 8 {
          right_moves = false
        }
      }
    }
    queen_moves[i] = moves
  }
  return queen_moves
}

precompute_king_moves :: proc() -> [64]u64 {
  king_moves: [64]u64
  for i in 0 ..< 64 {
    moves: u64 = 0
    king_board: u64 = 1 << cast(u8)i
    moves |= king_board << 9
    moves |= king_board << 8
    moves |= king_board << 7
    moves |= king_board << 1
    moves |= king_board >> 1
    moves |= king_board >> 7
    moves |= king_board >> 8
    moves |= king_board >> 9
    king_moves[i] = moves
  }
  return king_moves
}
