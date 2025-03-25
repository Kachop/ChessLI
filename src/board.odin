#+feature dynamic-literals

package main

import "core:math"
import t "shared:TermCL"

/*
Board struct
Stores the information about the a board state.
tile_map: Information about the light and dark tiles for the purpose of drawing the board.
piece_map: All of the piece locations. u64 for each piece type (White pawn, black bishop, etc). A 1 represents a piece of that type in that location, a 0 represents no piece of that type in that location.
*/
Board :: struct {
  tile_map: u64,
  piece_map: map[PieceInfo]u64
}

/*
Move struct
Stores all of the information about a given move.
piece: The piece that was moved, Pawn, Bishop, Queen etc.
start_file: The original file of the moved piece (1-8)
end_file: The terminating file of the moved piece (1-8)
start_rank: The starting rank of the moved piece (1-8)
end_rank: The finishing rank of the end piece (1-8)

Used for storing the information about the previous move, to determine when en-passeant moves are valid
*/
Move :: struct {
  piece: Piece,
  start_file: u8,
  end_file: u8,
  start_rank: u8,
  end_rank: u8,
}

/*
Function for drawing the board to the screen.
win: The screen to draw the board to.

Uses the information in the games global state to draw the current board to the screen.
(Maybe) Generalise this to draw any given board to the screen.
*/
draw_board :: proc(win: ^t.Screen) {
  old_allocator := context.allocator
  context.allocator = context.temp_allocator
  x: uint = 2
  y: uint = 1

  if state.to_move == .WHITE {
    y = 1
  } else {
    y = 57
  }

  for i in 0 ..< 64 {
    to_check: u64 = 1 << cast(u8)i
    if to_check & state.board.tile_map != 0 {
      if to_check & state.capture_options != 0 {
        draw_piece(win, x, y, TILE_W, 4)
      } else if to_check & state.move_options != 0 {
        draw_piece(win, x, y, TILE_W, 5)
      } else {
        draw_piece(win, x, y, TILE_W)
      }
    } else {
      if to_check & state.capture_options != 0 {
        draw_piece(win, x, y, TILE_B, 4)
      } else if to_check & state.move_options != 0 {
        draw_piece(win, x, y, TILE_B, 5)
      } else {
        draw_piece(win, x, y, TILE_B)
      }
    }
    for type, piece_map in state.board.piece_map {
      if to_check & state.hovered_square & state.capture_options != 0 {
        draw_piece(win, x, y, state.selected_piece)
      } else if to_check & state.hovered_square & state.move_options != 0 {
        draw_piece(win, x, y, state.selected_piece, 4)
      } else if to_check & piece_map != 0 {
        if to_check & state.hovered_square != 0 {
          draw_piece(win, x, y, type, 4)
        } else {
          draw_piece(win, x, y, type)
        }
      }
    }
    x += 16
    if (i + 1) % 8 == 0 {
      x = 2
      if state.to_move == .WHITE {
        y += 8
      } else {
        y -= 8
      }
    }
  }
}

/*
Returns the file (1-8) of any given square.
Square should be a single bit shifted between 0 and 63 bits to the left.
*/
get_file :: proc(square: u64) -> u8 {
  square := square
  for square > (1 << 7) {
    square >>= 8
  }
  file: u8
  for i in 0 ..= 7 {
    if (1 << cast(u8)i) & square != 0 {
      file = cast(u8)i+1
    }
  }
  return file
}

/*
Returns the rank (1-8) of any given square.
Square should be a single bit shifted between 0 and 63 bits to the left.
*/
get_rank :: proc(square: u64) -> u8 {
  square := square
  rank: u8 = 8
  for square > (1 << 7) {
    square >>= 8
    rank -= 1
  }
  return rank
}

/*
Returns the piece information of any given square.
Square should be a single bit shifted between 0 and 63 bits to the left.
Each square should only have one piece in at any time.
*/
get_piece :: proc(square: u64) -> PieceInfo {
  for piece, piece_map in state.board.piece_map {
    if square & piece_map != 0 {
      return piece
    }
  }
  return PieceInfo{}
}

/*
Returns the closest piece in a selection range between the start file and end file (1-8) and the start rank and end rank (1-8).
Used when there are no valid pieces to select on the same rank or file as the currently selected piece.
*/
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

/*
Returns the closest move or capture in a selection range between the start file and end file (1-8) and the start rank and end rank (1-8).
Used when there are no valid moves or captures to select on the same rank or file as the currently selected move or capture.
*/
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

/*
Returns the absolute distance between any 2 squares on the board.
Squares should be a single bit shifted by 0 or upto 63 bits to the left.
*/
calc_squares_distance :: proc(square1, square2: u64) -> f32 {
  square_1_file, square_1_rank: u8
  square_2_file, square_2_rank: u8

  file, rank: u8 = 1, 1

  to_check: u64 = 1

  for i in 1 ..= 64 {
    if to_check & square1 != 0 {
      square_1_file = file
      square_1_rank = rank
    }
    if to_check & square2 != 0 {
      square_2_file = file
      square_2_rank = rank
    }
    file += 1
    if file > 8 {
      file = 1
      rank += 1
    }
    to_check <<= 1
  }
  x_dist: f32 = abs(cast(f32)square_1_file - cast(f32)square_2_file)
  y_dist: f32 = abs(cast(f32)square_1_rank - cast(f32)square_2_rank)
  dist := math.sqrt((x_dist * x_dist) + (y_dist * y_dist))
  return dist
}

/*
Returns a Board with a completly default configuration for classical chess.
*/
getDefaultBoard :: proc() -> Board {
  old_allocator := context.temp_allocator
  context.temp_allocator = context.allocator
  board := Board{}
  board.tile_map = array_64_to_u64(TILE_MAP)
  
  piece: u64 = 1
  
  pawns_w: u64 = 0
  for i in 48 ..< 56 {
    pawns_w |= piece << cast(u8)i
  }

  pawns_b: u64 = 0
  for i in 8 ..< 16 {
    pawns_b |= piece << cast(u8)i
  }

  knights_w: u64 = 0
  knights_w |= piece << 57
  knights_w |= piece << 62

  knights_b: u64 = 0
  knights_b |= piece << 1
  knights_b |= piece << 6

  bishops_w: u64 = 0
  bishops_w |= piece << 58
  bishops_w |= piece << 61

  bishops_b: u64 = 0
  bishops_b |= piece << 2
  bishops_b |= piece << 5

  rooks_w: u64 = 0
  rooks_w |= piece << 56
  rooks_w |= piece << 63

  rooks_b: u64 = 0
  rooks_b |= piece << 0
  rooks_b |= piece << 7

  queen_w: u64 = 0
  queen_w |= piece << 59

  queen_b: u64 = 0
  queen_b |= piece << 3

  king_w: u64 = 0
  king_w |= piece << 60

  king_b: u64 = 0
  king_b |= piece << 4

  board.piece_map[PAWN_W] = pawns_w
  board.piece_map[PAWN_B] = pawns_b
  board.piece_map[KNIGHT_W] = knights_w
  board.piece_map[KNIGHT_B] = knights_b
  board.piece_map[BISHOP_W] = bishops_w
  board.piece_map[BISHOP_B] = bishops_b
  board.piece_map[ROOK_W] = rooks_w
  board.piece_map[ROOK_B] = rooks_b
  board.piece_map[QUEEN_W] = queen_w
  board.piece_map[QUEEN_B] = queen_b
  board.piece_map[KING_W] = king_w
  board.piece_map[KING_B] = king_b

  context.temp_allocator = old_allocator
  return board
}

/*
Copies the contents of one board into the other.
*/
copy_board :: proc(copy_to: ^map[PieceInfo]u64, copy_from: map[PieceInfo]u64) {
  for piece_info, piece_map in copy_from {
    copy_to[piece_info] = piece_map
  }
}

/*
Checks any square for a piece of a given colour and returns true of false based on the outcome.
(Maybe) Generalise for any board, instead of just using the global one.
*/
check_square_for_piece :: proc(square: u64, colour: Colour) -> bool {
  for piece, piece_map in state.board.piece_map {
    if piece_map & square != 0  && piece.colour == colour{
      return true
    }
  }
  return false
}

/*
Checks if a given square is a valid move or capture location for whatever piece has been currently selected.
*/
check_valid_move_or_capture :: proc(square: u64) -> bool {
  if square & (state.move_options | state.capture_options) != 0 {
    return true
  }
  return false
}
