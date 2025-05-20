# frozen_string_literal: true

# subclass pawn piece
class Pawn < Piece
  def symbol
    color == :white ? "\u2659" : "\u265F"
  end

  def valid_moves(board, from)
    row, col = from
    moves = []
    direction = color == :white ? -1 : 1
    start_row = color == :white ? 6 : 1

    # move one square forward
    new_row = row + direction
    if new_row.between?(0, 7) && board[[new_row, col]].nil?
      moves << [new_row, col]

      # move two tiles/squares forward from start pos
      new_row2 = row + 2 * direction
      if row == start_row && board[[new_row2, col]].nil? && board[[new_row, col]].nil? # must not jump over a piece
        moves << [new_row2, col]
      end
    end

    # diagonal capture
    [-1, 1].each do |side|
      new_col = col + side
      next unless new_col.between?(0, 7)

      capture_row = row + direction
      next unless capture_row.between?(0, 7)

      target_piece = board[[capture_row, new_col]]
      if target_piece && target_piece.color != color
        moves << [capture_row, new_col]
      end

      # en passant
      if board.en_passant_target && [capture_row, new_col] == board.en_passant_target
        # check if enemy pawn exists directly beside current pawn on current row
        en_passant_pawn_pos = [row, new_col] # pos of the enemy pawn being captured
        captured_pawn = board[en_passant_pawn_pos]
        if captured_pawn.is_a?(Pawn) && captured_pawn.color != color # Ensure it's an opponent pawn eligible for en passant
          moves << [capture_row, new_col]
        end
      end
    end
    moves
  end

  def attacks?(_board, from, target)
    row, col = target
    target_row, target_col = target
    direction = color == :white ? -1 : 1
    (target_row == row + direction) && (target_col == col + 1 || target_col == col - 1)
  end
end