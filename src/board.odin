#+feature dynamic-literals

package main

import "core:fmt"
import "core:math"
import t "shared:TermCL"

/*
All tools for managing to board and board-state
*/

RANK_1 :: 7
RANK_2 :: 6
RANK_3 :: 5
RANK_4 :: 4
RANK_5 :: 3
RANK_6 :: 2
RANK_7 :: 1
RANK_8 :: 0

ranks := [8]i32{RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8}
/*
Board :: struct {
    tile_map: map[rune][8]PieceInfo,
    piece_map: map[rune][dynamic]PieceInfo,
}
*/

Board :: struct {
  tile_map: u64,
  piece_map: map[PieceInfo]u64
}

Move :: struct {
  piece: Piece,
  start_file: rune,
  end_file: rune,
  start_rank: uint,
  end_rank: uint,
}

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

get_rank :: proc(square: u64) -> u8 {
  square := square
  rank: u8 = 8
  for square > (1 << 7) {
    square >>= 8
    rank -= 1
  }
  return rank
}

get_piece :: proc(square: u64) -> PieceInfo {
  for piece, piece_map in state.board.piece_map {
    if square & piece_map != 0 {
      return piece
    }
  }
  return PieceInfo{}
}

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
draw_board :: proc(win: ^t.Screen) {
  old_allocator := context.allocator
  context.allocator = context.temp_allocator
  x : uint = 2
  y : uint = 1

  if state.to_move == .WHITE {
    //Draw tiles
    for file in 'a' ..= 'h' {
      rank := state.board.tile_map[file]
      y = 1
      for index := 7; index >= 0; index -= 1 {
        tile := rank[index]
        piece := state.board.piece_map[file][index]
        draw_piece(win, x, y, tile)
        draw_piece(win, x, y, piece)

        y += 8
      }
      x += 16
    }
    if state.mode == .SELECT { 
      x = 2
      y = 1

      for file in 'a' ..= 'h' {
        //Draw pieces
        rank := state.board.piece_map[file]
        y = 1
        for index := 7; index >= 0; index -= 1 {
          piece := rank[index]
          if file == state.hovered_file && cast(uint)index == state.hovered_rank {
            draw_piece(win, x, y, piece, 4)
          }
          y += 8
        }
        x += 16
      }
    } else if state.mode == .MOVE {
      x = 2
      y = 1

      for file in 'a' ..= 'h' {
        rank := state.board.tile_map[file]
        y = 1
        for index := 7; index >= 0; index -= 1 {
          piece := rank[index]
          for i in 0 ..< len(state.move_option_files) {
            if file == state.move_option_files[i] && cast(uint)index == state.move_option_ranks[i] {
              draw_piece(win, x, y, piece, 5)
            }
          }
          for i in 0 ..< len(state.capture_option_files) {
            if file == state.capture_option_files[i] && cast(uint)index == state.capture_option_ranks[i] {
              tile := state.board.tile_map[file][index]
              draw_piece(win, x, y, tile, 4)
              piece := state.board.piece_map[file][index]
              draw_piece(win, x, y, piece)
            }
          }
          y += 8
        }
        x += 16
      }
      x = 2
      y = 1

      for file in 'a' ..= 'h' {
        rank := state.board.piece_map[file]
        y = 1
        for index := 7; index >= 0; index -= 1 {
          piece := rank[index]
          if file == state.selected_file && cast(uint)index == state.selected_rank {
            draw_piece(win, x, y, piece, 4)
          }
          if file == state.hovered_file && cast(uint)index == state.hovered_rank {
            draw_piece(win, x, y, state.board.piece_map[state.selected_file][state.selected_rank])
          }
          y += 8
        }
        x += 16
      }
    }
  } else {
    //Draw tiles and pieces
    for file := 'h'; file >= 'a'; file -= 1 {
      rank := state.board.tile_map[file]
      y = 1
      for index := 0; index <= 7; index += 1 {
        tile := rank[index]
        piece := state.board.piece_map[file][index]
        draw_piece(win, x, y, tile)
        draw_piece(win, x, y, piece)

        y += 8
      }
      x += 16
    }
    if state.mode == .SELECT {
      x = 2
      y = 1

      for file := 'h'; file >= 'a'; file -= 1 {
        rank := state.board.piece_map[file]
        y = 1
        for index := 0; index <= 7; index += 1 {
          piece := rank[index]
          if file == state.hovered_file && cast(uint)index == state.hovered_rank {
            draw_piece(win, x, y, piece, 4)
          }
          y += 8
        }
        x += 16
      }
    } else if state.mode == .MOVE {
      x = 2
      y = 1

      for file := 'h'; file >= 'a'; file -= 1 {
        rank := state.board.tile_map[file]
        y = 1
        for index := 0; index <= 7; index += 1 {
          piece := rank[index]
          for i in 0 ..< len(state.move_option_files) {
            if file == state.move_option_files[i] && cast(uint)index == state.move_option_ranks[i] {
              draw_piece(win, x, y, piece, 5)
            }
          }
          for i in 0 ..< len(state.capture_option_files) {
            if file == state.capture_option_files[i] && cast(uint)index == state.capture_option_ranks[i] {
              tile := state.board.tile_map[file][index]
              draw_piece(win, x, y, tile, 4)
              piece := state.board.piece_map[file][index]
              draw_piece(win, x, y, piece)
            }
          }
          y += 8
        }
        x += 16
      }

      x = 2
      y = 1

      for file := 'h'; file >= 'a'; file -= 1 {
        rank := state.board.piece_map[file]
        y = 1
        for index := 0; index <= 7; index += 1 {
          piece := rank[index]
          if file == state.selected_file && cast(uint)index == state.selected_rank {
            draw_piece(win, x, y, piece, 4)
          }
          if file == state.hovered_file && cast(uint)index == state.hovered_rank {
            draw_piece(win, x, y, state.board.piece_map[state.selected_file][state.selected_rank])
          }
          y += 8
        }
        x += 16
      }
    }
  }
  context.allocator = old_allocator
}
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
copy_board :: proc(copy_to: ^map[rune][dynamic]PieceInfo, copy_from: map[rune][dynamic]PieceInfo) {
  old_allocator := context.temp_allocator
  context.temp_allocator = context.allocator

  for file := 'a'; file <= 'h'; file += 1 {
    copy_to[file] = [dynamic]PieceInfo{PieceInfo{}, PieceInfo{}, PieceInfo{}, PieceInfo{}, PieceInfo{}, PieceInfo{}, PieceInfo{}, PieceInfo{}}
    for rank := 0; rank <= 7; rank += 1 {
      copy_to[file][rank] = copy_from[file][rank]
    }
  }
  context.temp_allocator = old_allocator
}
*/
check_square_for_piece :: proc(square: u64, colour: Colour) -> bool {
  for piece, piece_map in state.board.piece_map {
    if piece_map & square != 0  && piece.colour == colour{
      return true
    }
  }
  return false
}

check_valid_move_or_capture :: proc(square: u64) -> bool {
  if square & (state.move_options | state.capture_options) != 0 {
    return true
  }
  return false
}
