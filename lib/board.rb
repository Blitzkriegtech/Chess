# frozen_string_literal: true

require_relative 'board_general'
require_relative 'errors'
require_relative 'piece'
require_relative 'pieces/bishop'
require_relative 'pieces/king'
require_relative 'pieces/knight'
require_relative 'pieces/pawn'
require_relative 'pieces/queen'
require_relative 'pieces/rook'
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

    unless %i[white black].include?(data[:current_player]&.to_sym)
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

          unless piece_class_name.is_a?(String) && %i[white
                                                      black].include?(color_data&.to_sym) && [true, false,
                                                                                              nil].include?(moved_data)
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
        rescue StandardError => e
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

  # check moves if it is legal accrding to chess rules (excluding checks)
  # this is called by move_piece before executing the move.
  def validate_move(from, to)
    # add bounds checking (from and to)
    unless from.is_a?(Array) && from.length == 2 && from.all? { |coord| coord.between?(0, 7) } &&
           to.is_a?(Array) && to.length == 2 && to.all? { |coord| coord.between?(0, 7) }

      raise InvalidInputError, "Move coordinates are out of bounds/Invalid format: #{from.inspect}-#{to.inspect}"
    end

    piece = self[from] # piece at the starting pos
    raise InvalidMoveError, "No piece at #{from.inspect}" unless piece # piece must be @ 'from'
    raise InvalidMoveError, "It's not your turn. Move a #{current_player} piece." if piece.color != current_player

    valid_moves = piece.valid_moves(self, from)
    # check if the destination is in the list of valid moves for this piece
    unless valid_moves.include?(to)
      target_piece = self[to]
      if target_piece && target_piece.color == piece.color
        raise InvalidMoveError, "Cannot capture your own piece at #{to.inspect}."
      elsif target_piece && target_piece.color != piece.color
        raise InvalidMoveError,
              "Path is blocked or invalid capture for #{piece.class} from #{from.inspect} to #{to.inspect}."
      else # epmty tile/square, but not in valid_moves
        raise InvalidMoveError,
              "Invalid move for #{piece.class} from #{from.inspect} to #{to.inspect}. Destination is not reachable."
      end
    end

    # check the gen. rule: the move must not leave the king in check.
    # includes checking castling rules
    return unless move_leaves_king_in_check?(from, to)

    raise CheckError, 'Move would leave your king in check.'
  end

  # execute a valid move, update the board state and game history
  def execute_move(from, to)
    piece = self[from] # the piece being moved
    captured_piece = self[to] # piece at the point of destination (might be nil)

    # handle en passant capture before moving the attacking pawn
    if piece.is_a?(Pawn) && to == @en_passant_target
      # captured pawn is on the attacker's starting row, at the destination col
      captured_pos = [from[0], to[1]]
      captured_piece = self[captured_pos] # get the captured pawn instance
      self[captured_pos] = nil # remove the captured pawn from the board
    end

    # Handle castling rook movement *before* moving the king, as it's part of the same "move"
    # Check if the piece is a King and it's a 2-square horizontal move (indicative of castling)
    if piece.is_a?(King) && (from[1] - to[1]).abs == 2
      perform_castling_rook_move(from, to) # move the rook during castling
    end

    # move the main piece on the board
    move_chess_piece!([from, to]) # updates the grid
    self[to].marked_move # marks the piece as moved ( now at the 'to' tile/square )

    # Check for pawn promotion *after* the move is executed
    # If the piece at the destination is a pawn and reached the opposite back rank, promote it.
    promote_pawn(to)

    # update move history
    @move_history << {
      from: from,
      to: to,
      piece: piece.class.name,
      color: piece.color,
      captured: captured_piece&.class&.name,
      en_passant_target_before: @en_passant_target,
      # flag if this move was a castling move
      castling: piece.is_a?(King) && (from[1] - to[1]).abs == 2
    }

    # Update en passant target *after* the current move.
    # The target is only set if a pawn moves two squares.
    @en_passant_target = nil # reset the target @ the start of the next turn
    return unless self[to].is_a?(Pawn) && (from[0] - to[0]).abs == 2

    @en_passant_target = [(from[0] + to[0]) / 2, from[1]]
  end

  def perform_castling_rook_move(king_from, king_to)
    row = king_from[0]
    # determine rook's start and end pos based on king's to
    if king_to[1] == 6 # kingside castling
      rook_from = [row, 7]
      rook_to = [row, 5]
    elsif king_to[1] == 2 # queenside castling
      rook_from = [row, 0]
      rook_to = [row, 3]
    else
      puts "WARNING: perform_castling_rook_move called for non-castling king move #{king_from}-#{king_to}."
      return # do nothing if it's not a recognized castling move
    end

    rook = self[rook_from]
    # double check that there is a rook at the expected position
    unless rook.is_a?(Rook)
      puts "ERROR: Expected a rook at #{rook_from.inspect} for castling, but found #{rook.inspect}."
      return
    end

    # move the rook using the general move method
    move_chess_piece!([rook_from, rook_to])
    # mark the moved rook
    self[rook_to].marked_move
  end

  # handles pawn promotion logic
  def promote_pawn(position)
    pawn = self[position]
    return unless pawn.is_a?(Pawn)

    # determine the promotion rank based on the pawn's color
    promotion_rank = pawn.color == :white ? 0 : 7
    return unless position[0] == promotion_rank # ensure it's on the correct end rank

    puts "Pawn promotion! Your #{pawn.color.capitalize} pawn at #{algebraic_coord(position)} can be promoted."
    puts 'Choose piece (Q)ueen, (R)ook, (B)ishop, (N)Knight:'

    piece_class = nil
    loop do
      print 'Enter choice (Q, R, B, N): '
      choice = gets&.chomp&.upcase

      # handle empty input or Ctrl+D (default to quenn)
      if choice.nil? || choice.empty?
        puts 'No input received. Defaulting to Queen.'
        piece_class = Queen
        break
      end

      case choice
      when 'Q', 'q', 'queen', 'Queen', 'QUEEN'
        piece_class = Queen
        break
      when 'R', 'r', 'rook', 'ROOK', 'Rook'
        piece_class = Rook
        break
      when 'B', 'b', 'bishop', 'Bishop', 'BISHOP'
        piece_class = Bishop
        break
      when 'N', 'n', 'knight', 'KNIGHT', 'Knight'
        piece_class = Knight
        break
      when 'K', 'k', 'King', 'king', 'KING'
        puts 'Cannot promote to a King. Please choose Q, R, B, or N.'
        next
      else
        puts "Invalid choice '#{choice}'. Please choose Q, R, B, or N."
        next
      end
    end

    # Replace the pawn with the new piece of the same colo
    self[position] = piece_class.new(pawn.color)
    puts "Pawn at #{algebraic_coord(position)} promoted to #{piece_class.name}!"
  end

  # convert board coordinates [row, col] ot algebraic notation
  def algebraic_coord(position)
    row, col = position

    return nil unless row.between?(0, 7) && col.between?(0, 7)

    column_letter = ('a'.ord + col).chr
    row_number = 8 - row
    "#{column_letter}#{row_number}"
  end

  # Check if the current player has any legal moves
  def no_legal_moves?(color)
    grid.each_with_index.all? do |row_pieces, i|
      row_pieces.each_with_index.all? do |piece, j|
        # skip if tile is empty or has opponent's color
        next true unless piece && piece.color == color

        from = [i, j]

        piece.valid_moves(self, from).none? do |to|
          !move_leaves_king_in_check?(from, to)
        end
      end
    end
  end

  def move_leaves_king_in_check?(from, to)
    # create a deep copy of the board state to simulate the move w/o affecting the actual board
    begin
      test_board_grid = Marshal.load(Marshal.dump(@grid))
    rescue StandardError => e
      puts "Error creating deep copy of grid using Marshal: #{e.message}."
      raise 'Failed to create test board copy for check validation.'
    end

    test_board = Board.allocate
    test_board.instance_variable_set(:@grid, test_board_grid)
    test_board.instance_variable_set(:@current_player, @current_player)
    test_board.instance_variable_set(:@en_passant_target, @en_passant_target)

    test_piece = test_board[from]
    unless test_piece
      puts "WARNING: move_leaves_king_in_check? called with no piece at simulation 'from' position #{from.inspect}"
      return true
    end

    # 1. Simulate en passant capture if applicable *before* moving the attacking pawn.
    if test_piece.is_a?(Pawn) && to == test_board.en_passant_target
      captured_pos = [from[0], to[1]]
      test_board[captured_pos] = nil # remove the captured pawn in the simulation
    end

    # 2. Simulate castling rook movement if applicable *before* moving the king.
    # Check if the piece is a King and the move is a 2-square horizontal move (indicative of castling).
    if test_piece.is_a?(King) && (from[1] - to[1]).abs == 2
      row = from[0] # King's rank
      if to[1] == 6 # Kingside castling
        rook_from = [row, 7]
        rook_to = [row, 5]
      elsif to[1] == 2 # Queenside castling
        rook_from = [row, 0]
        rook_to = [row, 3]
      else
        # Should not happen if King#valid_moves is correct, but a safeguard.
        puts "WARNING: Simulation of castling called for non-castling king move #{from.inspect}-#{to.inspect}"
        # Continue simulation without moving a rook if it's not a standard castling destination.
        rook_from = nil # Ensure rook move is skipped
      end

      # Simulate the rook move on the test board if rook positions were determined
      if rook_from && rook_to
        test_rook = test_board[rook_from]
        if test_rook.is_a?(Rook) # Ensure there's actually a rook to move in simulation
          test_board[rook_to] = test_rook
          test_board[rook_from] = nil
        else
          puts "WARNING: Simulation expected a rook at #{rook_from.inspect} for castling but found #{test_rook.inspect}."
          # Continue simulation, but the castling visual/logic might be off.
        end
      end
    end

    # 3. Simulate the main piece movement (King or other piece).
    test_board.move_chess_piece!([from, to])

    # --- Check if the king is in check on the test board after the simulated move ---
    test_board.in_check?(@current_player)
  end

  def find_king(color)
    grid.each_with_index do |row, i|
      row.each_with_index do |piece, j|
        return [i, j] if piece.is_a?(King) && piece.color == color
      end
    end
    raise "Error: No #{color} king found on the board. Invalid game state."
  end

  def switch_player
    @current_player = @current_player == :white ? :black : :white
  end

  # Check if a given square [row, col] is currently under attack by the specified attacker color.
  # This method is used for check/checkmate detection and castling validation.
  # This method is public because Piece instances need to call it to validate moves.

  public

  def square_under_attack?(position, attacker_color)
    unless position.is_a?(Array) && position.length == 2 && position.all? { |coord| coord.between?(0, 7) }
      puts "WARNING: square_under_attack? called with invalid position: #{position.inspect}"
      return false # an invalid pos cannot be under attack
    end

    grid.each_with_index.any? do |row, i|
      row.each_with_index.any? do |piece, j|
        next unless piece && piece.color == attacker_color

        piece.attacks?(self, [i, j], position)
      end
    end
  end

  # Determine the opponent's color based on the current player
  def opponent_color
    current_player == :white ? :black : :white
  end
end
