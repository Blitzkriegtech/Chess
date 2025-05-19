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

  # initialization method for loading
  def initialize_from_save
    # initialize instance variables directly from loaded data
    @move_history = []
    @current_player = data[:current_player]
    @en_passant_target = data[:en_passant_target]

    # restore grid and move history
    restore_grid(data[:grid])
    restore_move_history(data[:move_history]) # pass here the loaded raw data
  end

  # restore grid from serialized data
  def restore_grid(grid_data)
    # 2D arry checker
    unless grid_data.is_?(Array) && grid_data.all? { |row| row.is_a?(Array) }
      puts "WARNING: Invalid grid data format. Expected 2D Array. \nResetting grid."
      @grid = Array.new(8) { Array.new(8) }
      return
    end

    @grid = Array.new(8) { Array.new(8) } # Re-initialize grid with empty squares

    grid.data.each_with_index do |row, i|
      row.each_with_index do |piece_data, j|
        next unless piece_data.is_a?(Hash) # skips nil or non-hash entries

        begin
          piece_class_name = piece_data[:class]
          color_data = piece_data[:color]
          moved_data = piece_data[:moved]

          unless piece_class_name.is_a?(String) && [:white, :black].include?(color_data&.to_sym) && [true, false, nil].include?(moved_data)
            puts "WARNING: Skipping invalid piece data format at #{[i, j]}: #{piece_data.inspect}"
            self[[i, j]] = nil
            next
          end

          # safely get the class constant using Object.const_get
          piece_class = Object.const_get(piece_class_name)

          unless piece_class.is_a?(Class) && piece_class.ancestors.include?(Piece)
            puts "WARNING: Invalid piece class name '#{piece_class_name}' at #{[i, j]} - not a valid Piece class."
            self[[i, j]] = nil
            next
          end

          # create the piece instance
          piece = piece_class.new(color_data.to_sym)

          # restore 'moved' state with default value of false if nil or not true
          piece.moved = moved_data == true # only set to true if it was explicitly true
            
          selfp[[i, j]] = piece # place the restored piece on the board
        
        rescue NameError
        puts "ERROR: Invalid piece class name '#{piece_class_name}' at #{[i, j]}. Piece skipped."
        self[[i, j]] = nil
        rescue => e 
          puts "ERROR restoring piece at #{[i, j]}: #{e.message}. Piece skipped."
          puts e.backtrace.join("\n") # Log backtrace for debuggin purposes
          self[[i, j]] = nil # ensures board doesn't get corrupted
        end  
      end
    end
  end

  # restore move history from serialized data
  def restore_move_history(move_history_data)
    # check the input if its array, default to empty if nil
    unless move_history_data.nil? || move_history_data.is_a?(Array)
      puts "WARNING: Invalid move history data format. Expected Array or nil, got #{move_history_data.class}.\nResseting history."
      @move_history = []
      return
    end
    
    @move_history = (move_history_data || []).map do |move|
      unless move.is_a?(Hash)
        puts "WARNING: Skipping invalid move history entry formate: #{move.inspect}"
        next nil # Skipt invalid entries
      end

      # restore the hash, ensuring color is a symbol if present
      restored_move = move.dup # create copy to avoid modifying the original data
      restored_move[:color] = restored_move[:color]&.to_sym

      restored_move
    end.compact # remove any nil entries resulting from skipping invalid ones
  end

  # prepare grid for serialization
  def serialized_grid
    @grid.map do |row|
      row.map do |piece|
        next unless piece # keep nil entries for empty tiles/squares

        {
          class: piece.class.name, # store class name as str
          color: piece.color, # store color symbol (:white or :black)
          moved: piece.moved # store moved state boolean
        }
      end
    end
  end

  def serialized_move_history
    @move_history # stores serializable data ( data of hashes )
  end

  private

  def setup_pieces
    # Rank & Filers
    8.times do |col|
      self[[1, col]] = Pawn.new(:black)
      self[[6, col]] = Pawn.new(:white)
    end

    # Executives
    back_row_classes = [Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook]
    back_row_classes.each_with_index do |piece_class, col|
      self[[0, col]] = piece_class.new(:black) # row 0
      self[[7, col]] = piece_class.new(:white) # row 7
    end
  end
end