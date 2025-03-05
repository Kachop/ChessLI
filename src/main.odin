package main

import "core:fmt"
import "core:os/os2"
import "core:strings"
import "core:encoding/ansi"
import "core:unicode/utf8"

import nc "shared:ncurses/src"
import "core:c"

Mode :: enum {
  SELECT,
  MOVE,
}

GameState :: struct {
  running: bool,
  move_no: u8,
  to_move: Colour,
  mode: Mode,
  board: Board,
  hovered_file: rune,
  hovered_rank: c.int,
  selected_file: rune,
  selected_rank: c.int,
  move_option_files: [dynamic]rune,
  move_option_ranks: [dynamic]c.int,
  capture_option_files: [dynamic]rune,
  capture_option_ranks: [dynamic]c.int,
}

state := GameState{}

BOARD_WIDTH  :: 130
BOARD_HEIGHT :: 64

main :: proc() {
  state.running = true
  state.move_no = 1
  state.to_move = .WHITE
  state.mode = .SELECT
  state.board = getDefaultBoard()
  state.hovered_file = 'a'
  state.move_option_files = [dynamic]rune{}
  state.move_option_ranks = [dynamic]c.int{}

  nc.initscr()
  nc.cbreak()
  nc.noecho()
  nc.use_default_colors()
  colour_support := nc.has_colors()
  if colour_support {
    nc.start_color()
    nc.init_pair(1, nc.COLOR_WHITE, nc.COLOR_WHITE)
    nc.init_pair(2, nc.COLOR_BLACK, nc.COLOR_BLACK)
    nc.init_pair(3, nc.COLOR_BLACK, nc.COLOR_CYAN)
    nc.init_pair(4, nc.COLOR_BLACK, nc.COLOR_BLUE)
    nc.init_pair(5, nc.COLOR_RED, nc.COLOR_RED)
    nc.init_pair(6, nc.COLOR_GREEN, nc.COLOR_GREEN)
  }
    
  WHITE_BACKGROUND_COLOUR := nc.COLOR_PAIR(1)
  BROWN := nc.COLOR_PAIR(2)

  nc.curs_set(0)
  nc.refresh()

  board_window := nc.newwin(BOARD_HEIGHT, BOARD_WIDTH, 1, 2)
  info_window := nc.newwin(40, 120, 66, 2)

  nc.keypad(board_window, true)
  nc.keypad(info_window, true)
  nc.refresh()
  draw_board(board_window)
  draw_info(info_window)

  for state.running {
    ch := nc.wgetch(board_window)
    if state.mode == .SELECT {
      handle_select_input(ch)
    } else if state.mode == .MOVE {
      //Cycle through the available moves and move the piece
      handle_move_input(ch)
    }

    draw_board(board_window)
    draw_info(info_window)
    nc.refresh()
  }
    
  nc.endwin()
  fmt.println("Closing program")
}

draw_info :: proc(win: ^nc.Window) {
  x : c.int = 2
  y : c.int = 1
  nc.box(win, 0, 0)

  nc.mvwaddstr(win, y, x, fmt.ctprintf("Hover file: %v", state.hovered_file))
  y += 1
  nc.mvwaddstr(win, y, x, fmt.ctprintf("Hover rank: %v", state.hovered_rank))
  y += 1
  nc.mvwaddstr(win, y, x, fmt.ctprintf("Mode: %v", state.mode))
  y += 1
  nc.mvwaddstr(win, y, x, fmt.ctprintf("Available moves: %v", len(state.move_option_files)))
  y += 1

  //ch := nc.wgetch(win)

  //nc.mvwaddstr(win, y, x, fmt.ctprintf("Last key pressed: %3d", ch))
  //y += 1
  
  nc.mvwaddstr(win, y, x, fmt.ctprintf("Moves:"))
  y += 1

  for i in 0 ..< len(state.move_option_files) {
    nc.mvwaddstr(win, y, x, fmt.ctprintf("%v%v", state.move_option_files[i], state.move_option_ranks[i]+1))
    y += 1
  }
  //nc.waddstr(win, "Test")
  nc.wrefresh(win)
}

handle_select_input :: proc(ch: i32) {
  switch ch {
  case 'w', nc.KEY_UP:
    if state.hovered_rank == 7 {
      state.hovered_rank = 0
      for !check_square_for_piece(state.hovered_file, state.hovered_rank, state.to_move) {
        state.hovered_rank += 1
        if state.hovered_rank == 7 {
          break
        }
      }
    } else {
      state.hovered_rank += 1
      for !check_square_for_piece(state.hovered_file, state.hovered_rank, state.to_move) {
        if state.hovered_rank == 7 {
          state.hovered_rank = 0
        } else {
          state.hovered_rank += 1
        }
      }
    }
  case 'a', nc.KEY_LEFT:
    if state.hovered_file == 'a' {
      state.hovered_file = 'h'
      for !check_square_for_piece(state.hovered_file, state.hovered_rank, state.to_move) {
        if state.to_move == .WHITE {
          state.hovered_file -= 1
        } else {
          state.hovered_file += 1
        }
        if state.hovered_file == 'a' {
          break
        }
      }
    } else {
      if state.to_move == .WHITE {
        state.hovered_file -= 1
      } else {
        state.hovered_file += 1
      }
      for !check_square_for_piece(state.hovered_file, state.hovered_rank, state.to_move) {
        if state.hovered_file == 'a' {
          state.hovered_file = 'h'
        } else {
          if state.to_move == .WHITE {
            state.hovered_file -= 1
          } else {
            state.hovered_file += 1
          }
        }
      }
    }
  case 's', nc.KEY_DOWN:
    if state.hovered_rank == 0 {
      state.hovered_rank = 7
      for !check_square_for_piece(state.hovered_file, state.hovered_rank, state.to_move) {
        state.hovered_rank -= 1
        if state.hovered_rank == 0 {
          break
        }
      }
    } else {
      state.hovered_rank -= 1
      for !check_square_for_piece(state.hovered_file, state.hovered_rank, state.to_move) {
        if state.hovered_rank == 0 {
          state.hovered_rank = 7
        } else {
          state.hovered_rank -= 1
        }
      }
    }
  case 'd', nc.KEY_RIGHT:
    if state.hovered_file == 'h' {
      state.hovered_file = 'a'
      for !check_square_for_piece(state.hovered_file, state.hovered_rank, state.to_move) {
        if state.to_move == .WHITE {
          state.hovered_file += 1
        } else {
          state.hovered_file -= 1
        }
        if state.hovered_file == 'h' {
          break
        }
      }
    } else {
      if state.to_move == .WHITE {
        state.hovered_file += 1
      } else {
        state.hovered_file -= 1
      }
      for !check_square_for_piece(state.hovered_file, state.hovered_rank, state.to_move) {
        if state.hovered_file == 'h' {
          state.hovered_file = 'a'
        } else {
          if state.to_move == .WHITE {
            state.hovered_file += 1
          } else {
            state.hovered_file -= 1
          }
        }
      }
    }
  case 10:
    state.selected_file = state.hovered_file
    state.selected_rank = state.hovered_rank
    clear(&state.move_option_files)
    clear(&state.move_option_ranks)
    switch state.board.piece_map[state.selected_file][state.selected_rank].piece {
    case .PAWN:
      get_pawn_moves()
    case .KNIGHT:
    case .BISHOP:
    case .ROOK:
    case .QUEEN:
    case .KING:
    case .NONE:
    }
    if len(state.move_option_files) > 0 || len(state.capture_option_files) > 0 {
      state.mode = .MOVE
    }
  case:
    nc.refresh()
  }
}

handle_move_input :: proc(ch: i32) {
  switch ch {
  case 'w', nc.KEY_UP:
    if state.hovered_rank == 7 {
      state.hovered_rank = 0
      for !check_valid_move_or_capture(state.hovered_file, state.hovered_rank) {
        state.hovered_rank += 1
        if state.hovered_rank == 7 {
          break
        }
      }
    } else {
      state.hovered_rank += 1
      for !check_valid_move_or_capture(state.hovered_file, state.hovered_rank) {
        if state.hovered_rank == 7 {
          state.hovered_rank = 0
        } else {
          state.hovered_rank += 1
        }
      }
    }
  case 'a', nc.KEY_LEFT:
  case 's', nc.KEY_DOWN:
  case 'd', nc.KEY_RIGHT:
    if state.hovered_rank == 0 {
      state.hovered_rank = 7
      for !check_valid_move_or_capture(state.hovered_file, state.hovered_rank) {
        state.hovered_rank -= 1
        if state.hovered_rank == 0 {
          break
        }
      }
    } else {
      state.hovered_rank -= 1
      for !check_valid_move_or_capture(state.hovered_file, state.hovered_rank) {
        if state.hovered_rank == 0 {
          state.hovered_rank = 7
        } else {
          state.hovered_rank -= 1
        }
      }
    }
  case 10://Enter
    if check_valid_move_or_capture(state.hovered_file, state.hovered_rank) {
      state.board.piece_map[state.hovered_file][state.hovered_rank] = state.board.piece_map[state.selected_file][state.selected_rank]
      state.board.piece_map[state.selected_file][state.selected_rank] = PieceInfo{}
      state.mode = .SELECT
      if state.to_move == .WHITE {
        state.to_move = .BLACK
      } else {
        state.to_move = .WHITE
        state.move_no += 1
      }
    }
  case 9://TAB
  case 27://ESC
    state.mode = .SELECT
  }
}
