# frozen_string_literal: true

# subclass knight piece
class Knight < Piece
  def symbol
    color == :white ? "\u2658" : "\u265E"
  end

  def valid_moves(board, from)
    row, col = from
    moves = []

    knight_moves = [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]]
    knight_moves.each do |dr, dc|
      new_row, new_col = row + dr, col + dc
      next unless new_row.between?(0, 7) && new_col.between?(0, 7)

      target_piece = board[[new_row, new_col]]
      moves << [new_row, new_col] unless target_piece&.color == color
    end
    moves
  end

  def attacks?(_board, from, target)
    row, col = from
    target_row, target_col = target
    (row - target_row).abs == 2 && (col - target_col).abs == 1 ||
      (row - target_row).abs == 1 && (col - target_col).abs == 2
  end
end