package main

import "core:fmt"
import "core:strconv"
import "core:unicode/utf8"
import "core:c"

/*
File for all of the game logic.
-Moving pieces
-Captures
-Check / checkmate
*/

files_str_set :: bit_set['a'..='h']
ranks_str_set :: bit_set['1'..='8']
ranks_num_set :: bit_set[1..=8]

files_str :: files_str_set{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'}
ranks_str :: ranks_str_set{'1', '2', '3', '4', '5', '6', '7', '8'}
ranks_num :: ranks_num_set{1, 2, 3, 4, 5, 6, 7, 8}

get_pawn_moves_and_captures :: proc() {
  if state.to_move == .WHITE {
    if state.selected_rank != 7 && state.selected_rank != 0 {
      if !check_square_for_piece(state.selected_file, state.selected_rank+1, .BLACK) && !check_square_for_piece(state.selected_file, state.selected_rank+1, .WHITE) {
        append(&state.move_option_files, state.selected_file)
        append(&state.move_option_ranks, state.selected_rank+1)
      }
      if state.selected_rank == 1 {
        //If pawn has not yet moved
        if !check_square_for_piece(state.selected_file, state.selected_rank+2, .BLACK) && !check_square_for_piece(state.selected_file, state.selected_rank+2, .WHITE) {
          append(&state.move_option_files, state.selected_file)
          append(&state.move_option_ranks, state.selected_rank+2)
        }
      }
    }
    if check_square_for_piece(state.selected_file-1, state.selected_rank+1, .BLACK) {
      append(&state.capture_option_files, state.selected_file-1)
      append(&state.capture_option_ranks, state.selected_rank+1)
    }
    if check_square_for_piece(state.selected_file+1, state.selected_rank+1, .BLACK) {
      append(&state.capture_option_files, state.selected_file+1)
      append(&state.capture_option_ranks, state.selected_rank+1)
    }
  } else {
    if state.selected_rank != 7 && state.selected_rank != 0 {
      if !check_square_for_piece(state.selected_file, state.selected_rank-1, .BLACK) && !check_square_for_piece(state.selected_file, state.selected_rank-1, .WHITE) {
        append(&state.move_option_files, state.selected_file)
        append(&state.move_option_ranks, state.selected_rank-1)
      }
      if state.selected_rank == 6 {
        //If pawn has not yet moved
        if !check_square_for_piece(state.selected_file, state.selected_rank-2, .BLACK) && !check_square_for_piece(state.selected_file, state.selected_rank-2, .WHITE) {
          append(&state.move_option_files, state.selected_file)
          append(&state.move_option_ranks, state.selected_rank-2)
        }
      }
    }
    if check_square_for_piece(state.selected_file-1, state.selected_rank-1, .WHITE) {
      append(&state.capture_option_files, state.selected_file-1)
      append(&state.capture_option_ranks, state.selected_rank-1)
    }
    if check_square_for_piece(state.selected_file+1, state.selected_rank-1, .WHITE) {
      append(&state.capture_option_files, state.selected_file+1)
      append(&state.capture_option_ranks, state.selected_rank-1)
    }
  }
}

get_knight_moves_and_captures :: proc() {
  if state.to_move == .WHITE {
    if state.selected_file == 'a' {
      if state.selected_rank == 0 {
        if !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .BLACK) {
          append(&state.move_option_files, state.selected_file+1)
          append(&state.move_option_ranks, state.selected_rank+2)
        } else if check_square_for_piece(state.selected_file+1, state.selected_rank+2, .BLACK) {
          append(&state.capture_option_files, state.selected_file+1)
          append(&state.capture_option_ranks, state.selected_rank+2)
        }
      } else if state.selected_rank == 7 {
        if !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .BLACK) {
          append(&state.move_option_files, state.selected_file+1)
          append(&state.move_option_ranks, state.selected_rank-2)
        } else if check_square_for_piece(state.selected_file+1, state.selected_rank-2, .BLACK) {
          append(&state.capture_option_files, state.selected_file+1)
          append(&state.capture_option_ranks, state.selected_rank-2)
        }
      } else {
        if state.selected_rank + 2 <= 7 {
          if !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .BLACK) {
            append(&state.move_option_files, state.selected_file+1)
            append(&state.move_option_ranks, state.selected_rank+2)
          } else if check_square_for_piece(state.selected_file+1, state.selected_rank+2, .BLACK) {
            append(&state.capture_option_files, state.selected_file+1)
            append(&state.capture_option_ranks, state.selected_rank+2)
          }
        }
        if !check_square_for_piece(state.selected_file+2, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file+2, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file+2)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file+2, state.selected_rank+1, .BLACK) {
          append(&state.capture_option_files, state.selected_file+2)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
        if state.selected_rank - 2 >= 0 {
          if !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .BLACK) {
            append(&state.move_option_files, state.selected_file+1)
            append(&state.move_option_ranks, state.selected_rank-2)
          } else if check_square_for_piece(state.selected_file+1, state.selected_rank-2, .BLACK) {
            append(&state.capture_option_files, state.selected_file+1)
            append(&state.capture_option_ranks, state.selected_rank-2)
          }
        }
        if !check_square_for_piece(state.selected_file+2, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file+2, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file+2)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file+2, state.selected_rank-1, .BLACK) {
          append(&state.capture_option_files, state.selected_file+2)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
      }
    } else if state.selected_file == 'h' {
      if state.selected_rank == 0 {
        if !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .BLACK) {
          append(&state.move_option_files, state.selected_file-1)
          append(&state.move_option_ranks, state.selected_rank+2)
        } else if check_square_for_piece(state.selected_file-1, state.selected_rank+2, .BLACK) {
          append(&state.capture_option_files, state.selected_file-1)
          append(&state.capture_option_ranks, state.selected_rank+2)
        }

      } else if state.selected_rank == 7 {
        if !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .BLACK) {
          append(&state.move_option_files, state.selected_file-1)
          append(&state.move_option_ranks, state.selected_rank-2)
        } else if check_square_for_piece(state.selected_file-1, state.selected_rank-2, .BLACK) {
          append(&state.capture_option_files, state.selected_file-1)
          append(&state.capture_option_ranks, state.selected_rank-2)
        }
      } else {
        if state.selected_rank + 2 <= 7 {
          if !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .BLACK) {
            append(&state.move_option_files, state.selected_file-1)
            append(&state.move_option_ranks, state.selected_rank+2)
          } else if check_square_for_piece(state.selected_file-1, state.selected_rank+2, .BLACK) {
            append(&state.capture_option_files, state.selected_file-1)
            append(&state.capture_option_ranks, state.selected_rank+2)
          }
        }
        if !check_square_for_piece(state.selected_file-2, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file-2, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file-2)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file-2, state.selected_rank+1, .BLACK) {
          append(&state.capture_option_files, state.selected_file-2)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
        if state.selected_rank - 2 >= 0 {
          if !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .BLACK) {
            append(&state.move_option_files, state.selected_file-1)
            append(&state.move_option_ranks, state.selected_rank-2)
          } else if check_square_for_piece(state.selected_file-1, state.selected_rank-2, .BLACK) {
            append(&state.capture_option_files, state.selected_file-1)
            append(&state.capture_option_ranks, state.selected_rank-2)
          }
        }
        if !check_square_for_piece(state.selected_file-2, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file-2, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file-2)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file-2, state.selected_rank-1, .BLACK) {
          append(&state.capture_option_files, state.selected_file-2)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
      }
    } else if state.selected_rank == 0 {
      if state.selected_file - 2 >= 'a' {
        if !check_square_for_piece(state.selected_file-2, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file-2, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file-2)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file-2, state.selected_rank+1, .BLACK) {
          append(&state.capture_option_files, state.selected_file-2)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
      }
      if !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .BLACK) {
        append(&state.move_option_files, state.selected_file-1)
        append(&state.move_option_ranks, state.selected_rank+2)
      } else if check_square_for_piece(state.selected_file-1, state.selected_rank+2, .BLACK) {
        append(&state.capture_option_files, state.selected_file-1)
        append(&state.capture_option_ranks, state.selected_rank+2)
      }
      if state.selected_file + 2 <= 'h' {
        if !check_square_for_piece(state.selected_file+2, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file+2, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file+2)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file+2, state.selected_rank+1, .BLACK) {
          append(&state.capture_option_files, state.selected_file+2)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
      }
      if !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .BLACK) {
        append(&state.move_option_files, state.selected_file+1)
        append(&state.move_option_ranks, state.selected_rank+2)
      } else if check_square_for_piece(state.selected_file+1, state.selected_rank+2, .BLACK) {
        append(&state.capture_option_files, state.selected_file+1)
        append(&state.capture_option_ranks, state.selected_rank+2)
      }
    } else if state.selected_rank == 7 {
      if state.selected_file - 2 >= 'a' {
        if !check_square_for_piece(state.selected_file-2, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file-2, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file-2)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file-2, state.selected_rank-1, .BLACK) {
          append(&state.capture_option_files, state.selected_file-2)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
      }
      if !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .BLACK) {
        append(&state.move_option_files, state.selected_file-1)
        append(&state.move_option_ranks, state.selected_rank-2)
      } else if check_square_for_piece(state.selected_file-1, state.selected_rank-2, .BLACK) {
        append(&state.capture_option_files, state.selected_file-1)
        append(&state.capture_option_ranks, state.selected_rank-2)
      }
      if state.selected_file + 2 <= 'h' {
        if !check_square_for_piece(state.selected_file+2, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file+2, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file+2)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file+2, state.selected_rank-1, .BLACK) {
          append(&state.capture_option_files, state.selected_file+2)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
      }
      if !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .BLACK) {
        append(&state.move_option_files, state.selected_file+1)
        append(&state.move_option_ranks, state.selected_rank-2)
      } else if check_square_for_piece(state.selected_file+1, state.selected_rank-2, .BLACK) {
        append(&state.capture_option_files, state.selected_file+1)
        append(&state.capture_option_ranks, state.selected_rank-2)
      }
    } else {
      //Not in a, h, 0 or 7
      if state.selected_file - 2 >= 'a' {
        if !check_square_for_piece(state.selected_file-2, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file-2, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file-2)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file-2, state.selected_rank-1, .BLACK) {
          append(&state.capture_option_files, state.selected_file-2)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
        if !check_square_for_piece(state.selected_file-2, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file-2, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file-2)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file-2, state.selected_rank+1, .BLACK) {
          append(&state.capture_option_files, state.selected_file-2)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
      }
      if state.selected_file + 2 <= 'h' {
        if !check_square_for_piece(state.selected_file+2, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file+2, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file+2)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file+2, state.selected_rank-1, .BLACK) {
          append(&state.capture_option_files, state.selected_file+2)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
        if !check_square_for_piece(state.selected_file+2, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file+2, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file+2)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file+2, state.selected_rank+1, .BLACK) {
          append(&state.capture_option_files, state.selected_file+2)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
      }
      if state.selected_rank - 2 >= 0 {
        if !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .BLACK) {
          append(&state.move_option_files, state.selected_file+1)
          append(&state.move_option_ranks, state.selected_rank-2)
        } else if check_square_for_piece(state.selected_file+1, state.selected_rank-2, .BLACK) {
          append(&state.capture_option_files, state.selected_file+1)
          append(&state.capture_option_ranks, state.selected_rank-2)
        }
        if !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .BLACK) {
          append(&state.move_option_files, state.selected_file-1)
          append(&state.move_option_ranks, state.selected_rank-2)
        } else if check_square_for_piece(state.selected_file-1, state.selected_rank-2, .BLACK) {
          append(&state.capture_option_files, state.selected_file-1)
          append(&state.capture_option_ranks, state.selected_rank-2)
        }
      }
      if state.selected_rank + 2 <= 7 {
        if !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .BLACK) {
          append(&state.move_option_files, state.selected_file+1)
          append(&state.move_option_ranks, state.selected_rank+2)
        } else if check_square_for_piece(state.selected_file+1, state.selected_rank+2, .BLACK) {
          append(&state.capture_option_files, state.selected_file+1)
          append(&state.capture_option_ranks, state.selected_rank+2)
        }
        if !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .BLACK) {
          append(&state.move_option_files, state.selected_file-1)
          append(&state.move_option_ranks, state.selected_rank+2)
        } else if check_square_for_piece(state.selected_file-1, state.selected_rank+2, .BLACK) {
          append(&state.capture_option_files, state.selected_file-1)
          append(&state.capture_option_ranks, state.selected_rank+2)
        }
      }
    }
  } else {
    if state.selected_file == 'a' {
      if state.selected_rank == 0 {
        if !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .BLACK) {
          append(&state.move_option_files, state.selected_file+1)
          append(&state.move_option_ranks, state.selected_rank+2)
        } else if check_square_for_piece(state.selected_file+1, state.selected_rank+2, .WHITE) {
          append(&state.capture_option_files, state.selected_file+1)
          append(&state.capture_option_ranks, state.selected_rank+2)
        }
      } else if state.selected_rank == 7 {
        if !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .BLACK) {
          append(&state.move_option_files, state.selected_file+1)
          append(&state.move_option_ranks, state.selected_rank-2)
        } else if check_square_for_piece(state.selected_file+1, state.selected_rank-2, .WHITE) {
          append(&state.capture_option_files, state.selected_file+1)
          append(&state.capture_option_ranks, state.selected_rank-2)
        }
      } else {
        if state.selected_rank + 2 <= 7 {
          if !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .BLACK) {
            append(&state.move_option_files, state.selected_file+1)
            append(&state.move_option_ranks, state.selected_rank+2)
          } else if check_square_for_piece(state.selected_file+1, state.selected_rank+2, .WHITE) {
            append(&state.capture_option_files, state.selected_file+1)
            append(&state.capture_option_ranks, state.selected_rank+2)
          }
        }
        if !check_square_for_piece(state.selected_file+2, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file+2, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file+2)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file+2, state.selected_rank+1, .WHITE) {
          append(&state.capture_option_files, state.selected_file+2)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
        if state.selected_rank - 2 >= 0 {
          if !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .BLACK) {
            append(&state.move_option_files, state.selected_file+1)
            append(&state.move_option_ranks, state.selected_rank-2)
          } else if check_square_for_piece(state.selected_file+1, state.selected_rank-2, .WHITE) {
            append(&state.capture_option_files, state.selected_file+1)
            append(&state.capture_option_ranks, state.selected_rank-2)
          }
        }
        if !check_square_for_piece(state.selected_file+2, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file+2, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file+2)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file+2, state.selected_rank-1, .WHITE) {
          append(&state.capture_option_files, state.selected_file+2)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
      }
    } else if state.selected_file == 'h' {
      if state.selected_rank == 0 {
        if !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .BLACK) {
          append(&state.move_option_files, state.selected_file-1)
          append(&state.move_option_ranks, state.selected_rank+2)
        } else if check_square_for_piece(state.selected_file-1, state.selected_rank+2, .WHITE) {
          append(&state.capture_option_files, state.selected_file-1)
          append(&state.capture_option_ranks, state.selected_rank+2)
        }

      } else if state.selected_rank == 7 {
        if !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .BLACK) {
          append(&state.move_option_files, state.selected_file-1)
          append(&state.move_option_ranks, state.selected_rank-2)
        } else if check_square_for_piece(state.selected_file-1, state.selected_rank-2, .WHITE) {
          append(&state.capture_option_files, state.selected_file-1)
          append(&state.capture_option_ranks, state.selected_rank-2)
        }
      } else {
        if state.selected_rank + 2 <= 7 {
          if !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .BLACK) {
            append(&state.move_option_files, state.selected_file-1)
            append(&state.move_option_ranks, state.selected_rank+2)
          } else if check_square_for_piece(state.selected_file-1, state.selected_rank+2, .WHITE) {
            append(&state.capture_option_files, state.selected_file-1)
            append(&state.capture_option_ranks, state.selected_rank+2)
          }
        }
        if !check_square_for_piece(state.selected_file-2, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file-2, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file-2)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file-2, state.selected_rank+1, .WHITE) {
          append(&state.capture_option_files, state.selected_file-2)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
        if state.selected_rank - 2 >= 0 {
          if !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .BLACK) {
            append(&state.move_option_files, state.selected_file-1)
            append(&state.move_option_ranks, state.selected_rank-2)
          } else if check_square_for_piece(state.selected_file-1, state.selected_rank-2, .WHITE) {
            append(&state.capture_option_files, state.selected_file-1)
            append(&state.capture_option_ranks, state.selected_rank-2)
          }
        }
        if !check_square_for_piece(state.selected_file-2, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file-2, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file-2)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file-2, state.selected_rank-1, .WHITE) {
          append(&state.capture_option_files, state.selected_file-2)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
      }
    } else if state.selected_rank == 0 {
      if state.selected_file - 2 >= 'a' {
        if !check_square_for_piece(state.selected_file-2, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file-2, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file-2)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file-2, state.selected_rank+1, .WHITE) {
          append(&state.capture_option_files, state.selected_file-2)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
      }
      if !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .BLACK) {
        append(&state.move_option_files, state.selected_file-1)
        append(&state.move_option_ranks, state.selected_rank+2)
      } else if check_square_for_piece(state.selected_file-1, state.selected_rank+2, .WHITE) {
        append(&state.capture_option_files, state.selected_file-1)
        append(&state.capture_option_ranks, state.selected_rank+2)
      }
      if state.selected_file + 2 <= 'h' {
        if !check_square_for_piece(state.selected_file+2, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file+2, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file+2)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file+2, state.selected_rank+1, .WHITE) {
          append(&state.capture_option_files, state.selected_file+2)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
      }
      if !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .BLACK) {
        append(&state.move_option_files, state.selected_file+1)
        append(&state.move_option_ranks, state.selected_rank+2)
      } else if check_square_for_piece(state.selected_file+1, state.selected_rank+2, .WHITE) {
        append(&state.capture_option_files, state.selected_file+1)
        append(&state.capture_option_ranks, state.selected_rank+2)
      }
    } else if state.selected_rank == 7 {
      if state.selected_file - 2 >= 'a' {
        if !check_square_for_piece(state.selected_file-2, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file-2, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file-2)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file-2, state.selected_rank-1, .WHITE) {
          append(&state.capture_option_files, state.selected_file-2)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
      }
      if !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .BLACK) {
        append(&state.move_option_files, state.selected_file-1)
        append(&state.move_option_ranks, state.selected_rank-2)
      } else if check_square_for_piece(state.selected_file-1, state.selected_rank-2, .WHITE) {
        append(&state.capture_option_files, state.selected_file-1)
        append(&state.capture_option_ranks, state.selected_rank-2)
      }
      if state.selected_file + 2 <= 'h' {
        if !check_square_for_piece(state.selected_file+2, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file+2, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file+2)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file+2, state.selected_rank-1, .WHITE) {
          append(&state.capture_option_files, state.selected_file+2)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
      }
      if !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .BLACK) {
        append(&state.move_option_files, state.selected_file+1)
        append(&state.move_option_ranks, state.selected_rank-2)
      } else if check_square_for_piece(state.selected_file+1, state.selected_rank-2, .WHITE) {
        append(&state.capture_option_files, state.selected_file+1)
        append(&state.capture_option_ranks, state.selected_rank-2)
      }
    } else {
      //Not in a, h, 0 or 7
      if state.selected_file - 2 >= 'a' {
        if !check_square_for_piece(state.selected_file-2, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file-2, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file-2)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file-2, state.selected_rank-1, .WHITE) {
          append(&state.capture_option_files, state.selected_file-2)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
        if !check_square_for_piece(state.selected_file-2, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file-2, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file-2)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file-2, state.selected_rank+1, .WHITE) {
          append(&state.capture_option_files, state.selected_file-2)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
      }
      if state.selected_file + 2 <= 'h' {
        if !check_square_for_piece(state.selected_file+2, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file+2, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file+2)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file+2, state.selected_rank-1, .WHITE) {
          append(&state.capture_option_files, state.selected_file+2)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
        if !check_square_for_piece(state.selected_file+2, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file+2, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file+2)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file+2, state.selected_rank+1, .WHITE) {
          append(&state.capture_option_files, state.selected_file+2)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
      }
      if state.selected_rank - 2 >= 0 {
        if !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank-2, .BLACK) {
          append(&state.move_option_files, state.selected_file+1)
          append(&state.move_option_ranks, state.selected_rank-2)
        } else if check_square_for_piece(state.selected_file+1, state.selected_rank-2, .WHITE) {
          append(&state.capture_option_files, state.selected_file+1)
          append(&state.capture_option_ranks, state.selected_rank-2)
        }
        if !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank-2, .BLACK) {
          append(&state.move_option_files, state.selected_file-1)
          append(&state.move_option_ranks, state.selected_rank-2)
        } else if check_square_for_piece(state.selected_file-1, state.selected_rank-2, .WHITE) {
          append(&state.capture_option_files, state.selected_file-1)
          append(&state.capture_option_ranks, state.selected_rank-2)
        }
      }
      if state.selected_rank + 2 <= 7 {
        if !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank+2, .BLACK) {
          append(&state.move_option_files, state.selected_file+1)
          append(&state.move_option_ranks, state.selected_rank+2)
        } else if check_square_for_piece(state.selected_file+1, state.selected_rank+2, .WHITE) {
          append(&state.capture_option_files, state.selected_file+1)
          append(&state.capture_option_ranks, state.selected_rank+2)
        }
        if !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank+2, .BLACK) {
          append(&state.move_option_files, state.selected_file-1)
          append(&state.move_option_ranks, state.selected_rank+2)
        } else if check_square_for_piece(state.selected_file-1, state.selected_rank+2, .WHITE) {
          append(&state.capture_option_files, state.selected_file-1)
          append(&state.capture_option_ranks, state.selected_rank+2)
        }
      }
    }
  }
}

get_bishop_moves_and_captures :: proc() {
  moves_found: bool
  increment : c.int = 1
  if state.to_move == .WHITE {
    //Up-right diagonals
    if state.selected_file < 'h' && state.selected_rank < 7 {
      for !moves_found {
        if !check_square_for_piece(state.selected_file+cast(rune)increment, state.selected_rank+increment, .BLACK) {
          if !check_square_for_piece(state.selected_file+cast(rune)increment, state.selected_rank+increment, .WHITE) {
            append(&state.move_option_files, state.selected_file+cast(rune)increment)
            append(&state.move_option_ranks, state.selected_rank+increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, state.selected_file+cast(rune)increment)
          append(&state.capture_option_ranks, state.selected_rank+increment)
          moves_found = true
        }
        if state.selected_file + cast(rune)increment > 'h' {
          moves_found = true
        }
        if state.selected_rank + increment > 7 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Down-right diagonals
    if state.selected_file < 'h' && state.selected_rank > 0 {
      for !moves_found {
        if !check_square_for_piece(state.selected_file+cast(rune)increment, state.selected_rank-increment, .BLACK) {
          if !check_square_for_piece(state.selected_file+cast(rune)increment, state.selected_rank-increment, .WHITE) {
            append(&state.move_option_files, state.selected_file+cast(rune)increment)
            append(&state.move_option_ranks, state.selected_rank-increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, state.selected_file+cast(rune)increment)
          append(&state.capture_option_ranks, state.selected_rank-increment)
          moves_found = true
        }
        if state.selected_file + cast(rune)increment > 'h' {
          moves_found = true
        }
        if state.selected_rank - increment < 0 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Down-left diagonals
    if state.selected_file < 'a' && state.selected_rank > 0 {
      for !moves_found {
        if !check_square_for_piece(state.selected_file-cast(rune)increment, state.selected_rank-increment, .BLACK) {
          if !check_square_for_piece(state.selected_file-cast(rune)increment, state.selected_rank-increment, .WHITE) {
            append(&state.move_option_files, state.selected_file-cast(rune)increment)
            append(&state.move_option_ranks, state.selected_rank-increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, state.selected_file-cast(rune)increment)
          append(&state.capture_option_ranks, state.selected_rank-increment)
          moves_found = true
        }
        if state.selected_file + cast(rune)increment < 'a' {
          moves_found = true
        }
      if state.selected_rank + increment < 0 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Up-left diagonals
    if state.selected_file > 'a' && state.selected_rank < 7 {
      for !moves_found {
        if !check_square_for_piece(state.selected_file-cast(rune)increment, state.selected_rank+increment, .BLACK) {
          if !check_square_for_piece(state.selected_file-cast(rune)increment, state.selected_rank+increment, .WHITE) {
            append(&state.move_option_files, state.selected_file-cast(rune)increment)
            append(&state.move_option_ranks, state.selected_rank+increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, state.selected_file-cast(rune)increment)
          append(&state.capture_option_ranks, state.selected_rank+increment)
          moves_found = true
        }
        if state.selected_file + cast(rune)increment < 'a' {
          moves_found = true
        }
        if state.selected_rank + increment > 7 {
          moves_found = true
        }
      }
    }
  } else {
    //Up-right diagonals
    if state.selected_file < 'h' && state.selected_rank < 7 {
      for !moves_found {
        if !check_square_for_piece(state.selected_file+cast(rune)increment, state.selected_rank+increment, .WHITE) {
          if !check_square_for_piece(state.selected_file+cast(rune)increment, state.selected_rank+increment, .BLACK) {
            append(&state.move_option_files, state.selected_file+cast(rune)increment)
            append(&state.move_option_ranks, state.selected_rank+increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, state.selected_file+cast(rune)increment)
          append(&state.capture_option_ranks, state.selected_rank+increment)
          moves_found = true
        }
        if state.selected_file + cast(rune)increment > 'h' {
          moves_found = true
        }
        if state.selected_rank + increment > 7 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Down-right diagonals
    if state.selected_file < 'h' && state.selected_rank > 0 {
      for !moves_found {
        if !check_square_for_piece(state.selected_file+cast(rune)increment, state.selected_rank-increment, .WHITE) {
          if !check_square_for_piece(state.selected_file+cast(rune)increment, state.selected_rank-increment, .BLACK) {
            append(&state.move_option_files, state.selected_file+cast(rune)increment)
            append(&state.move_option_ranks, state.selected_rank-increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, state.selected_file+cast(rune)increment)
          append(&state.capture_option_ranks, state.selected_rank-increment)
          moves_found = true
        }
        if state.selected_file + cast(rune)increment > 'h' {
          moves_found = true
        }
        if state.selected_rank - increment < 0 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Down-left diagonals
    if state.selected_file < 'a' && state.selected_rank > 0 {
      for !moves_found {
        if !check_square_for_piece(state.selected_file-cast(rune)increment, state.selected_rank-increment, .WHITE) {
          if !check_square_for_piece(state.selected_file-cast(rune)increment, state.selected_rank-increment, .BLACK) {
            append(&state.move_option_files, state.selected_file-cast(rune)increment)
            append(&state.move_option_ranks, state.selected_rank-increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, state.selected_file-cast(rune)increment)
          append(&state.capture_option_ranks, state.selected_rank-increment)
          moves_found = true
        }
        if state.selected_file + cast(rune)increment < 'a' {
          moves_found = true
        }
      if state.selected_rank + increment < 0 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Up-left diagonals
    if state.selected_file > 'a' && state.selected_rank < 7 {
      for !moves_found {
        if !check_square_for_piece(state.selected_file-cast(rune)increment, state.selected_rank+increment, .WHITE) {
          if !check_square_for_piece(state.selected_file-cast(rune)increment, state.selected_rank+increment, .BLACK) {
            append(&state.move_option_files, state.selected_file-cast(rune)increment)
            append(&state.move_option_ranks, state.selected_rank+increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, state.selected_file-cast(rune)increment)
          append(&state.capture_option_ranks, state.selected_rank+increment)
          moves_found = true
        }
        if state.selected_file + cast(rune)increment < 'a' {
          moves_found = true
        }
        if state.selected_rank + increment > 7 {
          moves_found = true
        }
      }
    }
  }
}

get_rook_moves_and_captures :: proc() {
  moves_found: bool
  increment : c.int = 1
  if state.to_move == .WHITE {
    //Forward moves and captures
    if state.selected_rank < 7 {
      for !moves_found {
        if !check_square_for_piece(state.selected_file, state.selected_rank+increment, .BLACK) {
          if !check_square_for_piece(state.selected_file, state.selected_rank+increment, .WHITE) {
            append(&state.move_option_files, state.selected_file)
            append(&state.move_option_ranks, state.selected_rank+increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, state.selected_file)
          append(&state.capture_option_ranks, state.selected_rank+increment)
          moves_found = true
        }
        if state.selected_rank + increment > 7 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Right moves and captures
    if state.selected_file < 'h' {
      for !moves_found {
        if !check_square_for_piece(cast(rune)(cast(i32)state.selected_file+increment), state.selected_rank, .BLACK) {
          if !check_square_for_piece(cast(rune)(cast(i32)state.selected_file+increment), state.selected_rank, .WHITE) {
            append(&state.move_option_files, cast(rune)(cast(i32)state.selected_file+increment))
            append(&state.move_option_ranks, state.selected_rank)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, cast(rune)(cast(i32)state.selected_file+increment))
          append(&state.capture_option_ranks, state.selected_rank)
          moves_found = true
        }
        if cast(rune)(cast(i32)state.selected_file + increment) > 'h' {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Backwards moves and captures
    if state.selected_rank > 0 {
      for !moves_found {
        if !check_square_for_piece(state.selected_file, state.selected_rank-increment, .BLACK) {
          if !check_square_for_piece(state.selected_file, state.selected_rank-increment, .WHITE) {
            append(&state.move_option_files, state.selected_file)
            append(&state.move_option_ranks, state.selected_rank-increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, state.selected_file)
          append(&state.capture_option_ranks, state.selected_rank-increment)
          moves_found = true
        }
        if state.selected_rank - increment < 0 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Left moves and captures
    if state.selected_file > 'a' {
      for !moves_found {
        if !check_square_for_piece(cast(rune)(cast(i32)state.selected_file-increment), state.selected_rank, .BLACK) {
          if !check_square_for_piece(cast(rune)(cast(i32)state.selected_file-increment), state.selected_rank, .WHITE) {
            append(&state.move_option_files, cast(rune)(cast(i32)state.selected_file-increment))
            append(&state.move_option_ranks, state.selected_rank)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, cast(rune)(cast(i32)state.selected_file-increment))
          append(&state.capture_option_ranks, state.selected_rank)
          moves_found = true
        }
        if cast(rune)(cast(i32)state.selected_file - increment) < 'a' {
          moves_found = true
        }
      }
    }
  } else {
    //Forwards moves and captures
    if state.selected_rank > 0 {
      for !moves_found {
        if !check_square_for_piece(state.selected_file, state.selected_rank-increment, .WHITE) {
          if !check_square_for_piece(state.selected_file, state.selected_rank-increment, .BLACK) {
            append(&state.move_option_files, state.selected_file)
            append(&state.move_option_ranks, state.selected_rank-increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, state.selected_file)
          append(&state.capture_option_ranks, state.selected_rank-increment)
          moves_found = true
        }
        if state.selected_rank - increment < 0 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Right moves and captures
    if state.selected_file > 'a' {
      for !moves_found {
        if !check_square_for_piece(cast(rune)(cast(i32)state.selected_file-increment), state.selected_rank, .WHITE) {
          if !check_square_for_piece(cast(rune)(cast(i32)state.selected_file-increment), state.selected_rank, .BLACK) {
            append(&state.move_option_files, cast(rune)(cast(i32)state.selected_file-increment))
            append(&state.move_option_ranks, state.selected_rank)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, cast(rune)(cast(i32)state.selected_file-increment))
          append(&state.capture_option_ranks, state.selected_rank)
          moves_found = true
        }
        if cast(rune)(cast(i32)state.selected_file - increment) < 'a' {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Backwards moves and captures
    if state.selected_rank < 7 {
      for !moves_found {
        if !check_square_for_piece(state.selected_file, state.selected_rank+increment, .WHITE) {
          if !check_square_for_piece(state.selected_file, state.selected_rank+increment, .BLACK) {
            append(&state.move_option_files, state.selected_file)
            append(&state.move_option_ranks, state.selected_rank+increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, state.selected_file)
          append(&state.capture_option_ranks, state.selected_rank+increment)
          moves_found = true
        }
        if state.selected_rank + increment > 7 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Left moves and captures
    if state.selected_file < 'h' {
      for !moves_found {
        if !check_square_for_piece(cast(rune)(cast(i32)state.selected_file+increment), state.selected_rank, .WHITE) {
          if !check_square_for_piece(cast(rune)(cast(i32)state.selected_file+increment), state.selected_rank, .BLACK) {
            append(&state.move_option_files, cast(rune)(cast(i32)state.selected_file+increment))
            append(&state.move_option_ranks, state.selected_rank)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, cast(rune)(cast(i32)state.selected_file+increment))
          append(&state.capture_option_ranks, state.selected_rank)
          moves_found = true
        }
        if cast(rune)(cast(i32)state.selected_file + increment) > 'h' {
          moves_found = true
        }
      }
    }
  }
}

get_king_moves_and_captures :: proc() {
  if state.to_move == .WHITE {
    if state.selected_file < 'h' {
      //Top Right
      if state.selected_rank < 7 {
        if !check_square_for_piece(state.selected_file+1, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file+1)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file+1, state.selected_rank+1, .BLACK) {
          append(&state.capture_option_files, state.selected_file+1)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
      }
      //Bottom Right
      if state.selected_rank > 0 {
        if !check_square_for_piece(state.selected_file+1, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file+1)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file+1, state.selected_rank-1, .BLACK) {
          append(&state.capture_option_files, state.selected_file+1)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
      }
      //Right
      if !check_square_for_piece(state.selected_file+1, state.selected_rank, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank, .BLACK) {
        append(&state.move_option_files, state.selected_file+1)
        append(&state.move_option_ranks, state.selected_rank)
      } else if check_square_for_piece(state.selected_file+1, state.selected_rank, .BLACK) {
        append(&state.capture_option_files, state.selected_file+1)
        append(&state.capture_option_ranks, state.selected_rank)
      }
    }
    if state.selected_file > 'a' {
      //Top Left
      if state.selected_rank < 7 {
        if !check_square_for_piece(state.selected_file-1, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file-1)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file-1, state.selected_rank+1, .BLACK) {
          append(&state.capture_option_files, state.selected_file-1)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
      }
      //Bottom Left
      if state.selected_rank > 0 {
        if !check_square_for_piece(state.selected_file-1, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file-1)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file-1, state.selected_rank-1, .BLACK) {
          append(&state.capture_option_files, state.selected_file-1)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
      }
      //Left
      if !check_square_for_piece(state.selected_file-1, state.selected_rank, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank, .BLACK) {
        append(&state.move_option_files, state.selected_file-1)
        append(&state.move_option_ranks, state.selected_rank)
      } else if check_square_for_piece(state.selected_file-1, state.selected_rank, .BLACK) {
        append(&state.capture_option_files, state.selected_file-1)
        append(&state.capture_option_ranks, state.selected_rank)
      }
    }
    //Top
    if state.selected_rank < 7 {
      if !check_square_for_piece(state.selected_file, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file, state.selected_rank+1, .BLACK) {
        append(&state.move_option_files, state.selected_file)
        append(&state.move_option_ranks, state.selected_rank+1)
      } else if check_square_for_piece(state.selected_file, state.selected_rank+1, .BLACK) {
        append(&state.capture_option_files, state.selected_file)
        append(&state.capture_option_ranks, state.selected_rank+1)
      }
    }
    //Bottom
    if state.selected_rank > 0 {
      if !check_square_for_piece(state.selected_file, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file, state.selected_rank-1, .BLACK) {
        append(&state.move_option_files, state.selected_file)
        append(&state.move_option_ranks, state.selected_rank-1)
      } else if check_square_for_piece(state.selected_file, state.selected_rank-1, .BLACK) {
        append(&state.capture_option_files, state.selected_file)
        append(&state.capture_option_ranks, state.selected_rank-1)
      }
    }
  } else {
    if state.selected_file < 'h' {
      //Top Right
      if state.selected_rank < 7 {
        if !check_square_for_piece(state.selected_file+1, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file+1)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file+1, state.selected_rank+1, .WHITE) {
          append(&state.capture_option_files, state.selected_file+1)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
      }
      //Bottom Right
      if state.selected_rank > 0 {
        if !check_square_for_piece(state.selected_file+1, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file+1)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file+1, state.selected_rank-1, .WHITE) {
          append(&state.capture_option_files, state.selected_file+1)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
      }
      //Right
      if !check_square_for_piece(state.selected_file+1, state.selected_rank, .WHITE) && !check_square_for_piece(state.selected_file+1, state.selected_rank, .BLACK) {
        append(&state.move_option_files, state.selected_file+1)
        append(&state.move_option_ranks, state.selected_rank)
      } else if check_square_for_piece(state.selected_file+1, state.selected_rank, .WHITE) {
        append(&state.capture_option_files, state.selected_file+1)
        append(&state.capture_option_ranks, state.selected_rank)
      }
    }
    if state.selected_file > 'a' {
      //Top Left
      if state.selected_rank < 7 {
        if !check_square_for_piece(state.selected_file-1, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank+1, .BLACK) {
          append(&state.move_option_files, state.selected_file-1)
          append(&state.move_option_ranks, state.selected_rank+1)
        } else if check_square_for_piece(state.selected_file-1, state.selected_rank+1, .WHITE) {
          append(&state.capture_option_files, state.selected_file-1)
          append(&state.capture_option_ranks, state.selected_rank+1)
        }
      }
      //Bottom Left
      if state.selected_rank > 0 {
        if !check_square_for_piece(state.selected_file-1, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank-1, .BLACK) {
          append(&state.move_option_files, state.selected_file-1)
          append(&state.move_option_ranks, state.selected_rank-1)
        } else if check_square_for_piece(state.selected_file-1, state.selected_rank-1, .WHITE) {
          append(&state.capture_option_files, state.selected_file-1)
          append(&state.capture_option_ranks, state.selected_rank-1)
        }
      }
      //Left
      if !check_square_for_piece(state.selected_file-1, state.selected_rank, .WHITE) && !check_square_for_piece(state.selected_file-1, state.selected_rank, .BLACK) {
        append(&state.move_option_files, state.selected_file-1)
        append(&state.move_option_ranks, state.selected_rank)
      } else if check_square_for_piece(state.selected_file-1, state.selected_rank, .WHITE) {
        append(&state.capture_option_files, state.selected_file-1)
        append(&state.capture_option_ranks, state.selected_rank)
      }
    }
    //Top
    if state.selected_rank < 7 {
      if !check_square_for_piece(state.selected_file, state.selected_rank+1, .WHITE) && !check_square_for_piece(state.selected_file, state.selected_rank+1, .BLACK) {
        append(&state.move_option_files, state.selected_file)
        append(&state.move_option_ranks, state.selected_rank+1)
      } else if check_square_for_piece(state.selected_file, state.selected_rank+1, .WHITE) {
        append(&state.capture_option_files, state.selected_file)
        append(&state.capture_option_ranks, state.selected_rank+1)
      }
    }
    //Bottom
    if state.selected_rank > 0 {
      if !check_square_for_piece(state.selected_file, state.selected_rank-1, .WHITE) && !check_square_for_piece(state.selected_file, state.selected_rank-1, .BLACK) {
        append(&state.move_option_files, state.selected_file)
        append(&state.move_option_ranks, state.selected_rank-1)
      } else if check_square_for_piece(state.selected_file, state.selected_rank-1, .WHITE) {
        append(&state.capture_option_files, state.selected_file)
        append(&state.capture_option_ranks, state.selected_rank-1)
      }
    }

  }
}
