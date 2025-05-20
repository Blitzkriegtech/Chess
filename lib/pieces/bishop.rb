# frozen_string_literal: true

# subclass bishop piece
class Bishop < Piece
  def symbol
    color == :white ? "\u2657" : "\u265D"
  end

  def valid_moves(board, from)
    moves = []
    directions = [[1, 1], [1, -1], [-1, 1], [-1, -1]]
    directions.each do |dr, dc|
      row, col = from
      loop do
        row += dr
        col += dc
        break unless row.between?(0,7) && col.between?(0, 7)

        target_piece = board[[row, col]]
        if target_piece.nil?
          moves << [row, col]
        elsif target_piece.color != color
          moves << [row, col]
          break
        else
          break
        end
      end
    end
    moves
  end

  def attacks?(board, from, target)
    row, col = from
    target_row, target_col = target

    return false unless (row - target_row).abs == (col - target_col).abs

    step_row = row < target_row ? 1 : -1
    step_col = col < target_col ? 1 : -1

    row += step_row
    col += step_col

    while (row != target_row) || (col != target_col)
      return false unless board[[row, col]].nil?

      row += step_row
      col += step_col
    end
    true
  end
end