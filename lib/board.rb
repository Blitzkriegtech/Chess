# frozen_string_literal: true

require_relative 'board_renderer'
#  monitors and updates the state of the board
class Board
  include BoardGeneral
  attr_accessor :current_player, :en_passant_target, :grid

  def initialize
    super # Initializes @grid using BoardGeneral(module)
    @move_history = []
    @current_player = :white
    @en_passant_target = nil # Tracks en passant oppotunities
    setup_pieces # Only set up pieces on a new game, not when loading
  end

  # method call for a new game
  def start_new_game
    @grid = Array.new(8) { Array.new(8) } # Reset grid
    @move_history = []
    @current_player = :white
    @en_passant_target = nil
    setup_pieces
  end

  def move_piece(from, to)
    
  end
end