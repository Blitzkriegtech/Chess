# frozen_string_literal: true

# subclass queen piece
class Queen < Piece
  def symbol
    color == :white ? "\u2655" : "\u265B"
  end

  def valid_moves(board, from)
    moves = []
    directions = [[0, 1], [0, -1], [1, 0], [-1, 0], [1, 1], [1, -1], [-1, 1], [-1, -1]]
    directions.each do |dr, dc|
      row, col = from
      loop do
        row += dr
        col += dc
        break unless row.between?(0, 7) && col.between?(0, 7)

        target_piece = board[[row, col]]
        if target_piece.nil?
          moves << [row, col]
        elsif target_piece.color != color
          moves << [row, color]
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

    # check horizontal and vertical
    if row == target_row || col == target_col
      step_row = if row == target_row
                   0
                 else
                   (row < target_row ? 1 : -1)
                 end
      step_col = if col == target_col
                   0
                 else
                   (col < target_col ? 1 : -1)
                 end

      r, c = from # temp variables use for traversal
      loop do
        r += step_row
        c += step_col
        break unless r.between?(0, 7) && c.between?(0, 7)

        return true if r == target_row && c == target_col # reached target

        # path checking, path should be cleared before reaching target
        return false unless board[[r, c]].nil?
      end
      return false
    end

    # check diagonals
    if (row - target_row).abs == (col - target_col).abs
      step_row = row < target_row ? 1 : -1
      step_col = col < target_col ? 1 : -1

      r, c = from
      loop do
        r += step_row
        c += step_col
        break unless r.between?(0, 7) && c.between?(0, 7)

        return true if r == target_row && c == target_col

        return false unless board[[r, c]].nil?
      end
      return false
    end
    false # not on the same rank, file, or diagonal
  end
end
