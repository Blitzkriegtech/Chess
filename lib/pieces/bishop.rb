# frozen_string_literal: true

# subclass bishop piece
class Bishop < Piece
  def symbol
    color == :white ? "\u2657" : "\u265D"
  end
end