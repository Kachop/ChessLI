package main

import "core:fmt"
import t "shared:TermCL"

/*
Mode enum.
.SELECT mode is for moving around your pieces and selecting a piece.
.MOVE mode is for moving around all a pieces given move or capture locations and selecting one.
*/
Mode :: enum {
  SELECT,
  MOVE,
}

/*
Global game state.
running: bool to track if the game is over or not.
move_no: Tracks the move number
check: Bool for tracking if the current board state is check.
to_move: The colour of the pieces who are currently selecting their move.
mode: Mode of the game, .SELECT or .MOVE.
board: global board state.
hovered_square: The square which the player is currently hovering on.
selected_square: The square which the player has selected (The piece which will be moved)
move_options: All of the available squares which can be moved to based on the currently selected piece.
capture_options: All of the available squares in which an enemy piece can be captures based on the currently selected piece.
last_move: Move struct which holds the information about the previous move, resets after every move.
can_castle_white_qs: Bool for if the white pieces can still perform a queen side castle.
can_castle_white_ks: Bool for if white can still castle on the king side.
can_castle_black_qs: Bool for whether black can castle on the queen side.
can_castle_black_ks: Bool for if black can do a king side castle.
*/
GameState :: struct {
  running: bool,
  move_no: u8,
  check: bool,
  to_move: Colour,
  mode: Mode,
  board: Board,
  hovered_square: u64,
  selected_square: u64,
  selected_piece: PieceInfo,
  move_options: u64,
  capture_options: u64,
  last_move: Move,
  can_castle_white_qs: bool,
  can_castle_white_ks: bool,
  can_castle_black_qs: bool,
  can_castle_black_ks: bool,
}

/*
Global variables.
s: Screen to draw the game to.
state: Global GameState struct.

PAWN_MOVES_W: pre-computed white pawn moves for every square.
PAWN_MOVES_B: pre-computed black pawn moves for every square.
KNIGHT_MOVES: pre-computed knight moves for every square.
BISHOP_MOVES: pre-computed bishop moves for each square.
ROOK_MOVES: pre-computed rook moves for every square.
QUEEN_MOVES: pre-computed queen moves for each square.
KING_MOVES: pre-computed king moves for all squares.

COLOURS: Array of foreground and background colour pairs to use for drawing to the terminal.
*/
s := t.init_screen()
state := GameState{}

PAWN_MOVES_W := precompute_pawn_moves_w()
PAWN_MOVES_B := precompute_pawn_moves_b()
KNIGHT_MOVES := precompute_knight_moves()
BISHOP_MOVES := precompute_bishop_moves()
ROOK_MOVES := precompute_rook_moves()
QUEEN_MOVES := precompute_queen_moves()
KING_MOVES := precompute_king_moves()

COLOURS := [][2]t.Color_8{
  {.White, .White},
  {.Black, .Black},
  {.Black, .Cyan},
  {.Black, .Blue},
  {.Red, .Red},
  {.Green, .Green}
}

/*
Main function for initialising the game and running the main game loop.
*/
main :: proc() {
  state.running = true
  state.move_no = 1
  state.to_move = .WHITE
  state.mode = .SELECT
  state.board = getDefaultBoard()
  state.hovered_square = (1 << 4) << (8 * 7)
  state.can_castle_white_qs = true
  state.can_castle_white_ks = true
  state.can_castle_black_qs = true
  state.can_castle_black_ks = true

  defer t.destroy_screen(&s)
  t.set_term_mode(&s, .Cbreak)
  t.hide_cursor(true)
  t.clear_screen(&s, .Everything)
  t.blit_screen(&s)

  draw_board(&s)
  draw_info(&s)

  for state.running {
    defer free_all(context.temp_allocator)
    defer t.blit_screen(&s)

    t.clear_screen(&s, .Everything)

    input, has_input := t.read(&s)
    keys := t.parse_keyboard_input(input)

    if keys.key == .Q {
      state.running = false
    }

    if state.mode == .SELECT {
      handle_select_input(keys.key)
    } else if state.mode == .MOVE {
      //Cycle through the available moves and move the piece
      handle_move_input(keys.key)
    }
    draw_board(&s)
    draw_info(&s)
  }
  free_all(context.temp_allocator)
  t.hide_cursor(false)
  t.set_term_mode(&s, .Restored)
  state.board.piece_map[PAWN_B] ~= (1 << 18)
  state.board.piece_map[PAWN_B] ~= (1 << 10)
  get_bishop_moves_and_captures(square=(1 << 25), colour=.WHITE)
  fmt.println(state.capture_options)
}

/*
Function for drawing debug information to the screen.
(TODO): Use for drawing game info to the screen like a timer and the current score, etc.
*/
draw_info :: proc(win: ^t.Screen) {
/*  x : uint = 2
  y : uint = 70
  
  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Go: %v", state.to_move))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Check: %v", state.check))
  y += 1
  
  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Hover file: %v", get_file(state.hovered_square)))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Hover rank: %v", get_rank(state.hovered_square)))
  y += 1

  t.move_cursor(win, y, x)
  //t.write(win, fmt.aprintf("Selected file: %v", state.selected_file))
  y += 1

  t.move_cursor(win, y, x)
//  t.write(win, fmt.aprintf("Selected rank: %v", state.selected_rank))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Move options: %v", state.move_options))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Capture options: %v", state.capture_options))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("File diff: %v", abs(cast(int)'d' - cast(int)'e')))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Mode: %v", state.mode))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Moves:"))
  y += 1

  t.move_cursor(win, y, x)
  t.write(win, fmt.aprintf("Test: %v", ~cast(u64)5))
  y += 1
 
  t.blit_screen(win)*/
}

/*
Function for handling user input for piece selection.
key: the key pressed by the user.

Handles a set of keys for navigating around the avaialble pieces and selecting a piece to move.
*/
handle_select_input :: proc(key: t.Key) {
  #partial switch key {
  case .W, .Arrow_Up:
    if state.to_move == .WHITE {
      increment_rank_selected()
    } else {
      decrement_rank_selected()
    }
  case .A, .Arrow_Left:
    decrement_file_selected()
  case .S, .Arrow_Down:
    if state.to_move == .WHITE {
      decrement_rank_selected()
    } else {
      increment_rank_selected()
    }
  case .D, .Arrow_Right:
    increment_file_selected()
  case .Enter:
    state.selected_square = state.hovered_square
    state.selected_piece = get_piece(state.selected_square)

    state.move_options = 0
    state.capture_options = 0

    index := square_to_index(state.selected_square)

    #partial switch state.selected_piece.piece {
    case .PAWN:
      get_pawn_moves_and_captures()
    case .KNIGHT:
      get_knight_moves_and_captures()
    case .BISHOP:
      get_bishop_moves_and_captures()
    case .ROOK:
      get_rook_moves_and_captures()
    case .QUEEN:
      get_queen_moves_and_captures()
    case .KING:
      get_king_moves_and_captures()
    }

    if state.move_options > 0 || state.capture_options > 0 {
      state.mode = .MOVE
    }
  }
}

/*
Function for handling user input for piece moves.
key: the key pressed by the user.

Handles a set of keys for navigating around the avaialble piece moves and captures and selecting one to make.

Checks if the move is valid, if it would result in check for either side, if it's a castle, or en-passeant for example.
*/
handle_move_input :: proc(key: t.Key) {
  #partial switch key {
  case .W, .Arrow_Up:
    if state.to_move == .WHITE {
      increment_rank_move()
    } else {
      decrement_rank_move()
    }
  case .A, .Arrow_Left:
    decrement_file_move()
  case .S, .Arrow_Down:
    if state.to_move == .WHITE {
      decrement_rank_move()
    } else {
      increment_rank_move()
    }
  case .D, .Arrow_Right:
    increment_file_move()
  case .Enter:
    saved_board := make(map[PieceInfo]u64)
    defer delete(saved_board)
    copy_board(&saved_board, state.board.piece_map)

    if state.selected_piece.piece == .PAWN {
      if get_file(state.hovered_square) != get_file(state.selected_square) {
        if get_empty_squares() & state.hovered_square != 0 {
          if state.to_move == .WHITE {
            state.board.piece_map[PAWN_B] ~= state.hovered_square << 8
          } else {
            state.board.piece_map[PAWN_W] ~= state.hovered_square >> 8
          }
        }
      }
    }

    if state.hovered_square != state.selected_square {
      state.board.piece_map[state.selected_piece] ~= state.selected_square
      state.board.piece_map[state.selected_piece] ~= state.hovered_square
 
      if state.to_move == .WHITE {
        state.board.piece_map[PAWN_B] ~= (state.board.piece_map[PAWN_B] & state.hovered_square)
        state.board.piece_map[KNIGHT_B] ~= (state.board.piece_map[KNIGHT_B] & state.hovered_square)
        state.board.piece_map[BISHOP_B] ~= (state.board.piece_map[BISHOP_B] & state.hovered_square)
        state.board.piece_map[ROOK_B] ~= (state.board.piece_map[ROOK_B] & state.hovered_square)
        state.board.piece_map[QUEEN_B] ~= (state.board.piece_map[QUEEN_B] & state.hovered_square)
        state.board.piece_map[KING_B] ~= (state.board.piece_map[KING_B] & state.hovered_square)
      } else {
        state.board.piece_map[PAWN_W] ~= (state.board.piece_map[PAWN_W] & state.hovered_square)
        state.board.piece_map[KNIGHT_W] ~= (state.board.piece_map[KNIGHT_W] & state.hovered_square)
        state.board.piece_map[BISHOP_W] ~= (state.board.piece_map[BISHOP_W] & state.hovered_square)
        state.board.piece_map[ROOK_W] ~= (state.board.piece_map[ROOK_W] & state.hovered_square)
        state.board.piece_map[QUEEN_W] ~= (state.board.piece_map[QUEEN_W] & state.hovered_square)
        state.board.piece_map[KING_W] ~= (state.board.piece_map[KING_W] & state.hovered_square)
      }

      //Checking if move results in current player being in check
      if is_check() {
        copy_board(&state.board.piece_map, saved_board)
        state.mode = .SELECT
        state.hovered_square = state.selected_square
        state.move_options = 0
        state.capture_options = 0
        state.selected_square = 0
        state.selected_piece = PieceInfo{}
        break
      } else {
        state.check = false
        state.move_options = 0
        state.capture_options = 0
      }

      //Moves that stop future castling
      if state.selected_piece == KING_W {
        state.can_castle_white_qs = false
        state.can_castle_white_ks = false
      } else if state.selected_piece == KING_B {
        state.can_castle_black_qs = false
        state.can_castle_black_ks = false
      }

      if state.selected_piece == ROOK_W {
        if state.selected_square == (1 << 56) {
          state.can_castle_white_qs = false
        } else if state.selected_square == (1 << 63) {
          state.can_castle_white_ks = false
        }
      } else if state.selected_piece == ROOK_B {
        if state.selected_square == (1) {
          state.can_castle_black_qs = false
        } else if state.selected_square == (1 << 7) {
          state.can_castle_black_ks = false
        }
      }

      //Castling
      if state.to_move == .WHITE {
        if state.selected_piece == KING_W && state.hovered_square == (1 << 58) {
          state.board.piece_map[ROOK_W] ~= (1 << 56)
          state.board.piece_map[ROOK_W] ~= (1 << 59)
        } else if state.selected_piece == KING_W && state.hovered_square == (1 << 62) {
          state.board.piece_map[ROOK_W] ~= (1 << 63)
          state.board.piece_map[ROOK_W] ~= (1 << 61)
        }
      } else {
        if state.selected_piece == KING_B && state.hovered_square == (1 << 2) {
          state.board.piece_map[ROOK_W] ~= (1)
          state.board.piece_map[ROOK_W] ~= (1 << 3)
        } else if state.selected_piece == KING_B && state.hovered_square == (1 << 6) {
          state.board.piece_map[ROOK_W] ~= (1 << 7)
          state.board.piece_map[ROOK_W] ~= (1 << 6)
        }
      }

      //Pawn promotion
      if state.to_move == .WHITE {
        if state.board.piece_map[PAWN_W] & ((1) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) | (1 << 6) | (1 << 7)) != 0 {
          handle_promotion_input()
        }
      } else {
        if state.board.piece_map[PAWN_B] & ((1 << 56) | (1 << 57) | (1 << 58) | (1 << 59) | (1 << 60) | (1 << 61) | (1 << 62) | (1 << 63)) != 0 {
          handle_promotion_input()
        }
      }

      if is_check(colour =.WHITE if state.to_move == .BLACK else .BLACK) {
        state.check = true
        if is_checkmate(colour =.WHITE if state.to_move == .BLACK else .BLACK) {
          state.running = false
        }
      } else {
        state.check = false
      }

      if state.to_move == .WHITE {
       state.to_move = .BLACK
      } else {
        state.to_move = .WHITE
        state.move_no += 1
      }
      temp_square := find_closest_piece(1, 8, 1, 8, state.to_move)
      if temp_square != 0 {
        state.hovered_square = temp_square
      }
    }
    state.mode = .SELECT
    state.last_move = Move{state.selected_piece.piece, get_file(state.selected_square), get_file(state.hovered_square), get_rank(state.selected_square), get_rank(state.hovered_square)}
    state.move_options = 0
    state.capture_options = 0
    state.selected_square = 0
    state.selected_piece = PieceInfo{}
  case .Tab:
  case .Escape:
    state.mode = .SELECT
    state.hovered_square = state.selected_square
    state.move_options = 0
    state.capture_options = 0
    state.selected_square = 0
    state.selected_piece = PieceInfo{}
  }
}

/*
Function for interrupting the main game loop to select which piece a pawn should promote into.
Returns to the main game loop once a piece has been selected.
*/
handle_promotion_input :: proc() {
  input, has_input := t.read(&s)
  keys := t.parse_keyboard_input(input)
  promotion_handled := false
  promotion_options_w := []PieceInfo{QUEEN_W, ROOK_W, BISHOP_W, KNIGHT_W}
  promotion_options_b := []PieceInfo{QUEEN_B, ROOK_B, BISHOP_B, KNIGHT_B}
  selected_piece_index := 0
  
  state.board.piece_map[PAWN_W if state.to_move == .WHITE else PAWN_B] ~= state.hovered_square
  state.board.piece_map[promotion_options_w[selected_piece_index] if state.to_move == .WHITE else promotion_options_b[selected_piece_index]] ~= state.hovered_square

  for !promotion_handled {
    defer t.blit_screen(&s)
    t.clear_screen(&s, .Everything)
    #partial switch keys.key {
    case .Tab:
      //Switch which piece to promote to
      selected_piece_index += 1
      if selected_piece_index == len(promotion_options_w) {
        selected_piece_index = 0
      }
      if state.to_move == .WHITE {
        if selected_piece_index > 0 {
          state.board.piece_map[promotion_options_w[selected_piece_index-1]] ~= state.hovered_square
        } else {
          state.board.piece_map[promotion_options_w[len(promotion_options_w)-1]] ~= state.hovered_square
        }
        state.board.piece_map[promotion_options_w[selected_piece_index]] ~= state.hovered_square
      } else {
        if selected_piece_index > 0 {
          state.board.piece_map[promotion_options_b[selected_piece_index-1]] ~= state.hovered_square
        } else {
          state.board.piece_map[promotion_options_b[len(promotion_options_w)-1]] ~= state.hovered_square
        }
        state.board.piece_map[promotion_options_b[selected_piece_index]] ~= state.hovered_square
      }
    case .Enter:
      promotion_handled = true
    }
    input, has_input = t.read(&s)
    keys = t.parse_keyboard_input(input)
    draw_board(&s)
  }
}

/*
Go to the next avaialable or closest piece in an higher file. (Move piece selection to the right)
*/
increment_file_selected :: proc() {
  original_square := state.hovered_square
  file := get_file(original_square)
  if get_file(state.hovered_square) != 8 {
    state.hovered_square <<= 1
    for !check_square_for_piece(state.hovered_square, state.to_move) {
      if get_file(state.hovered_square) == 8 {
        state.hovered_square = original_square
        temp_square := find_closest_piece(file+1, 8, 1, 8, state.to_move)
        if temp_square != 0 {
          state.hovered_square = temp_square
        }
        break
      }
      state.hovered_square <<= 1
    }
  }
}
/*
Go to the next avaialable or closest piece in an lower file. (Move piece selection to the left)
*/
decrement_file_selected :: proc() {
  original_square := state.hovered_square
  file := get_file(original_square)
  if get_file(state.hovered_square) != 1 {
    state.hovered_square >>= 1
    for !check_square_for_piece(state.hovered_square, state.to_move) {
      if get_file(state.hovered_square) == 1 {
        state.hovered_square = original_square
        temp_square := find_closest_piece(file-1, 1, 1, 8, state.to_move)
        if temp_square != 0 {
          state.hovered_square = temp_square
        }
        break
      }
      state.hovered_square >>= 1
    }
  } 
}

/*
Go to the next avaialable or closest piece in an higher rank. (Move piece selection up)
*/
increment_rank_selected :: proc() {
  original_square := state.hovered_square
  rank := get_rank(original_square)
  if get_rank(state.hovered_square) != 8 {
    state.hovered_square >>= 8
    for !check_square_for_piece(state.hovered_square, state.to_move) {
      if get_rank(state.hovered_square) == 8 {
        state.hovered_square = original_square
        temp_square := find_closest_piece(1, 8, rank+1, 8, state.to_move)
        if temp_square != 0 {
          state.hovered_square = temp_square
        }
        break
      }
      state.hovered_square >>= 8
    }
  }
}

/*
Go to the next avaialable or closest piece in an lower rank. (Move piece selection down)
*/
decrement_rank_selected :: proc() {
  original_square := state.hovered_square
  rank := get_rank(original_square)
  if get_rank(state.hovered_square) != 1 {
    state.hovered_square <<= 8
    for !check_square_for_piece(state.hovered_square, state.to_move) {
      if get_rank(state.hovered_square) == 1 {
        state.hovered_square = original_square
        temp_square := find_closest_piece(1, 8, rank-1, 1, state.to_move)
        if temp_square != 0 {
          state.hovered_square = temp_square
        }
        break
      }
      state.hovered_square <<= 8
    }
  } 
}

/*
Go to the next avaialable or closest move or capture in an higher file. (Move selection to the right)
*/
increment_file_move :: proc() {
  original_square := state.hovered_square
  file := get_file(original_square)
  if get_file(state.hovered_square) != 8 {
    state.hovered_square <<= 1
    for !check_valid_move_or_capture(state.hovered_square) {
      if get_file(state.hovered_square) == 8 {
        state.hovered_square = original_square
        temp_square := find_closest_move_or_capture(get_file(state.hovered_square)+1, 8, 1, 8)

        if temp_square != 0 {
          if check_valid_move_or_capture(temp_square) {
            state.hovered_square = temp_square
          }
        }
        break
      }
      state.hovered_square <<= 1
    }
  }
}

/*
Go to the next avaialable or closest move or capture in an lower file. (Move selection to the left)
*/
decrement_file_move :: proc() {
  original_square := state.hovered_square
  file := get_file(original_square)
  if get_file(state.hovered_square) != 1 {
    state.hovered_square >>= 1
    for !check_valid_move_or_capture(state.hovered_square) {
      if get_file(state.hovered_square) == 1 {
        state.hovered_square = original_square
        temp_square := find_closest_move_or_capture(get_file(state.hovered_square)-1, 1, 1, 8)

        if temp_square != 0 {
          if check_valid_move_or_capture(temp_square) {
            state.hovered_square = temp_square
          }
        }
        break
      }
      state.hovered_square >>= 1
    }
  }
}

/*
Go to the next avaialable or closest move or capture in an higher rank. (Move selection up)
*/
increment_rank_move :: proc() {
  original_square := state.hovered_square
  rank := get_rank(original_square)
  if get_rank(state.hovered_square) != 8 {
    state.hovered_square >>= 8
    for !check_valid_move_or_capture(state.hovered_square) {
      if get_rank(state.hovered_square) == 8 {
        state.hovered_square = original_square
        temp_square := find_closest_move_or_capture(1, 8, get_rank(state.hovered_square)+1, 8)

        if temp_square != 0 {
          if check_valid_move_or_capture(temp_square) {
            state.hovered_square = temp_square
          }
        }
        break
      }
      state.hovered_square >>= 8
    }
  }
}

/*
Go to the next avaialable or closest move or capture in an lower rank. (Move piece selection down)
*/
decrement_rank_move :: proc() {
  original_square := state.hovered_square
  rank := get_rank(original_square)
  if get_rank(state.hovered_square) != 1 {
    state.hovered_square <<= 8
    for !check_valid_move_or_capture(state.hovered_square) {
      if get_rank(state.hovered_square) == 1 {
        state.hovered_square = original_square
        temp_square := find_closest_move_or_capture(1, 8, get_rank(state.hovered_square)-1, 1)

        if temp_square != 0 {
          if check_valid_move_or_capture(temp_square) {
            state.hovered_square = temp_square
          }
        }
        break
      }
      state.hovered_square <<= 8
    }
  }
}
