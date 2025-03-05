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

get_pawn_moves :: proc() {
  if state.to_move == .WHITE {
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
  } else {
    if state.selected_rank == 6 {
      //If pawn has not yet moved
    } else {
      //Pawn has already moved
    }
  }
}

check_pawn_move :: proc(move: string, state: ^GameState) -> bool {
    to_rank := rune_to_num(cast(rune)move[1])
    rank: u8
    for piece, i in state.board.piece_map[cast(rune)move[0]] {
        if piece.piece == .PAWN  && piece.colour == state.to_move {
            rank = cast(u8)i + 1
        }
    }

    if rank == 0 {
        return false
    }

    if state.move_no == 1 {
        if state.to_move == .WHITE {
            if to_rank - rank == 1 || to_rank - rank == 2 {
                state.board.piece_map[cast(rune)move[0]][to_rank-1] = state.board.piece_map[cast(rune)move[0]][rank-1]
                state.board.piece_map[cast(rune)move[0]][rank-1] = PieceInfo{}
            } else {
                return false
            }
        } else {
            if rank - to_rank == 1 || rank - to_rank == 2 {
                state.board.piece_map[cast(rune)move[0]][to_rank-1] = state.board.piece_map[cast(rune)move[0]][rank-1]
                state.board.piece_map[cast(rune)move[0]][rank-1] = PieceInfo{}
            } else {
                return false
            }
        }
    } else {
        if state.to_move == .WHITE {
            if to_rank - rank == 1 {
                state.board.piece_map[cast(rune)move[0]][to_rank-1] = state.board.piece_map[cast(rune)move[0]][rank-1]
                state.board.piece_map[cast(rune)move[0]][rank-1] = PieceInfo{}
            } else {
                return false
            }
        } else {
            if rank - to_rank == 1 {
                state.board.piece_map[cast(rune)move[0]][to_rank-1] = state.board.piece_map[cast(rune)move[0]][rank-1]
                state.board.piece_map[cast(rune)move[0]][rank-1] = PieceInfo{}
            } else {
                return false
            }
        }
    }
    if state.to_move == .WHITE {
        state.to_move = .BLACK
    } else {
        state.to_move = .WHITE
    }
    return true
}

check_pawn_capture :: proc(move: string, state: ^GameState) -> bool {
    to_rank := rune_to_num(cast(rune)move[1])
    rank: u8

    for piece, i in state.board.piece_map[cast(rune)move[0]] {
        if piece.piece == .PAWN  && piece.colour == state.to_move {
            rank = cast(u8)i + 1
        }
    }

    if rank == 0 {
        return false
    }

    if state.to_move == .WHITE {
        if to_rank - rank == 1 {
            state.board.piece_map[cast(rune)move[2]][to_rank-1] = state.board.piece_map[cast(rune)move[0]][rank-1]
            state.board.piece_map[cast(rune)move[0]][rank-1] = PieceInfo{}
        } else {
            return false
        }
    } else {
        if rank - to_rank == 1 {
            state.board.piece_map[cast(rune)move[2]][to_rank-1] = state.board.piece_map[cast(rune)move[0]][rank-1]
            state.board.piece_map[cast(rune)move[0]][rank-1] = PieceInfo{}
        } else {
            return false
        }
    }
    return true
}

check_rook_move :: proc(move: string, board: ^Board) {

}

rune_to_num :: proc(str: rune) -> u8 {
    runes := [dynamic]rune{}

    append(&runes, str)

    str_val := utf8.runes_to_string(runes[:])

    delete(runes)

    num, _ := strconv.parse_u64(str_val)
    return cast(u8)num
}
