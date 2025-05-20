# frozen_string_literal: true

# subclass king piece
class King < Piece
  def symbol
    color == :white ? "\u2654" : "\u265A"
  end

  def valid_moves(board, from)
    row, col = from
    moves = []

    # strd adjacent moves
    (-1..1).each do |i|
      (-1..1).each do |j|
        next if i == 0 && j == 0 # skip current pos

        new_row, new_col = row + i, col + j
        next unless new_row.between?(0, 7) && new_col.between?(0, 7) # check bounds

        target_piece = board[[new_row, new_col]]
        # add move if target square is empty or occupied by an opponent's piece
        moves << [new_row, new_col] unless target_piece&.color == color
      end
    end

    # castling
    # king must not have moved
    unless moved
      # checks the row for castling (rank 1 for black, rank 8 for white)
      castling_row = color == :white ? 7 : 0

      # kingside castle
      kingside_rook_pos = [castling_row, 7]
      kingside_rook = board[kingside_rook_pos] # get the piece @ rook's pos

      # check if kingside rook exists, is a Rook, and has not moved
      if kingside_rook.is_a?(Rook) && !kingside_rook.moved
        # check if tiles/squares are empty in betweem king and rook
        if board[[castling_row, 5]].nil? && board[[castling_row, 6]].nil?
          # check if king is currently checked, or passes through or lands on an attacked square
          unless board.square_under_attack?([castling_row, 4], board.opponent_color) || # king's initial pos
                        board.square_under_attack?([castling_row, 5], board.opponent_color) || # where king moves through
                        board.square_under_attack?([castling_row, 6], board.opponent_color) # where king lands on
                        moves << [castling_row, 6]
          end 
        end
      end

      # queenside castle
      queenside_rook_pos = [castling_row, 0]
      queenside_rook = board[queenside_rook_pos]

      if queenside_rook.is_a?(Rook) && !queenside_rook.moved
        if board[[castling_row, 1]].nil? && board[[castling_row, 2]].nil? && board[[castling_row, 3]].nil?
          unless board.square_under_attack?([castling_row, 4], board.opponent_color) || # king's initial pos
            board.square_under_attack?([castling_row, 3], board.opponent_color) ||
            board.square_under_attack?([castling_row, 2], board.opponent_color)
            moves << [castling_row, 2]
          end
        end
      end
    end
    moves # return the list of valid moves
  end

  def attacks?(_board, from, target)
    row, col = from
    target_row, target_col = target
    # king attacks any adjacent square
    (row - target_row).abs <= 1 && (col - target_col).abs <= 1
  end
end