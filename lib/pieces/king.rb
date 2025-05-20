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
  end
end