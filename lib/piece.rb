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

  def symbol
    raise NotImplementedError, "#{self.class} must implement the 'symbol' method."
  end
end