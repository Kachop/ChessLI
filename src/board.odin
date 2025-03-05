#+feature dynamic-literals

package main

import "core:fmt"
import nc "shared:ncurses/src"
import "core:c"

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

Board :: struct {
    tile_map: map[rune][8]PieceInfo,
    piece_map: map[rune][dynamic]PieceInfo,
}

draw_board :: proc(win: ^nc.Window) {
  x : c.int = 0
  y : c.int = 0
  if state.to_move == .WHITE {
    if state.mode == .SELECT {
      for file in 'a' ..= 'h' {
        rank := state.board.tile_map[file]
        y = 0
        for index := 7; index >= 0; index -= 1 {
          piece := rank[index]
          draw_piece(win, x, y, piece)
          y += 8
        }
        x += 16
      }
 
      x = 0
      y = 0

      for file in 'a' ..= 'h' {
        rank := state.board.piece_map[file]
        y = 0
        for index := 7; index >= 0; index -= 1 {
          piece := rank[index]
          if file == state.hovered_file && cast(c.int)index == state.hovered_rank {
            draw_piece(win, x, y, piece, 5)
          } else {
            draw_piece(win, x, y, piece)
          }
          y += 8
        }
        x += 16
      }
    } else if state.mode == .MOVE {
      for file in 'a' ..= 'h' {
        rank := state.board.tile_map[file]
        y = 0
        for index := 7; index >= 0; index -= 1 {
          piece := rank[index]
          draw_piece(win, x, y, piece)
          y += 8
        }
        x += 16
      }

      x = 0
      y = 0

      for file in 'a' ..= 'h' {
        rank := state.board.tile_map[file]
        y = 0
        for index := 7; index >= 0; index -= 1 {
          piece := rank[index]
          for i in 0 ..< len(state.move_option_files) {
            if file == state.move_option_files[i] && cast(c.int)index == state.move_option_ranks[i] {
              draw_piece(win, x, y, piece, 6)
            }
          }
          for i in 0 ..< len(state.capture_option_files) {
            if file == state.capture_option_files[i] && cast(c.int)index == state.capture_option_ranks[i] {
              draw_piece(win, x, y, piece, 5)
            }
          }
          y += 8
        }
        x += 16
      }

      x = 0
      y = 0

      for file in 'a' ..= 'h' {
        rank := state.board.piece_map[file]
        y = 0
        for index := 7; index >= 0; index -= 1 {
          piece := rank[index]
          if file == state.selected_file && cast(c.int)index == state.selected_rank {
            draw_piece(win, x, y, piece, 5)
          } else {
            draw_piece(win, x, y, piece)
          }
          if file == state.hovered_file && cast(c.int)index == state.hovered_rank {
            nc.wattron(win, nc.A_BLINK)
            draw_piece(win, x, y, state.board.piece_map[state.selected_file][state.selected_rank])
            nc.wattroff(win, nc.A_BLINK)
          } else {
            draw_piece(win, x, y, piece)
          }
          y += 8
        }
        x += 16
      }
    }
  } else {
    if state.mode == .SELECT {
      for file := 'h'; file >= 'a'; file -= 1 {
        rank := state.board.tile_map[file]
        y = 0
        for index := 0; index <= 7; index += 1 {
          piece := rank[index]
          draw_piece(win, x, y, piece)
          y += 8
        }
        x += 16
      }
 
      x = 0
      y = 0

      for file := 'h'; file >= 'a'; file -= 1 {
        rank := state.board.piece_map[file]
        y = 0
        for index := 0; index <= 7; index += 1 {
          piece := rank[index]
          if file == state.hovered_file && cast(c.int)index == state.hovered_rank {
            draw_piece(win, x, y, piece, 5)
          } else {
            draw_piece(win, x, y, piece)
          }
          y += 8
        }
        x += 16
      }
    } else if state.mode == .MOVE {
      for file := 'h'; file >= 'a'; file -= 1 {
        rank := state.board.tile_map[file]
        y = 0
        for index := 0; index <= 7; index += 1 {
          piece := rank[index]
          draw_piece(win, x, y, piece)
          y += 8
        }
        x += 16
      }

      x = 0
      y = 0

      for file := 'h'; file >= 'a'; file -= 1 {
        rank := state.board.tile_map[file]
        y = 0
        for index := 0; index <= 7; index += 1 {
          piece := rank[index]
          for i in 0 ..< len(state.move_option_files) {
            if file == state.move_option_files[i] && cast(c.int)index == state.move_option_ranks[i] {
              draw_piece(win, x, y, piece, 6)
            }
          }
          for i in 0 ..< len(state.capture_option_files) {
            if file == state.capture_option_files[i] && cast(c.int)index == state.capture_option_ranks[i] {
              draw_piece(win, x, y, piece, 5)
            }
          }
          y += 8
        }
        x += 16
      }

      x = 0
      y = 0

      for file := 'h'; file >= 'a'; file -= 1 {
        rank := state.board.piece_map[file]
        y = 0
        for index := 0; index <= 7; index += 1 {
          piece := rank[index]
          if file == state.selected_file && cast(c.int)index == state.selected_rank {
            draw_piece(win, x, y, piece, 5)
          } else {
            draw_piece(win, x, y, piece)
          }
          if file == state.hovered_file && cast(c.int)index == state.hovered_rank {
            nc.wattron(win, nc.A_BLINK)
            draw_piece(win, x, y, state.board.piece_map[state.selected_file][state.selected_rank])
            nc.wattroff(win, nc.A_BLINK)
          } else {
            draw_piece(win, x, y, piece)
          }
          y += 8
        }
        x += 16
      }
    }
  }
}

getDefaultBoard :: proc() -> Board {
    board := Board{}

    board.tile_map['a'] = [8]PieceInfo{TILE_B, TILE_W, TILE_B, TILE_W, TILE_B, TILE_W, TILE_B, TILE_W}
    board.tile_map['b'] = [8]PieceInfo{TILE_W, TILE_B, TILE_W, TILE_B, TILE_W, TILE_B, TILE_W, TILE_B}
    board.tile_map['c'] = [8]PieceInfo{TILE_B, TILE_W, TILE_B, TILE_W, TILE_B, TILE_W, TILE_B, TILE_W}
    board.tile_map['d'] = [8]PieceInfo{TILE_W, TILE_B, TILE_W, TILE_B, TILE_W, TILE_B, TILE_W, TILE_B}
    board.tile_map['e'] = [8]PieceInfo{TILE_B, TILE_W, TILE_B, TILE_W, TILE_B, TILE_W, TILE_B, TILE_W}
    board.tile_map['f'] = [8]PieceInfo{TILE_W, TILE_B, TILE_W, TILE_B, TILE_W, TILE_B, TILE_W, TILE_B}
    board.tile_map['g'] = [8]PieceInfo{TILE_B, TILE_W, TILE_B, TILE_W, TILE_B, TILE_W, TILE_B, TILE_W}
    board.tile_map['h'] = [8]PieceInfo{TILE_W, TILE_B, TILE_W, TILE_B, TILE_W, TILE_B, TILE_W, TILE_B}

    board.piece_map['a'] = [dynamic]PieceInfo{ROOK_W, PAWN_W, PieceInfo{}, PieceInfo{}, PieceInfo{}, PieceInfo{}, PAWN_B, ROOK_B}
    board.piece_map['b'] = [dynamic]PieceInfo{KNIGHT_W, PAWN_W, PieceInfo{}, PieceInfo{}, PieceInfo{}, PieceInfo{}, PAWN_B, KNIGHT_B}
    board.piece_map['c'] = [dynamic]PieceInfo{BISHOP_W, PAWN_W, PieceInfo{}, PieceInfo{}, PieceInfo{}, PieceInfo{}, PAWN_B, BISHOP_B}
    board.piece_map['d'] = [dynamic]PieceInfo{QUEEN_W, PAWN_W, PieceInfo{}, PieceInfo{}, PieceInfo{}, PieceInfo{}, PAWN_B, QUEEN_B}
    board.piece_map['e'] = [dynamic]PieceInfo{KING_W, PAWN_W, PieceInfo{}, PieceInfo{}, PieceInfo{}, PieceInfo{}, PAWN_B, KING_B}
    board.piece_map['f'] = [dynamic]PieceInfo{BISHOP_W, PAWN_W, PieceInfo{}, PieceInfo{}, PieceInfo{}, PieceInfo{}, PAWN_B, BISHOP_B}
    board.piece_map['g'] = [dynamic]PieceInfo{KNIGHT_W, PAWN_W, PieceInfo{}, PieceInfo{}, PieceInfo{}, PieceInfo{}, PAWN_B, KNIGHT_B}
    board.piece_map['h'] = [dynamic]PieceInfo{ROOK_W, PAWN_W, PieceInfo{}, PieceInfo{}, PieceInfo{}, PieceInfo{}, PAWN_B, ROOK_B}
    return board
}

check_square_for_piece :: proc(file: rune, rank: c.int, colour: Colour) -> bool {
  if state.board.piece_map[file][rank].piece != .NONE && state.board.piece_map[file][rank].colour == colour {
    return true
  }
  return false
}

check_valid_move_or_capture :: proc(file: rune, rank: c.int) -> bool {
  for i in 0 ..< len(state.move_option_files) {
    if state.hovered_file == state.move_option_files[i] && state.hovered_rank == state.move_option_ranks[i] {
      return true
    }
  }

  for i in 0 ..< len(state.capture_option_files) {
    if state.hovered_file == state.capture_option_files[i] && state.hovered_rank == state.capture_option_ranks[i] {
      return true
    }
  }
  return false
}
