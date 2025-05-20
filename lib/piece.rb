# frozen_string_literal: true

# parent class for chess pieces
class Piece
  attr_reader :color # black or white
  attr_accessor :moved # boolean, move tracker

  def initialize(color)
    unless [:white, :black].include?(color)
      raise ArgumentError, "Invalid piece color: #{color}. Must be :white or :black."
    end
    @color = color
    @moved = false # pieces start unmoved
  end

  def mark_moved
    @moved = true
  end

  # abstract methods
  # This method does *not* consider if the move leaves the king in check.
  def symbol
    raise NotImplementedError, "#{self.class} must implement the 'symbol' method."
  end

  def valid_moves(_board, _from)
    raise NotImplementedError,"#{self.class} must implement the 'valid_moves' method."
  end

  def attacks?(_board, _from, _target)
    raise NotImplementedError, "#{self.class} must implement the 'attacks?' method."
  end
end