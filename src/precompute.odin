package main

import "core:fmt"

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

precompute_pawn_moves :: proc() -> [64]u64 {
  pawn_moves: [64]u64
  for i in 0 ..< 64 {
    moves: u64 = 0
    pawn_board: u64 = 1 << cast(u8)i
    if state.to_move == .WHITE {
      moves |= pawn_board >> 8
      if 48 <= i && i <= 55 {
        moves |= pawn_board >> 16
      }
    } else {
      moves |= pawn_board << 8
      if 8 <= i && i <= 15 {
        moves |= pawn_board << 16
      }
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
    moves |= knight_board >> 17
    moves |= knight_board >> 15
    moves |= knight_board >> 10
    moves |= knight_board >> 6
    moves |= knight_board << 6
    moves |= knight_board << 10
    moves |= knight_board << 15
    moves |= knight_board << 17
  }
  return knight_moves
}

precompute_bishop_moves :: proc() -> [64]u64 {
  bishop_moves: [64]u64
  for i in 0 ..< 64 {
    moves: u64 = 0
    bishop_board: u64 = 1 << cast(u8)i
    for j in 0 ..< 8 {
      moves |= bishop_board << cast(u8)(j * 7)
      moves |= bishop_board << cast(u8)(j * 9)
      moves |= bishop_board >> cast(u8)(j * 7)
      moves |= bishop_board >> cast(u8)(j * 9)
    }
  }
  return bishop_moves
}

precompute_rook_moves :: proc() -> [64]u64 {
  rook_moves: [64]u64
  for i in 0 ..< 64 {
    moves: u64 = 0
    rook_board: u64 = 1 << cast(u8)i
    for j in 0 ..< 8 {
      moves |= rook_board << cast(u8)(j * 8)
      moves |= rook_board >> cast(u8)(j * 8)
    }
    moves_available := true
    shift: u8 = 0
    for moves_available {
      moves |= rook_board << shift
      shift += 1
      if (rook_board << shift) % 8 == 0 {
        moves_available = false
      }
    }
    moves_available = true
    shift = 0
    for moves_available {
      moves |= rook_board >> shift
      shift += 1
      if (rook_board >> shift) & 8 == 0 {
        moves_available = false
      }
    }
  }
  return rook_moves
}

precompute_queen_moves :: proc() -> [64]u64 {
  queen_moves: [64]u64
  for i in 0 ..< 64 {
    moves: u64 = 0
    queen_board: u64 = 1 << cast(u8)i
    for j in 0 ..< 8 {
      moves |= queen_board << cast(u8)(j * 9)
      moves |= queen_board << cast(u8)(j * 8)
      moves |= queen_board << cast(u8)(j * 7)
      moves |= queen_board >> cast(u8)(j * 9)
      moves |= queen_board >> cast(u8)(j * 8)
      moves |= queen_board >> cast(u8)(j * 7)
    }
    moves_available := true
    shift: u8 = 0
    for moves_available {
      moves |= queen_board << shift
      shift += 1
      if (queen_board << shift) & 8 == 0 {
        moves_available = false
      }
    }
    moves_available = true
    shift = 0
    for moves_available {
      moves |= queen_board >> shift
      shift += 1
      if (queen_board >> shift) & 8 == 0 {
        moves_available = false
      }
    }
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
  }
  return king_moves
}
