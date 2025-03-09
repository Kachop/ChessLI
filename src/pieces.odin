package main

import "core:fmt"
import t "shared:TermCL"
/*
All infor needed for drawing pieces to the screen
*/

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
  value: uint,
  colour: Colour,
  image: [64]u8,
}

TILE_W :: PieceInfo {
  piece = .NONE,
  value = 0,
  colour = .WHITE,
  image = TILE_IMG,
}

TILE_B :: PieceInfo {
  piece = .NONE,
  value = 0,
  colour = .BLACK,
  image = TILE_IMG,
}

PAWN_W :: PieceInfo {
  piece = .PAWN,
  value = 1,
  colour = .WHITE,
  image = PAWN_IMG,
}

PAWN_B :: PieceInfo {
  piece = .PAWN,
  value = 1,
  colour = .BLACK,
  image = PAWN_IMG,
}

KNIGHT_W :: PieceInfo {
  piece = .KNIGHT,
  value = 3,
  colour = .WHITE,
  image = KNIGHT_IMG,
}

KNIGHT_B :: PieceInfo {
  piece = .KNIGHT,
  value = 3,
  colour = .BLACK,
  image = KNIGHT_IMG,
}

BISHOP_W :: PieceInfo {
  piece = .BISHOP,
  value = 3,
  colour = .WHITE,
  image = BISHOP_IMG,
}

BISHOP_B :: PieceInfo {
  piece = .BISHOP,
  value = 3,
  colour = .BLACK,
  image = BISHOP_IMG,
}

ROOK_W :: PieceInfo {
  piece = .ROOK,
  value = 5,
  colour = .WHITE,
  image = ROOK_IMG,
}

ROOK_B :: PieceInfo {
  piece = .ROOK,
  value = 5,
  colour = .BLACK,
  image = ROOK_IMG,
}

QUEEN_W :: PieceInfo {
  piece = .QUEEN,
  value = 9,
  colour = .WHITE,
  image = QUEEN_IMG,
}

QUEEN_B :: PieceInfo {
  piece = .QUEEN,
  value = 9,
  colour = .BLACK,
  image = QUEEN_IMG,
}

KING_W :: PieceInfo {
  piece = .KING,
  value = 10,
  colour = .WHITE,
  image = KING_IMG,
}

KING_B :: PieceInfo {
  piece = .KING,
  value = 10,
  colour = .BLACK,
  image = KING_IMG,
}

draw_piece :: proc(win: ^t.Screen, x, y: uint, piece: PieceInfo, colour: uint = 0) {
  draw_x := x
  draw_y := y

  for pixel, i in piece.image {
    if piece.piece != .NONE {
      if pixel == 1 {
        if piece.colour == .WHITE {
          if colour == 0 {
            t.set_color_style_8(win, .White, .White)
            t.move_cursor(win, draw_y, draw_x)
            t.writef(win, "%s", WHITE_PIECE)
            t.reset_styles(win)
          } else {
            t.set_color_style_8(win, COLOURS[colour][0], COLOURS[colour][1])
            t.move_cursor(win, draw_y, draw_x)
            t.writef(win, "%s", WHITE_PIECE)
            t.reset_styles(win)
          }
        } else {
          if colour == 0 {
            t.set_color_style_8(win, .Black, .Black)
            t.move_cursor(win, draw_y, draw_x)
            t.writef(win, "%s", BLACK_PIECE)
            t.reset_styles(win)
          } else {
            t.set_color_style_8(win, COLOURS[colour][0], COLOURS[colour][1])
            t.move_cursor(win, draw_y, draw_x)
            t.writef(win, "%s", BLACK_PIECE)
            t.reset_styles(win)
          }
        }
      }
    } else if piece.piece == .NONE && piece.colour != .NONE {
      if piece.colour == .WHITE {
        if colour == 0 {
          t.set_color_style_8(win, .Black, .Cyan)
          t.move_cursor(win, draw_y, draw_x)
          t.writef(win, "%s", BLACK_BACKGROUND)
          t.reset_styles(win)
        } else {
          t.set_color_style_8(win, COLOURS[colour][0], COLOURS[colour][1])
          t.move_cursor(win, draw_y, draw_x)
          t.writef(win, "%s", BLACK_BACKGROUND)
          t.reset_styles(win)
        }
      } else {
        if colour == 0 {
          t.set_color_style_8(win, .Black, .Blue)
          t.move_cursor(win, draw_y, draw_x)
          t.writef(win, "%s", BLACK_BACKGROUND)
          t.reset_styles(win)
        } else {
          t.set_color_style_8(win, COLOURS[colour][0], COLOURS[colour][1])
          t.move_cursor(win, draw_y, draw_x)
          t.writef(win, "%s", BLACK_BACKGROUND)
          t.reset_styles(win)
        }
      }
    }

    draw_x += 2

    if (i + 1) % 8 == 0 {
      draw_x = x
      draw_y += 1
    }
  }
}
