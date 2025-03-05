package main

import "core:fmt"
import "core:os/os2"
import "core:strings"
import "core:encoding/ansi"
import "core:unicode/utf8"

import nc "shared:ncurses/src"
import "core:c"

Mode :: enum {
  HOVER,
  SELECT,
}

GameState :: struct {
    running: bool,
    move_no: u8,
    to_move: Colour,
    board: Board,
    hovered_file: rune,
    hovered_rank: c.int,
    selected_file: rune,
    selected_rank: c.int,
}

BOARD_WIDTH  :: 130
BOARD_HEIGHT :: 64

main :: proc() {
    state := GameState{
        running = true,
        move_no = 1,
        to_move = .WHITE,
        board = getDefaultBoard(),
        hovered_file = 'a'
    }

    nc.initscr()
    nc.cbreak()
    nc.noecho()
    nc.use_default_colors()
    colour_support := nc.has_colors()
    if colour_support {
        nc.start_color()
        nc.init_pair(1, nc.COLOR_RED, nc.COLOR_BLUE)
        nc.init_pair(2, nc.COLOR_BLUE, nc.COLOR_GREEN)
    }
    
    PURPLE := nc.COLOR_PAIR(1)
    BROWN := nc.COLOR_PAIR(2)

    nc.curs_set(0)
    nc.refresh()

    board_window := nc.newwin(BOARD_HEIGHT, BOARD_WIDTH, 1, 2)

    nc.keypad(board_window, true)
    nc.refresh()
    draw_board(board_window, state)
    
    for {
        ch := nc.wgetch(board_window)
        switch ch {
        case 'w', nc.KEY_UP:
            if state.hovered_rank == 0 {
                state.hovered_rank = 7
            } else {
                state.hovered_rank -= 1
            }
        case 'a', nc.KEY_LEFT:
            if state.hovered_file == 'a' {
                state.hovered_file = 'h'
            } else {
                state.hovered_file -= 1
            }
        case 's', nc.KEY_DOWN:
            if state.hovered_rank == 7 {
                state.hovered_rank = 0
            } else {
                state.hovered_rank += 1
            }
        case 'd', nc.KEY_RIGHT:
            if state.hovered_file == 'h' {
                state.hovered_file = 'a'
            } else {
                state.hovered_file += 1
            }
        case 10:
            state.selected_file = state.hovered_file
            state.selected_rank = state.hovered_rank
        case:
            nc.refresh()
        }
        
        draw_board(board_window, state)
    }
    
    nc.endwin()
    fmt.println("Closing program")
}
