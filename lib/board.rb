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
    # checks for illegal moves, if it is raise an error otherwise execute the move
    # then switch player after a successful move
    validate_move(from, to)
    execute_move(from, to)
    switch_player
    true # indicates successful move
  end

  # Method call for checking if KING is currently in check for both WHITE & BLACK
  def in_check?(color)
    king_pos = find_king(color)
    opponent_color = color == :white ? :black : :white # determing opponent color

    # check through entire opponent pieces if any attacks the king
    grid.each_with_index.any? do |row, i|
      row.each_with_index.any? do |piece, j|
        # skip tiles/square with piece of same color or empty
        next unless piece && piece.color == opponent_color

        # use the piece's #attaks? to check if it attakcs the king's square
        piece.attacks?(self, [i, j], king_pos)
      end
    end
  end

  # checkmate checker
  def checkmate?(color)
    in_check?(color) && no_legal_moves?(color)
  end

  # stalemate checker
  def stalemate?(color)
    !in_check?(color) && no_legal_moves?(color)
  end

  # prepare board state for serialization
  def to_h
    {
      grid: serialized_grid,
      current_player: @current_player,
      en_passant_target: @en_passant_target,
      move_history: serialized_move_history
    }
  end

  # method call for board state restoration from deserialized data
  def self.from_h(data)
    raise InvalidSaveError, 'Invalid save data format (not Hash)' unless data.is_a?(Hash)

    # data validation
    unless data[:grid].is_a?(Array) && data[:grid].all? { |row| row.is_a?(Array) }
      raise InvalidSaveError, "Loaded data 'grid' is not a 2D Array."
    end

    unless [:white, :black].include?(data[:current_player]&.to_sym)
      raise InvalidSaveError, "Loaded data 'current_player' is invalid."
    end

    # create a new board instance
    board = allocate
    board.send(:initialize_from_save, data) # call a custom initialization method

    board
  end
end