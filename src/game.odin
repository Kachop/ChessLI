package main

import "core:fmt"
import "core:strconv"
import "core:unicode/utf8"

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

get_pawn_moves_and_captures :: proc(file: rune = state.selected_file, rank: uint = state.selected_rank) {
  if state.to_move == .WHITE {
    if rank != 7 && rank != 0 {
      if !check_square_for_piece(file, rank+1, .BLACK) && !check_square_for_piece(file, rank+1, .WHITE) {
        append(&state.move_option_files, file)
        append(&state.move_option_ranks, rank+1)
      }
      if rank == 1 {
        //If pawn has not yet moved
        if !check_square_for_piece(file, rank+2, .BLACK) && !check_square_for_piece(file, rank+2, .WHITE) {
          append(&state.move_option_files, file)
          append(&state.move_option_ranks, rank+2)
        }
      }
    }
    if check_square_for_piece(file-1, rank+1, .BLACK) {
      append(&state.capture_option_files, file-1)
      append(&state.capture_option_ranks, rank+1)
    }
    if check_square_for_piece(file+1, rank+1, .BLACK) {
      append(&state.capture_option_files, file+1)
      append(&state.capture_option_ranks, rank+1)
    }
  } else {
    if rank != 7 && rank != 0 {
      if !check_square_for_piece(file, rank-1, .BLACK) && !check_square_for_piece(file, rank-1, .WHITE) {
        append(&state.move_option_files, file)
        append(&state.move_option_ranks, rank-1)
      }
      if rank == 6 {
        //If pawn has not yet moved
        if !check_square_for_piece(file, rank-2, .BLACK) && !check_square_for_piece(file, rank-2, .WHITE) {
          append(&state.move_option_files, file)
          append(&state.move_option_ranks, rank-2)
        }
      }
    }
    if check_square_for_piece(file-1, rank-1, .WHITE) {
      append(&state.capture_option_files, file-1)
      append(&state.capture_option_ranks, rank-1)
    }
    if check_square_for_piece(file+1, rank-1, .WHITE) {
      append(&state.capture_option_files, file+1)
      append(&state.capture_option_ranks, rank-1)
    }
  }
}

get_knight_moves_and_captures :: proc(file: rune = state.selected_file, rank: uint = state.selected_rank) {
  if state.to_move == .WHITE {
    if file == 'a' {
      if rank == 0 {
        if !check_square_for_piece(file+1, rank+2, .WHITE) && !check_square_for_piece(file+1, rank+2, .BLACK) {
          append(&state.move_option_files, file+1)
          append(&state.move_option_ranks, rank+2)
        } else if check_square_for_piece(file+1, rank+2, .BLACK) {
          append(&state.capture_option_files, file+1)
          append(&state.capture_option_ranks, rank+2)
        }
      } else if rank == 7 {
        if !check_square_for_piece(file+1, rank-2, .WHITE) && !check_square_for_piece(file+1, rank-2, .BLACK) {
          append(&state.move_option_files, file+1)
          append(&state.move_option_ranks, rank-2)
        } else if check_square_for_piece(file+1, rank-2, .BLACK) {
          append(&state.capture_option_files, file+1)
          append(&state.capture_option_ranks, rank-2)
        }
      } else {
        if rank + 2 <= 7 {
          if !check_square_for_piece(file+1, rank+2, .WHITE) && !check_square_for_piece(file+1, rank+2, .BLACK) {
            append(&state.move_option_files, file+1)
            append(&state.move_option_ranks, rank+2)
          } else if check_square_for_piece(file+1, rank+2, .BLACK) {
            append(&state.capture_option_files, file+1)
            append(&state.capture_option_ranks, rank+2)
          }
        }
        if !check_square_for_piece(file+2, rank+1, .WHITE) && !check_square_for_piece(file+2, rank+1, .BLACK) {
          append(&state.move_option_files, file+2)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file+2, rank+1, .BLACK) {
          append(&state.capture_option_files, file+2)
          append(&state.capture_option_ranks, rank+1)
        }
        if rank - 2 >= 0 {
          if !check_square_for_piece(file+1, rank-2, .WHITE) && !check_square_for_piece(file+1, rank-2, .BLACK) {
            append(&state.move_option_files, file+1)
            append(&state.move_option_ranks, rank-2)
          } else if check_square_for_piece(file+1, rank-2, .BLACK) {
            append(&state.capture_option_files, file+1)
            append(&state.capture_option_ranks, rank-2)
          }
        }
        if !check_square_for_piece(file+2, rank-1, .WHITE) && !check_square_for_piece(file+2, rank-1, .BLACK) {
          append(&state.move_option_files, file+2)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file+2, rank-1, .BLACK) {
          append(&state.capture_option_files, file+2)
          append(&state.capture_option_ranks, rank-1)
        }
      }
    } else if file == 'h' {
      if rank == 0 {
        if !check_square_for_piece(file-1, rank+2, .WHITE) && !check_square_for_piece(file-1, rank+2, .BLACK) {
          append(&state.move_option_files, file-1)
          append(&state.move_option_ranks, rank+2)
        } else if check_square_for_piece(file-1, rank+2, .BLACK) {
          append(&state.capture_option_files, file-1)
          append(&state.capture_option_ranks, rank+2)
        }

      } else if rank == 7 {
        if !check_square_for_piece(file-1, rank-2, .WHITE) && !check_square_for_piece(file-1, rank-2, .BLACK) {
          append(&state.move_option_files, file-1)
          append(&state.move_option_ranks, rank-2)
        } else if check_square_for_piece(file-1, rank-2, .BLACK) {
          append(&state.capture_option_files, file-1)
          append(&state.capture_option_ranks, rank-2)
        }
      } else {
        if rank + 2 <= 7 {
          if !check_square_for_piece(file-1, rank+2, .WHITE) && !check_square_for_piece(file-1, rank+2, .BLACK) {
            append(&state.move_option_files, file-1)
            append(&state.move_option_ranks, rank+2)
          } else if check_square_for_piece(file-1, rank+2, .BLACK) {
            append(&state.capture_option_files, file-1)
            append(&state.capture_option_ranks, rank+2)
          }
        }
        if !check_square_for_piece(file-2, rank+1, .WHITE) && !check_square_for_piece(file-2, rank+1, .BLACK) {
          append(&state.move_option_files, file-2)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file-2, rank+1, .BLACK) {
          append(&state.capture_option_files, file-2)
          append(&state.capture_option_ranks, rank+1)
        }
        if rank - 2 >= 0 {
          if !check_square_for_piece(file-1, rank-2, .WHITE) && !check_square_for_piece(file-1, rank-2, .BLACK) {
            append(&state.move_option_files, file-1)
            append(&state.move_option_ranks, rank-2)
          } else if check_square_for_piece(file-1, rank-2, .BLACK) {
            append(&state.capture_option_files, file-1)
            append(&state.capture_option_ranks, rank-2)
          }
        }
        if !check_square_for_piece(file-2, rank-1, .WHITE) && !check_square_for_piece(file-2, rank-1, .BLACK) {
          append(&state.move_option_files, file-2)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file-2, rank-1, .BLACK) {
          append(&state.capture_option_files, file-2)
          append(&state.capture_option_ranks, rank-1)
        }
      }
    } else if rank == 0 {
      if file - 2 >= 'a' {
        if !check_square_for_piece(file-2, rank+1, .WHITE) && !check_square_for_piece(file-2, rank+1, .BLACK) {
          append(&state.move_option_files, file-2)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file-2, rank+1, .BLACK) {
          append(&state.capture_option_files, file-2)
          append(&state.capture_option_ranks, rank+1)
        }
      }
      if !check_square_for_piece(file-1, rank+2, .WHITE) && !check_square_for_piece(file-1, rank+2, .BLACK) {
        append(&state.move_option_files, file-1)
        append(&state.move_option_ranks, rank+2)
      } else if check_square_for_piece(file-1, rank+2, .BLACK) {
        append(&state.capture_option_files, file-1)
        append(&state.capture_option_ranks, rank+2)
      }
      if file + 2 <= 'h' {
        if !check_square_for_piece(file+2, rank+1, .WHITE) && !check_square_for_piece(file+2, rank+1, .BLACK) {
          append(&state.move_option_files, file+2)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file+2, rank+1, .BLACK) {
          append(&state.capture_option_files, file+2)
          append(&state.capture_option_ranks, rank+1)
        }
      }
      if !check_square_for_piece(file+1, rank+2, .WHITE) && !check_square_for_piece(file+1, rank+2, .BLACK) {
        append(&state.move_option_files, file+1)
        append(&state.move_option_ranks, rank+2)
      } else if check_square_for_piece(file+1, rank+2, .BLACK) {
        append(&state.capture_option_files, file+1)
        append(&state.capture_option_ranks, rank+2)
      }
    } else if rank == 7 {
      if file - 2 >= 'a' {
        if !check_square_for_piece(file-2, rank-1, .WHITE) && !check_square_for_piece(file-2, rank-1, .BLACK) {
          append(&state.move_option_files, file-2)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file-2, rank-1, .BLACK) {
          append(&state.capture_option_files, file-2)
          append(&state.capture_option_ranks, rank-1)
        }
      }
      if !check_square_for_piece(file-1, rank-2, .WHITE) && !check_square_for_piece(file-1, rank-2, .BLACK) {
        append(&state.move_option_files, file-1)
        append(&state.move_option_ranks, rank-2)
      } else if check_square_for_piece(file-1, rank-2, .BLACK) {
        append(&state.capture_option_files, file-1)
        append(&state.capture_option_ranks, rank-2)
      }
      if file + 2 <= 'h' {
        if !check_square_for_piece(file+2, rank-1, .WHITE) && !check_square_for_piece(file+2, rank-1, .BLACK) {
          append(&state.move_option_files, file+2)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file+2, rank-1, .BLACK) {
          append(&state.capture_option_files, file+2)
          append(&state.capture_option_ranks, rank-1)
        }
      }
      if !check_square_for_piece(file+1, rank-2, .WHITE) && !check_square_for_piece(file+1, rank-2, .BLACK) {
        append(&state.move_option_files, file+1)
        append(&state.move_option_ranks, rank-2)
      } else if check_square_for_piece(file+1, rank-2, .BLACK) {
        append(&state.capture_option_files, file+1)
        append(&state.capture_option_ranks, rank-2)
      }
    } else {
      //Not in a, h, 0 or 7
      if file - 2 >= 'a' {
        if !check_square_for_piece(file-2, rank-1, .WHITE) && !check_square_for_piece(file-2, rank-1, .BLACK) {
          append(&state.move_option_files, file-2)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file-2, rank-1, .BLACK) {
          append(&state.capture_option_files, file-2)
          append(&state.capture_option_ranks, rank-1)
        }
        if !check_square_for_piece(file-2, rank+1, .WHITE) && !check_square_for_piece(file-2, rank+1, .BLACK) {
          append(&state.move_option_files, file-2)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file-2, rank+1, .BLACK) {
          append(&state.capture_option_files, file-2)
          append(&state.capture_option_ranks, rank+1)
        }
      }
      if file + 2 <= 'h' {
        if !check_square_for_piece(file+2, rank-1, .WHITE) && !check_square_for_piece(file+2, rank-1, .BLACK) {
          append(&state.move_option_files, file+2)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file+2, rank-1, .BLACK) {
          append(&state.capture_option_files, file+2)
          append(&state.capture_option_ranks, rank-1)
        }
        if !check_square_for_piece(file+2, rank+1, .WHITE) && !check_square_for_piece(file+2, rank+1, .BLACK) {
          append(&state.move_option_files, file+2)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file+2, rank+1, .BLACK) {
          append(&state.capture_option_files, file+2)
          append(&state.capture_option_ranks, rank+1)
        }
      }
      if rank - 2 >= 0 {
        if !check_square_for_piece(file+1, rank-2, .WHITE) && !check_square_for_piece(file+1, rank-2, .BLACK) {
          append(&state.move_option_files, file+1)
          append(&state.move_option_ranks, rank-2)
        } else if check_square_for_piece(file+1, rank-2, .BLACK) {
          append(&state.capture_option_files, file+1)
          append(&state.capture_option_ranks, rank-2)
        }
        if !check_square_for_piece(file-1, rank-2, .WHITE) && !check_square_for_piece(file-1, rank-2, .BLACK) {
          append(&state.move_option_files, file-1)
          append(&state.move_option_ranks, rank-2)
        } else if check_square_for_piece(file-1, rank-2, .BLACK) {
          append(&state.capture_option_files, file-1)
          append(&state.capture_option_ranks, rank-2)
        }
      }
      if rank + 2 <= 7 {
        if !check_square_for_piece(file+1, rank+2, .WHITE) && !check_square_for_piece(file+1, rank+2, .BLACK) {
          append(&state.move_option_files, file+1)
          append(&state.move_option_ranks, rank+2)
        } else if check_square_for_piece(file+1, rank+2, .BLACK) {
          append(&state.capture_option_files, file+1)
          append(&state.capture_option_ranks, rank+2)
        }
        if !check_square_for_piece(file-1, rank+2, .WHITE) && !check_square_for_piece(file-1, rank+2, .BLACK) {
          append(&state.move_option_files, file-1)
          append(&state.move_option_ranks, rank+2)
        } else if check_square_for_piece(file-1, rank+2, .BLACK) {
          append(&state.capture_option_files, file-1)
          append(&state.capture_option_ranks, rank+2)
        }
      }
    }
  } else {
    if file == 'a' {
      if rank == 0 {
        if !check_square_for_piece(file+1, rank+2, .WHITE) && !check_square_for_piece(file+1, rank+2, .BLACK) {
          append(&state.move_option_files, file+1)
          append(&state.move_option_ranks, rank+2)
        } else if check_square_for_piece(file+1, rank+2, .WHITE) {
          append(&state.capture_option_files, file+1)
          append(&state.capture_option_ranks, rank+2)
        }
      } else if rank == 7 {
        if !check_square_for_piece(file+1, rank-2, .WHITE) && !check_square_for_piece(file+1, rank-2, .BLACK) {
          append(&state.move_option_files, file+1)
          append(&state.move_option_ranks, rank-2)
        } else if check_square_for_piece(file+1, rank-2, .WHITE) {
          append(&state.capture_option_files, file+1)
          append(&state.capture_option_ranks, rank-2)
        }
      } else {
        if rank + 2 <= 7 {
          if !check_square_for_piece(file+1, rank+2, .WHITE) && !check_square_for_piece(file+1, rank+2, .BLACK) {
            append(&state.move_option_files, file+1)
            append(&state.move_option_ranks, rank+2)
          } else if check_square_for_piece(file+1, rank+2, .WHITE) {
            append(&state.capture_option_files, file+1)
            append(&state.capture_option_ranks, rank+2)
          }
        }
        if !check_square_for_piece(file+2, rank+1, .WHITE) && !check_square_for_piece(file+2, rank+1, .BLACK) {
          append(&state.move_option_files, file+2)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file+2, rank+1, .WHITE) {
          append(&state.capture_option_files, file+2)
          append(&state.capture_option_ranks, rank+1)
        }
        if rank - 2 >= 0 {
          if !check_square_for_piece(file+1, rank-2, .WHITE) && !check_square_for_piece(file+1, rank-2, .BLACK) {
            append(&state.move_option_files, file+1)
            append(&state.move_option_ranks, rank-2)
          } else if check_square_for_piece(file+1, rank-2, .WHITE) {
            append(&state.capture_option_files, file+1)
            append(&state.capture_option_ranks, rank-2)
          }
        }
        if !check_square_for_piece(file+2, rank-1, .WHITE) && !check_square_for_piece(file+2, rank-1, .BLACK) {
          append(&state.move_option_files, file+2)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file+2, rank-1, .WHITE) {
          append(&state.capture_option_files, file+2)
          append(&state.capture_option_ranks, rank-1)
        }
      }
    } else if file == 'h' {
      if rank == 0 {
        if !check_square_for_piece(file-1, rank+2, .WHITE) && !check_square_for_piece(file-1, rank+2, .BLACK) {
          append(&state.move_option_files, file-1)
          append(&state.move_option_ranks, rank+2)
        } else if check_square_for_piece(file-1, rank+2, .WHITE) {
          append(&state.capture_option_files, file-1)
          append(&state.capture_option_ranks, rank+2)
        }

      } else if rank == 7 {
        if !check_square_for_piece(file-1, rank-2, .WHITE) && !check_square_for_piece(file-1, rank-2, .BLACK) {
          append(&state.move_option_files, file-1)
          append(&state.move_option_ranks, rank-2)
        } else if check_square_for_piece(file-1, rank-2, .WHITE) {
          append(&state.capture_option_files, file-1)
          append(&state.capture_option_ranks, rank-2)
        }
      } else {
        if rank + 2 <= 7 {
          if !check_square_for_piece(file-1, rank+2, .WHITE) && !check_square_for_piece(file-1, rank+2, .BLACK) {
            append(&state.move_option_files, file-1)
            append(&state.move_option_ranks, rank+2)
          } else if check_square_for_piece(file-1, rank+2, .WHITE) {
            append(&state.capture_option_files, file-1)
            append(&state.capture_option_ranks, rank+2)
          }
        }
        if !check_square_for_piece(file-2, rank+1, .WHITE) && !check_square_for_piece(file-2, rank+1, .BLACK) {
          append(&state.move_option_files, file-2)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file-2, rank+1, .WHITE) {
          append(&state.capture_option_files, file-2)
          append(&state.capture_option_ranks, rank+1)
        }
        if rank - 2 >= 0 {
          if !check_square_for_piece(file-1, rank-2, .WHITE) && !check_square_for_piece(file-1, rank-2, .BLACK) {
            append(&state.move_option_files, file-1)
            append(&state.move_option_ranks, rank-2)
          } else if check_square_for_piece(file-1, rank-2, .WHITE) {
            append(&state.capture_option_files, file-1)
            append(&state.capture_option_ranks, rank-2)
          }
        }
        if !check_square_for_piece(file-2, rank-1, .WHITE) && !check_square_for_piece(file-2, rank-1, .BLACK) {
          append(&state.move_option_files, file-2)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file-2, rank-1, .WHITE) {
          append(&state.capture_option_files, file-2)
          append(&state.capture_option_ranks, rank-1)
        }
      }
    } else if rank == 0 {
      if file - 2 >= 'a' {
        if !check_square_for_piece(file-2, rank+1, .WHITE) && !check_square_for_piece(file-2, rank+1, .BLACK) {
          append(&state.move_option_files, file-2)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file-2, rank+1, .WHITE) {
          append(&state.capture_option_files, file-2)
          append(&state.capture_option_ranks, rank+1)
        }
      }
      if !check_square_for_piece(file-1, rank+2, .WHITE) && !check_square_for_piece(file-1, rank+2, .BLACK) {
        append(&state.move_option_files, file-1)
        append(&state.move_option_ranks, rank+2)
      } else if check_square_for_piece(file-1, rank+2, .WHITE) {
        append(&state.capture_option_files, file-1)
        append(&state.capture_option_ranks, rank+2)
      }
      if file + 2 <= 'h' {
        if !check_square_for_piece(file+2, rank+1, .WHITE) && !check_square_for_piece(file+2, rank+1, .BLACK) {
          append(&state.move_option_files, file+2)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file+2, rank+1, .WHITE) {
          append(&state.capture_option_files, file+2)
          append(&state.capture_option_ranks, rank+1)
        }
      }
      if !check_square_for_piece(file+1, rank+2, .WHITE) && !check_square_for_piece(file+1, rank+2, .BLACK) {
        append(&state.move_option_files, file+1)
        append(&state.move_option_ranks, rank+2)
      } else if check_square_for_piece(file+1, rank+2, .WHITE) {
        append(&state.capture_option_files, file+1)
        append(&state.capture_option_ranks, rank+2)
      }
    } else if rank == 7 {
      if file - 2 >= 'a' {
        if !check_square_for_piece(file-2, rank-1, .WHITE) && !check_square_for_piece(file-2, rank-1, .BLACK) {
          append(&state.move_option_files, file-2)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file-2, rank-1, .WHITE) {
          append(&state.capture_option_files, file-2)
          append(&state.capture_option_ranks, rank-1)
        }
      }
      if !check_square_for_piece(file-1, rank-2, .WHITE) && !check_square_for_piece(file-1, rank-2, .BLACK) {
        append(&state.move_option_files, file-1)
        append(&state.move_option_ranks, rank-2)
      } else if check_square_for_piece(file-1, rank-2, .WHITE) {
        append(&state.capture_option_files, file-1)
        append(&state.capture_option_ranks, rank-2)
      }
      if file + 2 <= 'h' {
        if !check_square_for_piece(file+2, rank-1, .WHITE) && !check_square_for_piece(file+2, rank-1, .BLACK) {
          append(&state.move_option_files, file+2)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file+2, rank-1, .WHITE) {
          append(&state.capture_option_files, file+2)
          append(&state.capture_option_ranks, rank-1)
        }
      }
      if !check_square_for_piece(file+1, rank-2, .WHITE) && !check_square_for_piece(file+1, rank-2, .BLACK) {
        append(&state.move_option_files, file+1)
        append(&state.move_option_ranks, rank-2)
      } else if check_square_for_piece(file+1, rank-2, .WHITE) {
        append(&state.capture_option_files, file+1)
        append(&state.capture_option_ranks, rank-2)
      }
    } else {
      //Not in a, h, 0 or 7
      if file - 2 >= 'a' {
        if !check_square_for_piece(file-2, rank-1, .WHITE) && !check_square_for_piece(file-2, rank-1, .BLACK) {
          append(&state.move_option_files, file-2)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file-2, rank-1, .WHITE) {
          append(&state.capture_option_files, file-2)
          append(&state.capture_option_ranks, rank-1)
        }
        if !check_square_for_piece(file-2, rank+1, .WHITE) && !check_square_for_piece(file-2, rank+1, .BLACK) {
          append(&state.move_option_files, file-2)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file-2, rank+1, .WHITE) {
          append(&state.capture_option_files, file-2)
          append(&state.capture_option_ranks, rank+1)
        }
      }
      if file + 2 <= 'h' {
        if !check_square_for_piece(file+2, rank-1, .WHITE) && !check_square_for_piece(file+2, rank-1, .BLACK) {
          append(&state.move_option_files, file+2)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file+2, rank-1, .WHITE) {
          append(&state.capture_option_files, file+2)
          append(&state.capture_option_ranks, rank-1)
        }
        if !check_square_for_piece(file+2, rank+1, .WHITE) && !check_square_for_piece(file+2, rank+1, .BLACK) {
          append(&state.move_option_files, file+2)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file+2, rank+1, .WHITE) {
          append(&state.capture_option_files, file+2)
          append(&state.capture_option_ranks, rank+1)
        }
      }
      if rank - 2 >= 0 {
        if !check_square_for_piece(file+1, rank-2, .WHITE) && !check_square_for_piece(file+1, rank-2, .BLACK) {
          append(&state.move_option_files, file+1)
          append(&state.move_option_ranks, rank-2)
        } else if check_square_for_piece(file+1, rank-2, .WHITE) {
          append(&state.capture_option_files, file+1)
          append(&state.capture_option_ranks, rank-2)
        }
        if !check_square_for_piece(file-1, rank-2, .WHITE) && !check_square_for_piece(file-1, rank-2, .BLACK) {
          append(&state.move_option_files, file-1)
          append(&state.move_option_ranks, rank-2)
        } else if check_square_for_piece(file-1, rank-2, .WHITE) {
          append(&state.capture_option_files, file-1)
          append(&state.capture_option_ranks, rank-2)
        }
      }
      if rank + 2 <= 7 {
        if !check_square_for_piece(file+1, rank+2, .WHITE) && !check_square_for_piece(file+1, rank+2, .BLACK) {
          append(&state.move_option_files, file+1)
          append(&state.move_option_ranks, rank+2)
        } else if check_square_for_piece(file+1, rank+2, .WHITE) {
          append(&state.capture_option_files, file+1)
          append(&state.capture_option_ranks, rank+2)
        }
        if !check_square_for_piece(file-1, rank+2, .WHITE) && !check_square_for_piece(file-1, rank+2, .BLACK) {
          append(&state.move_option_files, file-1)
          append(&state.move_option_ranks, rank+2)
        } else if check_square_for_piece(file-1, rank+2, .WHITE) {
          append(&state.capture_option_files, file-1)
          append(&state.capture_option_ranks, rank+2)
        }
      }
    }
  }
}

get_bishop_moves_and_captures :: proc(file: rune = state.selected_file, rank: uint = state.selected_rank) {
  moves_found: bool
  increment : uint = 1
  if state.to_move == .WHITE {
    //Up-right diagonals
    if file < 'h' && rank < 7 {
      for !moves_found {
        if !check_square_for_piece(file+cast(rune)increment, rank+increment, .BLACK) {
          if !check_square_for_piece(file+cast(rune)increment, rank+increment, .WHITE) {
            append(&state.move_option_files, file+cast(rune)increment)
            append(&state.move_option_ranks, rank+increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file+cast(rune)increment)
          append(&state.capture_option_ranks, rank+increment)
          moves_found = true
        }
        if file + cast(rune)increment > 'h' {
          moves_found = true
        }
        if rank + increment > 7 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Down-right diagonals
    if file < 'h' && rank > 0 {
      for !moves_found {
        if !check_square_for_piece(file+cast(rune)increment, rank-increment, .BLACK) {
          if !check_square_for_piece(file+cast(rune)increment, rank-increment, .WHITE) {
            append(&state.move_option_files, file+cast(rune)increment)
            append(&state.move_option_ranks, rank-increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file+cast(rune)increment)
          append(&state.capture_option_ranks, rank-increment)
          moves_found = true
        }
        if file + cast(rune)increment > 'h' {
          moves_found = true
        }
        if rank - increment < 0 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Down-left diagonals
    if file < 'a' && rank > 0 {
      for !moves_found {
        if !check_square_for_piece(file-cast(rune)increment, rank-increment, .BLACK) {
          if !check_square_for_piece(file-cast(rune)increment, rank-increment, .WHITE) {
            append(&state.move_option_files, file-cast(rune)increment)
            append(&state.move_option_ranks, rank-increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file-cast(rune)increment)
          append(&state.capture_option_ranks, rank-increment)
          moves_found = true
        }
        if file + cast(rune)increment < 'a' {
          moves_found = true
        }
      if rank + increment < 0 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Up-left diagonals
    if file > 'a' && rank < 7 {
      for !moves_found {
        if !check_square_for_piece(file-cast(rune)increment, rank+increment, .BLACK) {
          if !check_square_for_piece(file-cast(rune)increment, rank+increment, .WHITE) {
            append(&state.move_option_files, file-cast(rune)increment)
            append(&state.move_option_ranks, rank+increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file-cast(rune)increment)
          append(&state.capture_option_ranks, rank+increment)
          moves_found = true
        }
        if file + cast(rune)increment < 'a' {
          moves_found = true
        }
        if rank + increment > 7 {
          moves_found = true
        }
      }
    }
  } else {
    //Up-right diagonals
    if file > 'a' && rank > 0 {
      for !moves_found {
        if !check_square_for_piece(file-cast(rune)increment, rank-increment, .WHITE) {
          if !check_square_for_piece(file-cast(rune)increment, rank-increment, .BLACK) {
            append(&state.move_option_files, file-cast(rune)increment)
            append(&state.move_option_ranks, rank-increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file-cast(rune)increment)
          append(&state.capture_option_ranks, rank-increment)
          moves_found = true
        }
        if file - cast(rune)increment < 'a' {
          moves_found = true
        }
        if rank - increment < 0 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Down-right diagonals
    if file > 'a' && rank < 7 {
      for !moves_found {
        if !check_square_for_piece(file-cast(rune)increment, rank+increment, .WHITE) {
          if !check_square_for_piece(file-cast(rune)increment, rank+increment, .BLACK) {
            append(&state.move_option_files, file-cast(rune)increment)
            append(&state.move_option_ranks, rank+increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file-cast(rune)increment)
          append(&state.capture_option_ranks, rank+increment)
          moves_found = true
        }
        if file - cast(rune)increment < 'a' {
          moves_found = true
        }
        if rank + increment > 7 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Down-left diagonals
    if file < 'h' && rank < 7 {
      for !moves_found {
        if !check_square_for_piece(file+cast(rune)increment, rank+increment, .WHITE) {
          if !check_square_for_piece(file+cast(rune)increment, rank+increment, .BLACK) {
            append(&state.move_option_files, file+cast(rune)increment)
            append(&state.move_option_ranks, rank+increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file+cast(rune)increment)
          append(&state.capture_option_ranks, rank+increment)
          moves_found = true
        }
        if file + cast(rune)increment > 'h' {
          moves_found = true
        }
      if rank + increment > 7 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Up-left diagonals
    if file < 'h' && rank > 0 {
      for !moves_found {
        if !check_square_for_piece(file+cast(rune)increment, rank-increment, .WHITE) {
          if !check_square_for_piece(file+cast(rune)increment, rank-increment, .BLACK) {
            append(&state.move_option_files, file+cast(rune)increment)
            append(&state.move_option_ranks, rank-increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file+cast(rune)increment)
          append(&state.capture_option_ranks, rank-increment)
          moves_found = true
        }
        if file + cast(rune)increment > 'h' {
          moves_found = true
        }
        if rank - increment < 0 {
          moves_found = true
        }
      }
    }
  }
}

get_rook_moves_and_captures :: proc(file: rune = state.selected_file, rank: uint = state.selected_rank) {
  moves_found: bool
  increment : uint = 1
  if state.to_move == .WHITE {
    //Forward moves and captures
    if rank < 7 {
      for !moves_found {
        if !check_square_for_piece(file, rank+increment, .BLACK) {
          if !check_square_for_piece(file, rank+increment, .WHITE) {
            append(&state.move_option_files, file)
            append(&state.move_option_ranks, rank+increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file)
          append(&state.capture_option_ranks, rank+increment)
          moves_found = true
        }
        if rank + increment > 7 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Right moves and captures
    if file < 'h' {
      for !moves_found {
        if !check_square_for_piece(file+cast(rune)increment, rank, .BLACK) {
          if !check_square_for_piece(file+cast(rune)increment, rank, .WHITE) {
            append(&state.move_option_files, file+cast(rune)increment)
            append(&state.move_option_ranks, rank)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file+cast(rune)increment)
          append(&state.capture_option_ranks, rank)
          moves_found = true
        }
        if file + cast(rune)increment > 'h' {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Backwards moves and captures
    if rank > 0 {
      for !moves_found {
        if !check_square_for_piece(file, rank-increment, .BLACK) {
          if !check_square_for_piece(file, rank-increment, .WHITE) {
            append(&state.move_option_files, file)
            append(&state.move_option_ranks, rank-increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file)
          append(&state.capture_option_ranks, rank-increment)
          moves_found = true
        }
        if rank - increment < 0 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Left moves and captures
    if file > 'a' {
      for !moves_found {
        if !check_square_for_piece(file-cast(rune)increment, rank, .BLACK) {
          if !check_square_for_piece(file-cast(rune)increment, rank, .WHITE) {
            append(&state.move_option_files, file-cast(rune)increment)
            append(&state.move_option_ranks, rank)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file-cast(rune)increment)
          append(&state.capture_option_ranks, rank)
          moves_found = true
        }
        if file - cast(rune)increment < 'a' {
          moves_found = true
        }
      }
    }
  } else {
    //Forwards moves and captures
    if rank > 0 {
      for !moves_found {
        if !check_square_for_piece(file, rank-increment, .WHITE) {
          if !check_square_for_piece(file, rank-increment, .BLACK) {
            append(&state.move_option_files, file)
            append(&state.move_option_ranks, rank-increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file)
          append(&state.capture_option_ranks, rank-increment)
          moves_found = true
        }
        if rank - increment < 0 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Right moves and captures
    if file > 'a' {
      for !moves_found {
        if !check_square_for_piece(file-cast(rune)increment, rank, .WHITE) {
          if !check_square_for_piece(file-cast(rune)increment, rank, .BLACK) {
            append(&state.move_option_files, file-cast(rune)increment)
            append(&state.move_option_ranks, rank)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file-cast(rune)increment)
          append(&state.capture_option_ranks, rank)
          moves_found = true
        }
        if file - cast(rune)increment < 'a' {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Backwards moves and captures
    if rank < 7 {
      for !moves_found {
        if !check_square_for_piece(file, rank+increment, .WHITE) {
          if !check_square_for_piece(file, rank+increment, .BLACK) {
            append(&state.move_option_files, file)
            append(&state.move_option_ranks, rank+increment)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file)
          append(&state.capture_option_ranks, rank+increment)
          moves_found = true
        }
        if rank + increment > 7 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Left moves and captures
    if file < 'h' {
      for !moves_found {
        if !check_square_for_piece(file+cast(rune)increment, rank, .WHITE) {
          if !check_square_for_piece(file+cast(rune)increment, rank, .BLACK) {
            append(&state.move_option_files, file+cast(rune)increment)
            append(&state.move_option_ranks, rank)
            increment += 1
          } else {
            moves_found = true
          }
        } else {
          append(&state.capture_option_files, file+cast(rune)increment)
          append(&state.capture_option_ranks, rank)
          moves_found = true
        }
        if file + cast(rune)increment > 'h' {
          moves_found = true
        }
      }
    }
  }
}

get_king_moves_and_captures :: proc(file: rune = state.selected_file, rank: uint = state.selected_rank) {
  if state.to_move == .WHITE {
    if file < 'h' {
      //Top Right
      if rank < 7 {
        if !check_square_for_piece(file+1, rank+1, .WHITE) && !check_square_for_piece(file+1, rank+1, .BLACK) {
          append(&state.move_option_files, file+1)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file+1, rank+1, .BLACK) {
          append(&state.capture_option_files, file+1)
          append(&state.capture_option_ranks, rank+1)
        }
      }
      //Bottom Right
      if rank > 0 {
        if !check_square_for_piece(file+1, rank-1, .WHITE) && !check_square_for_piece(file+1, rank-1, .BLACK) {
          append(&state.move_option_files, file+1)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file+1, rank-1, .BLACK) {
          append(&state.capture_option_files, file+1)
          append(&state.capture_option_ranks, rank-1)
        }
      }
      //Right
      if !check_square_for_piece(file+1, rank, .WHITE) && !check_square_for_piece(file+1, rank, .BLACK) {
        append(&state.move_option_files, file+1)
        append(&state.move_option_ranks, rank)
      } else if check_square_for_piece(file+1, rank, .BLACK) {
        append(&state.capture_option_files, file+1)
        append(&state.capture_option_ranks, rank)
      }
    }
    if file > 'a' {
      //Top Left
      if rank < 7 {
        if !check_square_for_piece(file-1, rank+1, .WHITE) && !check_square_for_piece(file-1, rank+1, .BLACK) {
          append(&state.move_option_files, file-1)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file-1, rank+1, .BLACK) {
          append(&state.capture_option_files, file-1)
          append(&state.capture_option_ranks, rank+1)
        }
      }
      //Bottom Left
      if rank > 0 {
        if !check_square_for_piece(file-1, rank-1, .WHITE) && !check_square_for_piece(file-1, rank-1, .BLACK) {
          append(&state.move_option_files, file-1)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file-1, rank-1, .BLACK) {
          append(&state.capture_option_files, file-1)
          append(&state.capture_option_ranks, rank-1)
        }
      }
      //Left
      if !check_square_for_piece(file-1, rank, .WHITE) && !check_square_for_piece(file-1, rank, .BLACK) {
        append(&state.move_option_files, file-1)
        append(&state.move_option_ranks, rank)
      } else if check_square_for_piece(file-1, rank, .BLACK) {
        append(&state.capture_option_files, file-1)
        append(&state.capture_option_ranks, rank)
      }
    }
    //Top
    if rank < 7 {
      if !check_square_for_piece(file, rank+1, .WHITE) && !check_square_for_piece(file, rank+1, .BLACK) {
        append(&state.move_option_files, file)
        append(&state.move_option_ranks, rank+1)
      } else if check_square_for_piece(file, rank+1, .BLACK) {
        append(&state.capture_option_files, file)
        append(&state.capture_option_ranks, rank+1)
      }
    }
    //Bottom
    if rank > 0 {
      if !check_square_for_piece(file, rank-1, .WHITE) && !check_square_for_piece(file, rank-1, .BLACK) {
        append(&state.move_option_files, file)
        append(&state.move_option_ranks, rank-1)
      } else if check_square_for_piece(file, rank-1, .BLACK) {
        append(&state.capture_option_files, file)
        append(&state.capture_option_ranks, rank-1)
      }
    }
  } else {
    if file < 'h' {
      //Top Right
      if rank < 7 {
        if !check_square_for_piece(file+1, rank+1, .WHITE) && !check_square_for_piece(file+1, rank+1, .BLACK) {
          append(&state.move_option_files, file+1)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file+1, rank+1, .WHITE) {
          append(&state.capture_option_files, file+1)
          append(&state.capture_option_ranks, rank+1)
        }
      }
      //Bottom Right
      if rank > 0 {
        if !check_square_for_piece(file+1, rank-1, .WHITE) && !check_square_for_piece(file+1, rank-1, .BLACK) {
          append(&state.move_option_files, file+1)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file+1, rank-1, .WHITE) {
          append(&state.capture_option_files, file+1)
          append(&state.capture_option_ranks, rank-1)
        }
      }
      //Right
      if !check_square_for_piece(file+1, rank, .WHITE) && !check_square_for_piece(file+1, rank, .BLACK) {
        append(&state.move_option_files, file+1)
        append(&state.move_option_ranks, rank)
      } else if check_square_for_piece(file+1, rank, .WHITE) {
        append(&state.capture_option_files, file+1)
        append(&state.capture_option_ranks, rank)
      }
    }
    if file > 'a' {
      //Top Left
      if rank < 7 {
        if !check_square_for_piece(file-1, rank+1, .WHITE) && !check_square_for_piece(file-1, rank+1, .BLACK) {
          append(&state.move_option_files, file-1)
          append(&state.move_option_ranks, rank+1)
        } else if check_square_for_piece(file-1, rank+1, .WHITE) {
          append(&state.capture_option_files, file-1)
          append(&state.capture_option_ranks, rank+1)
        }
      }
      //Bottom Left
      if rank > 0 {
        if !check_square_for_piece(file-1, rank-1, .WHITE) && !check_square_for_piece(file-1, rank-1, .BLACK) {
          append(&state.move_option_files, file-1)
          append(&state.move_option_ranks, rank-1)
        } else if check_square_for_piece(file-1, rank-1, .WHITE) {
          append(&state.capture_option_files, file-1)
          append(&state.capture_option_ranks, rank-1)
        }
      }
      //Left
      if !check_square_for_piece(file-1, rank, .WHITE) && !check_square_for_piece(file-1, rank, .BLACK) {
        append(&state.move_option_files, file-1)
        append(&state.move_option_ranks, rank)
      } else if check_square_for_piece(file-1, rank, .WHITE) {
        append(&state.capture_option_files, file-1)
        append(&state.capture_option_ranks, rank)
      }
    }
    //Top
    if rank < 7 {
      if !check_square_for_piece(file, rank+1, .WHITE) && !check_square_for_piece(file, rank+1, .BLACK) {
        append(&state.move_option_files, file)
        append(&state.move_option_ranks, rank+1)
      } else if check_square_for_piece(file, rank+1, .WHITE) {
        append(&state.capture_option_files, file)
        append(&state.capture_option_ranks, rank+1)
      }
    }
    //Bottom
    if rank > 0 {
      if !check_square_for_piece(file, rank-1, .WHITE) && !check_square_for_piece(file, rank-1, .BLACK) {
        append(&state.move_option_files, file)
        append(&state.move_option_ranks, rank-1)
      } else if check_square_for_piece(file, rank-1, .WHITE) {
        append(&state.capture_option_files, file)
        append(&state.capture_option_ranks, rank-1)
      }
    }

  }
}

is_check :: proc(board: map[rune][dynamic]PieceInfo = state.board.piece_map) -> bool {
  //Checks the current board (or a given one) for check_square_for_piece
  //Checks after enter is pressed. Check piece on given board at hover location

  old_move_files := state.move_option_files
  old_move_ranks := state.move_option_ranks
  old_capture_files := state.capture_option_files
  old_capture_ranks := state.capture_option_ranks

  clear(&state.move_option_files)
  clear(&state.move_option_ranks)
  clear(&state.capture_option_files)
  clear(&state.capture_option_ranks)

  piece := board[state.hovered_file][state.hovered_rank]

  #partial switch piece.piece {
  case .PAWN:
    get_pawn_moves_and_captures(state.hovered_file, state.hovered_rank)
  case .KNIGHT:
    get_knight_moves_and_captures(state.hovered_file, state.hovered_rank)
  case .BISHOP:
    get_bishop_moves_and_captures(state.hovered_file, state.hovered_rank)
  case .ROOK:
    get_rook_moves_and_captures(state.hovered_file, state.hovered_rank)
  case .QUEEN:
    get_bishop_moves_and_captures(state.hovered_file, state.hovered_rank)
    get_rook_moves_and_captures(state.hovered_file, state.hovered_rank)
  }
  
  for i in 0 ..< len(state.capture_option_files) {
    if board[state.capture_option_files[i]][state.capture_option_ranks[i]].piece == .KING {
      clear(&state.move_option_files)
      clear(&state.move_option_ranks)
      get_king_moves_and_captures(state.capture_option_files[i], state.capture_option_ranks[i])
      return true
    }
  }
  state.move_option_files, state.move_option_ranks = old_move_files, old_move_ranks
  state.capture_option_files, state.capture_option_ranks = old_capture_files, old_capture_ranks
  return false
}

is_checkmate :: proc() {
}
