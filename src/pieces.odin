package main

import t "shared:TermCL"

/*
ASCII representation of chess board tiles and all of the pieces.
*/
WHITE_PIECE :: "##"
WHITE_BACKGROUND :: "00"
BLACK_PIECE :: "||"
BLACK_BACKGROUND :: "  "

TILE_MAP :: [64]u8{0, 1, 0, 1, 0, 1, 0, 1,
  1, 0, 1, 0, 1, 0, 1, 0,
  0, 1, 0, 1, 0, 1, 0, 1,
  1, 0, 1, 0, 1, 0, 1, 0,
  0, 1, 0, 1, 0, 1, 0, 1,
  1, 0, 1, 0, 1, 0, 1, 0,
  0, 1, 0, 1, 0, 1, 0, 1,
  1, 0, 1, 0, 1, 0, 1, 0}

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

/*
Individual piece types. Seperates all individual piece types, even by colour.
*/
PieceType :: enum {
  PAWN_W,
  KNIGHT_W,
  BISHOP_W,
  ROOK_W,
  QUEEN_W,
  KING_W,
  PAWN_B,
  KNIGHT_B,
  BISHOP_B,
  ROOK_B,
  QUEEN_B,
  KING_B,
}

/*
Each individual piece type without explicit colour information.
*/
Piece :: enum {
  NONE,

  PAWN,
  KNIGHT,
  BISHOP,
  ROOK,
  QUEEN,
  KING,
}

/*
Piece colour. .NONE is used for tiles, so that they don't flag as white or black pieces.
*/
Colour :: enum {
  NONE,
  WHITE,
  BLACK,
}

/*
All the inforation needed about a specific piece type.
*/
PieceInfo :: struct {
  piece: Piece,
  value: uint,
  colour: Colour,
  image: [64]u8,
}

/*
White tile piece information
*/
TILE_W :: PieceInfo {
  piece = .NONE,
  value = 0,
  colour = .WHITE,
  image = TILE_IMG,
}

/*
Black tile piece information
*/
TILE_B :: PieceInfo {
  piece = .NONE,
  value = 0,
  colour = .BLACK,
  image = TILE_IMG,
}

/*
White pawn piece information
*/
PAWN_W :: PieceInfo {
  piece = .PAWN,
  value = 1,
  colour = .WHITE,
  image = PAWN_IMG,
}

/*
Black pawn piece information
*/
PAWN_B :: PieceInfo {
  piece = .PAWN,
  value = 1,
  colour = .BLACK,
  image = PAWN_IMG,
}

/*
White knight piece information
*/
KNIGHT_W :: PieceInfo {
  piece = .KNIGHT,
  value = 3,
  colour = .WHITE,
  image = KNIGHT_IMG,
}

/*
Black knight piece information
*/
KNIGHT_B :: PieceInfo {
  piece = .KNIGHT,
  value = 3,
  colour = .BLACK,
  image = KNIGHT_IMG,
}

/*
White bishop piece information
*/
BISHOP_W :: PieceInfo {
  piece = .BISHOP,
  value = 3,
  colour = .WHITE,
  image = BISHOP_IMG,
}

/*
Black bishop piece information
*/
BISHOP_B :: PieceInfo {
  piece = .BISHOP,
  value = 3,
  colour = .BLACK,
  image = BISHOP_IMG,
}

/*
White rook piece information
*/
ROOK_W :: PieceInfo {
  piece = .ROOK,
  value = 5,
  colour = .WHITE,
  image = ROOK_IMG,
}

/*
Black rook piece information
*/
ROOK_B :: PieceInfo {
  piece = .ROOK,
  value = 5,
  colour = .BLACK,
  image = ROOK_IMG,
}

/*
White queen piece information
*/
QUEEN_W :: PieceInfo {
  piece = .QUEEN,
  value = 9,
  colour = .WHITE,
  image = QUEEN_IMG,
}

/*
Black queen piece information
*/
QUEEN_B :: PieceInfo {
  piece = .QUEEN,
  value = 9,
  colour = .BLACK,
  image = QUEEN_IMG,
}

/*
White king piece information
*/
KING_W :: PieceInfo {
  piece = .KING,
  value = 10,
  colour = .WHITE,
  image = KING_IMG,
}

/*
Black king piece information
*/
KING_B :: PieceInfo {
  piece = .KING,
  value = 10,
  colour = .BLACK,
  image = KING_IMG,
}

/*
Function for drawing an individual piece.
win: The screen to draw the piece to.
x, y: The coordinates to draw the piece. (0, 0) is top-left.
piece: The piece to draw. Each PieceInfo contains the image data for drawing the piece.
colour: colour to draw the piece, default just draws the piece white or black, other colours are used to highlight pieces for example.
*/
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
