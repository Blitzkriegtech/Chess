# frozen_string_literal: true

# parent class for chess pieces
class Piece
  attr_reader :color # black or white
  attr_accessor :moved # boolean, move tracker

  def initialize(color)
    
  end
end