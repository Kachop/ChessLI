package main

import "core:fmt"
import nc "shared:ncurses/src"
import "core:c"
/*
All infor needed for drawing pieces to the screen
*/

//WHITE_PIECE :: "██"
WHITE_PIECE :: "##"
WHITE_BACKGROUND :: "00"
BLACK_PIECE :: "||"
BLACK_BACKGROUND :: "  "

TILE_IMG :: [64]u8{0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0}

PAWN_IMG :: [64]u8{0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 1, 1, 0, 0, 0,
    0, 0, 0, 1, 1, 0, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0,
    0, 0, 0, 1, 1, 0, 0, 0,
    0, 0, 0, 1, 1, 0, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0,
    0, 1, 1, 1, 1, 1, 1, 0}

ROOK_IMG :: [64]u8{0, 0, 0, 0, 0, 0, 0, 0,
    0, 1, 0, 1, 1, 0, 1, 0,
    0, 1, 1, 1, 1, 1, 1, 0,
    0, 0, 1, 1, 1, 1, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0,
    0, 1, 1, 1, 1, 1, 1, 0,
    0, 1, 1, 1, 1, 1, 1, 0}

KNIGHT_IMG :: [64]u8{0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 1, 1, 0, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0,
    0, 1, 1, 1, 1, 1, 0, 0,
    0, 1, 1, 1, 1, 1, 0, 0,
    0, 0, 0, 1, 1, 1, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0,
    0, 1, 1, 1, 1, 1, 1, 0}

BISHOP_IMG :: [64]u8{0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 1, 1, 0, 0, 0,
    0, 0, 1, 1, 0, 0, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0,
0, 0, 0, 1, 1, 0, 0, 0,
    0, 0, 0, 1, 1, 0, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0,
    0, 1, 1, 1, 1, 1, 1, 0}

QUEEN_IMG :: [64]u8{0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 1, 1, 0, 0, 0,
    0, 1, 0, 1, 1, 0, 1, 0,
    0, 1, 1, 1, 1, 1, 1, 0,
    0, 0, 1, 1, 1, 1, 0, 0,
    0, 0, 0, 1, 1, 0, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0,
    0, 1, 1, 1, 1, 1, 1, 0}

KING_IMG :: [64]u8{0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 1, 1, 0, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0,
    0, 0, 0, 1, 1, 0, 0, 0,
    0, 1, 1, 1, 1, 1, 1, 0,
    0, 1, 1, 1, 1, 1, 1, 0,
    0, 0, 1, 1, 1, 1, 0, 0,
    0, 1, 1, 1, 1, 1, 1, 0}

Piece :: enum {
    NONE,

    PAWN,
    KNIGHT,
    BISHOP,
    ROOK,
    QUEEN,
    KING,
}

Colour :: enum {
    NONE,
    WHITE,
    BLACK,
}

PieceInfo :: struct {
    piece: Piece,
    colour: Colour,
    image: [64]u8,
}

TILE_W :: PieceInfo {
    piece = .NONE,
    colour = .WHITE,
    image = TILE_IMG,
}

TILE_B :: PieceInfo {
    piece = .NONE,
    colour = .BLACK,
    image = TILE_IMG,
}

PAWN_W :: PieceInfo {
    piece = .PAWN,
    colour = .WHITE,
    image = PAWN_IMG,
}

PAWN_B :: PieceInfo {
    piece = .PAWN,
    colour = .BLACK,
    image = PAWN_IMG,
}

KNIGHT_W :: PieceInfo {
    piece = .KNIGHT,
    colour = .WHITE,
    image = KNIGHT_IMG,
}

KNIGHT_B :: PieceInfo {
    piece = .KNIGHT,
    colour = .BLACK,
    image = KNIGHT_IMG,
}

BISHOP_W :: PieceInfo {
    piece = .BISHOP,
    colour = .WHITE,
    image = BISHOP_IMG,
}

BISHOP_B :: PieceInfo {
    piece = .BISHOP,
    colour = .BLACK,
    image = BISHOP_IMG,
}

ROOK_W :: PieceInfo {
    piece = .ROOK,
    colour = .WHITE,
    image = ROOK_IMG,
}

ROOK_B :: PieceInfo {
    piece = .ROOK,
    colour = .BLACK,
    image = ROOK_IMG,
}

QUEEN_W :: PieceInfo {
    piece = .QUEEN,
    colour = .WHITE,
    image = QUEEN_IMG,
}

QUEEN_B :: PieceInfo {
    piece = .QUEEN,
    colour = .BLACK,
    image = QUEEN_IMG,
}

KING_W :: PieceInfo {
    piece = .KING,
    colour = .WHITE,
    image = KING_IMG,
}

KING_B :: PieceInfo {
    piece = .KING,
    colour = .BLACK,
    image = KING_IMG,
}

draw_piece :: proc(win: ^nc.Window, x, y: c.int, piece: PieceInfo, colour: c.int = 0) {
  draw_x := x
  draw_y := y

  for pixel, i in piece.image {
    if piece.piece != .NONE {
      if pixel == 1 {
        if piece.colour == .WHITE {
          if colour == 0 {
            nc.wattron(win, nc.COLOR_PAIR(1))
            nc.mvwprintw(win, draw_y, draw_x, "%s", WHITE_PIECE)
            nc.wattroff(win, nc.COLOR_PAIR(1))
          } else {
            nc.wattron(win, nc.COLOR_PAIR(colour))
            nc.mvwprintw(win, draw_y, draw_x, "%s", WHITE_PIECE)
            nc.wattroff(win, nc.COLOR_PAIR(colour))
          }
        } else {
          if colour == 0 {
            nc.wattron(win, nc.COLOR_PAIR(2))
            nc.mvwprintw(win, draw_y, draw_x, "%s", BLACK_PIECE)
            nc.wattroff(win, nc.COLOR_PAIR(2))
          } else {
            nc.wattron(win, nc.COLOR_PAIR(colour))
            nc.mvwprintw(win, draw_y, draw_x, "%s", BLACK_PIECE)
            nc.wattroff(win, nc.COLOR_PAIR(colour))
          }
        }
      }
    } else if piece.piece == .NONE && piece.colour != .NONE {
      if piece.colour == .WHITE {
        if colour == 0 {
          nc.wattron(win, nc.COLOR_PAIR(3))
          nc.mvwprintw(win, draw_y, draw_x, "%s", BLACK_BACKGROUND)
          nc.wattroff(win, nc.COLOR_PAIR(3))
        } else {
          nc.wattron(win, nc.COLOR_PAIR(colour))
          nc.mvwprintw(win, draw_y, draw_x, "%s", BLACK_BACKGROUND)
          nc.wattroff(win, nc.COLOR_PAIR(colour))
        }
      } else {
        if colour == 0 {
          nc.wattron(win, nc.COLOR_PAIR(4))
          nc.mvwprintw(win, draw_y, draw_x, "%s", BLACK_BACKGROUND)
          nc.wattroff(win, nc.COLOR_PAIR(4))
        } else {
          nc.wattron(win, nc.COLOR_PAIR(colour))
          nc.mvwprintw(win, draw_y, draw_x, "%s", BLACK_BACKGROUND)
          nc.wattroff(win, nc.COLOR_PAIR(colour))
        }
      }
    }

    draw_x += 2

    if (i + 1) % 8 == 0 {
      draw_x = x
      draw_y += 1
    }
  }
  //nc.wrefresh(win)
}
