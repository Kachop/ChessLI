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
/*
get_pawn_moves_and_captures :: proc(file: rune = state.selected_file, rank: uint = state.selected_rank, colour: Colour = state.to_move) {
  if colour == .WHITE {
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
    if state.last_move.piece == .PAWN && abs(cast(int)state.last_move.end_file - cast(int)file) == 1 {
      if state.last_move.start_rank == 6 && state.last_move.end_rank == 4 && rank == 4 {
        append(&state.capture_option_files, state.last_move.end_file)
        append(&state.capture_option_ranks, rank+1)
      }
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
    if state.last_move.piece == .PAWN && abs(cast(int)state.last_move.end_file - cast(int)file) == 1 {
      if state.last_move.start_rank == 1 && state.last_move.end_rank == 3 && rank == 3 {
        append(&state.capture_option_files, state.last_move.end_file)
        append(&state.capture_option_ranks, rank-1)
      }
    }
  }
}

get_knight_moves_and_captures :: proc(file: rune = state.selected_file, rank: uint = state.selected_rank, colour: Colour = state.to_move) {
  if colour == .WHITE {
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
        if cast(int)rank - 2 >= 0 {
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
        if cast(int)rank - 2 >= 0 {
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
      if cast(int)rank - 2 >= 0 {
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
        if cast(int)rank - 2 >= 0 {
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
        if cast(int)rank - 2 >= 0 {
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
      if cast(int)rank - 2 >= 0 {
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

get_bishop_moves_and_captures :: proc(file: rune = state.selected_file, rank: uint = state.selected_rank, colour: Colour = state.to_move) {
  moves_found: bool
  increment : uint = 1
  if colour == .WHITE {
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
        if cast(int)rank - cast(int)increment < 0 {
          moves_found = true
        }
      }
    }
    moves_found = false
    increment = 1
    //Down-left diagonals
    if file > 'a' && rank > 0 {
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
        if file - cast(rune)increment < 'a' {
          moves_found = true
        }
      if cast(int)rank - cast(int)increment < 0 {
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
        if file - cast(rune)increment < 'a' {
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
        if cast(int)rank - cast(int)increment < 0 {
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
        if cast(int)rank - cast(int)increment < 0 {
          moves_found = true
        }
      }
    }
  }
}

get_rook_moves_and_captures :: proc(file: rune = state.selected_file, rank: uint = state.selected_rank, colour: Colour = state.to_move) {
  moves_found: bool
  increment : uint = 1
  if colour == .WHITE {
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
        if cast(int)rank - cast(int)increment < 0 {
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
        if cast(int)rank - cast(int)increment < 0 {
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

get_king_moves_and_captures :: proc(file: rune = state.selected_file, rank: uint = state.selected_rank, colour: Colour = state.to_move) {
  if colour == .WHITE {
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
    if file == 'e' && rank == 0 && state.can_castle_white_ks {
      if !check_square_for_piece('f', 0, .WHITE) && !check_square_for_piece('f', 0, .BLACK) {
        if !check_square_for_piece('g', 0, .WHITE) && !check_square_for_piece('g', 0, .BLACK) {
          temp_board := make(map[rune][dynamic]PieceInfo)
          defer delete(temp_board)
          copy_board(&temp_board, state.board.piece_map)

          state.board.piece_map['f'][0] = state.board.piece_map['e'][0]
          state.board.piece_map['e'][0] = PieceInfo{}
          if !is_check(colour = .WHITE) {
            state.board.piece_map['g'][0] = state.board.piece_map['f'][0]
            state.board.piece_map['f'][0] = PieceInfo{}
            if !is_check(colour = .WHITE) {
              append(&state.move_option_files, 'g')
              append(&state.move_option_ranks, 0)
            }
          }
          copy_board(&state.board.piece_map, temp_board)
        }
      }
    }
    if file == 'e' && rank == 0 && state.can_castle_white_qs {
      if !check_square_for_piece('d', 0, .WHITE) && !check_square_for_piece('d', 0, .BLACK) {
        if !check_square_for_piece('c', 0, .WHITE) && !check_square_for_piece('c', 0, .BLACK) {
          if !check_square_for_piece('b', 0, .WHITE) && !check_square_for_piece('b', 0, .BLACK) {
            temp_board := make(map[rune][dynamic]PieceInfo)
            defer delete(temp_board)
            copy_board(&temp_board, state.board.piece_map)

            state.board.piece_map['d'][0] = state.board.piece_map['e'][0]
            state.board.piece_map['e'][0] = PieceInfo{}
            if !is_check(colour = .WHITE) {
              state.board.piece_map['c'][0] = state.board.piece_map['d'][0]
              state.board.piece_map['d'][0] = PieceInfo{}
              if !is_check(colour = .WHITE) {
                append(&state.move_option_files, 'c')
                append(&state.move_option_ranks, 0)
              }
            }
            copy_board(&state.board.piece_map, temp_board)

          }
        }
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
    if file == 'e' && rank == 7 && state.can_castle_black_ks {
      if !check_square_for_piece('f', 7, .WHITE) && !check_square_for_piece('f', 7, .BLACK) {
        if !check_square_for_piece('g', 7, .WHITE) && !check_square_for_piece('g', 7, .BLACK) {
          temp_board := make(map[rune][dynamic]PieceInfo)
          defer delete(temp_board)
          copy_board(&temp_board, state.board.piece_map)

          state.board.piece_map['f'][7] = state.board.piece_map['e'][7]
          state.board.piece_map['e'][7] = PieceInfo{}
          if !is_check(colour = .WHITE) {
            state.board.piece_map['g'][7] = state.board.piece_map['f'][7]
            state.board.piece_map['f'][7] = PieceInfo{}
            if !is_check(colour = .WHITE) {
              append(&state.move_option_files, 'g')
              append(&state.move_option_ranks, 7)
            }
          }
          copy_board(&state.board.piece_map, temp_board)
        }
      }
    }
    if file == 'e' && rank == 7 && state.can_castle_black_qs {
      if !check_square_for_piece('d', 7, .WHITE) && !check_square_for_piece('d', 7, .BLACK) {
        if !check_square_for_piece('c', 7, .WHITE) && !check_square_for_piece('c', 7, .BLACK) {
          if !check_square_for_piece('b', 7, .WHITE) && !check_square_for_piece('b', 7, .BLACK) {
            temp_board := make(map[rune][dynamic]PieceInfo)
            defer delete(temp_board)
            copy_board(&temp_board, state.board.piece_map)

            state.board.piece_map['d'][7] = state.board.piece_map['e'][7]
            state.board.piece_map['e'][7] = PieceInfo{}
            if !is_check(colour = .WHITE) {
              state.board.piece_map['c'][7] = state.board.piece_map['d'][7]
              state.board.piece_map['d'][7] = PieceInfo{}
              if !is_check(colour = .WHITE) {
                append(&state.move_option_files, 'c')
                append(&state.move_option_ranks, 7)
              }
            }
            copy_board(&state.board.piece_map, temp_board)
          }
        }
      } 
    }
  }
}

/*
Checks a given board state (current board state by default) and for a given colour pieces if the opposing king is in check
Loops through all of the pieces of a given colour and accumulates all of the available captures.
If one of those avaialble captures is the king then returns true. If not returns false
*/

is_check :: proc(board: map[rune][dynamic]PieceInfo = state.board.piece_map, colour: Colour = state.to_move) -> bool {
  clear(&state.capture_option_files)
  clear(&state.capture_option_ranks)
  for file := 'a'; file <= 'h'; file += 1 {
    for rank: uint = 0; rank <= 7; rank += 1 {
      piece := board[file][rank]

      if piece.colour == colour {
        #partial switch piece.piece {
        case .PAWN:
          get_pawn_moves_and_captures(file, rank, colour)
        case .KNIGHT:
          get_knight_moves_and_captures(file, rank, colour)
        case .BISHOP:
          get_bishop_moves_and_captures(file, rank, colour)
        case .ROOK:
          get_rook_moves_and_captures(file, rank, colour)
        case .QUEEN:
          get_bishop_moves_and_captures(file, rank, colour)
          get_rook_moves_and_captures(file, rank, colour)
        }
      }
    }
  }

  clear(&state.move_option_files)
  clear(&state.move_option_ranks)
  
  for i in 0 ..< len(state.capture_option_files) {
    if board[state.capture_option_files[i]][state.capture_option_ranks[i]].piece == .KING {
      clear(&state.capture_option_files)
      clear(&state.capture_option_ranks)
      return true
    }
  }
  clear(&state.capture_option_files)
  clear(&state.capture_option_ranks)
  return false
}

/*
Checks if the current board state is checkmate.

Loops through all possible moves and captures of the checked player.
If any of those board states result in no check then returns false.
If none of the available moves or captures stop the check then returns true.
*/
is_checkmate :: proc() -> bool {
  original_board := make(map[rune][dynamic]PieceInfo)
  defer delete(original_board)
  copy_board(&original_board, state.board.piece_map)

  if state.to_move == .WHITE {
    state.to_move = .BLACK
    for file := 'a'; file <= 'h'; file += 1 {
      for rank : uint = 0; rank <= 7; rank += 1 {
        piece := state.board.piece_map[file][rank]
        if piece.colour == .BLACK {
          clear(&state.move_option_files)
          clear(&state.move_option_ranks)
          clear(&state.capture_option_files)
          clear(&state.capture_option_ranks)

          #partial switch piece.piece {
          case .PAWN:
            get_pawn_moves_and_captures(file, rank)
          case .KNIGHT:
            get_knight_moves_and_captures(file, rank)
          case .BISHOP:
            get_bishop_moves_and_captures(file, rank)
          case .ROOK:
            get_rook_moves_and_captures(file, rank)
          case .QUEEN:
            get_bishop_moves_and_captures(file, rank)
            get_rook_moves_and_captures(file, rank)
          case.KING:
            get_king_moves_and_captures(file, rank)
          }

          for i in 0 ..< len(state.move_option_files) {
            state.board.piece_map[state.move_option_files[i]][state.move_option_ranks[i]] = piece
            state.board.piece_map[file][rank] = PieceInfo{}

            old_move_files: [dynamic]rune
            old_move_ranks: [dynamic]uint
            old_capture_files: [dynamic]rune
            old_capture_ranks: [dynamic]uint
            copy(old_move_files[:], state.move_option_files[:]) 
            copy(old_move_ranks[:], state.move_option_ranks[:])
            copy(old_capture_files[:], state.capture_option_files[:])
            copy(old_capture_ranks[:], state.capture_option_ranks[:])

            if !is_check(colour = .WHITE) {
              state.to_move = .WHITE
              copy_board(&state.board.piece_map, original_board)
              return false
            }
            copy_board(&state.board.piece_map, original_board)
            copy(state.move_option_files[:], old_move_files[:])
            copy(state.move_option_ranks[:], old_move_ranks[:])
            copy(state.capture_option_files[:], old_capture_files[:])
            copy(state.capture_option_ranks[:], old_capture_ranks[:])
          }

          for i in 0 ..< len(state.capture_option_files) {
            state.board.piece_map[state.capture_option_files[i]][state.capture_option_ranks[i]] = piece
            state.board.piece_map[file][rank] = PieceInfo{}
            
            old_move_files: [dynamic]rune
            old_move_ranks: [dynamic]uint
            old_capture_files: [dynamic]rune
            old_capture_ranks: [dynamic]uint
            copy(old_move_files[:], state.move_option_files[:]) 
            copy(old_move_ranks[:], state.move_option_ranks[:])
            copy(old_capture_files[:], state.capture_option_files[:])
            copy(old_capture_ranks[:], state.capture_option_ranks[:])

            if !is_check(colour = .WHITE) { 
              state.to_move = .WHITE
              copy_board(&state.board.piece_map, original_board)
              return false
            }
            copy_board(&state.board.piece_map, original_board)
            copy(state.move_option_files[:], old_move_files[:])
            copy(state.move_option_ranks[:], old_move_ranks[:])
            copy(state.capture_option_files[:], old_capture_files[:])
            copy(state.capture_option_ranks[:], old_capture_ranks[:])

          }
        }
      }
    }
    state.to_move = .WHITE
  } else {
    state.to_move = .WHITE
    for file := 'a'; file <= 'h'; file += 1 {
      for rank : uint = 0; rank <= 7; rank += 1 {
        piece := state.board.piece_map[file][rank]
        if piece.colour == .WHITE {
          clear(&state.move_option_files)
          clear(&state.move_option_ranks)
          clear(&state.capture_option_files)
          clear(&state.capture_option_ranks)

          #partial switch piece.piece {
          case .PAWN:
            get_pawn_moves_and_captures(file, rank)
          case .KNIGHT:
            get_knight_moves_and_captures(file, rank)
          case .BISHOP:
            get_bishop_moves_and_captures(file, rank)
          case .ROOK:
            get_rook_moves_and_captures(file, rank)
          case .QUEEN:
            get_bishop_moves_and_captures(file, rank)
            get_rook_moves_and_captures(file, rank)
          case.KING:
            get_king_moves_and_captures(file, rank)
          }

          for i in 0 ..< len(state.move_option_files) {
            state.board.piece_map[state.move_option_files[i]][state.move_option_ranks[i]] = piece
            state.board.piece_map[file][rank] = PieceInfo{}
            
            old_move_files: [dynamic]rune
            old_move_ranks: [dynamic]uint
            old_capture_files: [dynamic]rune
            old_capture_ranks: [dynamic]uint
            copy(old_move_files[:], state.move_option_files[:]) 
            copy(old_move_ranks[:], state.move_option_ranks[:])
            copy(old_capture_files[:], state.capture_option_files[:])
            copy(old_capture_ranks[:], state.capture_option_ranks[:])
            
            if !is_check(colour = .BLACK) {
              state.to_move = .BLACK
              copy_board(&state.board.piece_map, original_board)
              return false
            }
            copy_board(&state.board.piece_map, original_board)
            copy(state.move_option_files[:], old_move_files[:])
            copy(state.move_option_ranks[:], old_move_ranks[:])
            copy(state.capture_option_files[:], old_capture_files[:])
            copy(state.capture_option_ranks[:], old_capture_ranks[:])

          }

          for i in 0 ..< len(state.capture_option_files) {
            state.board.piece_map[state.capture_option_files[i]][state.capture_option_ranks[i]] = piece
            state.board.piece_map[file][rank] = PieceInfo{}
            
            old_move_files: [dynamic]rune
            old_move_ranks: [dynamic]uint
            old_capture_files: [dynamic]rune
            old_capture_ranks: [dynamic]uint
            copy(old_move_files[:], state.move_option_files[:]) 
            copy(old_move_ranks[:], state.move_option_ranks[:])
            copy(old_capture_files[:], state.capture_option_files[:])
            copy(old_capture_ranks[:], state.capture_option_ranks[:])

            if !is_check(colour = .BLACK) {
              state.to_move = .BLACK
              copy_board(&state.board.piece_map, original_board)
              return false
            }
            copy_board(&state.board.piece_map, original_board)
            copy(state.move_option_files[:], old_move_files[:])
            copy(state.move_option_ranks[:], old_move_ranks[:])
            copy(state.capture_option_files[:], old_capture_files[:])
            copy(state.capture_option_ranks[:], old_capture_ranks[:])

          }
        }
      }
    }
    state.to_move = .BLACK
  }
  return true
}
*/
