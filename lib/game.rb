# frozen_string_literal: true

require_relative 'board'
require_relative 'chess_parser'
require_relative 'board_constructor'
require_relative 'errors'
require 'yaml'
# game logics
class Game
  SAVE_DIR = 'saves' # directory for save files

  def  initialize
    @board = Board.new
    @renderer = BoardConstructor.new(@board)
  end

  # main game loop
  def play
    loop do
      # check end game conditions
      if @board.checkmate?(@board.current_player)
        @renderer.construct_board # show final board
        # if current player is checkmated, opponent wins
        winner_color = @board.opponent_color
        puts "CHECKMATE! #{winner_color.capitalize} wins!"
        break
      elsif @board.stalemate?(@board.current_player)
        @renderer.construct_board
        puts 'STALEMATE! Game drawn.'
        break
      end

      @renderer.construct_board # display current board state
      handle_turn # handles player input and turn logic
    rescue InvalidInputError, InvalidMoveError, CheckError => e
      puts "ERROR: #{e.message}"
    rescue Interrupt # allows quitting with Ctrl + C
      puts "\nGame interrupted. Exiting."
      break
    rescue => e # in case any unexpected error occurs
      puts "An unexpected error occured: #{e.message}"
      puts e.backtrace.join("\n") # for debug purposes
      break # exits the game completely
    end
  end

  # save current game state (YAML)
  def save_game(filename)
    Dir.mkdir(SAVE_DIR) unless Dir.exist?(SAVE_DIR)

    # sanitze filename
    sanitized = filename.gsub(/[^\w-]/, '_').downcase # Allows letters, numbers, underscore, hyphen
    sanitized = sanitized[0..50]
    sanitized = "game_#{Time.now.strftime('%Y%m%d_%H%M%S')}" if sanitized.empty?

    full_path = File.join(SAVE_DIR, "#{sanitized}.yaml")

    begin
      # gets the serialazible data (board)
      board_data = @board.to_h
      # dump
      File.write(full_path, YAML.dump(board_data))
      puts "Game saved SUCESSFULLY to #{full_path}"
    rescue => e
      puts "ERROR saving game to #{full_path}: #{e.message}"
    end
  end

  # load a game state from a YAML file
  def load_game(filename)
    sanitized = filename.gsub(/[^\w-]/, '_').downcase
    sanitized = sanitized[0..50]
    full_path = File.join(SAVE_DIR, "#{sanitized}.yaml")

    unless File.exist?(full_path)
      raise InvalidInputError, "Save file '#{filename}' not found in the '#{SAVE_DIR}' directory."
    end

    # list allowed classes for YAML safe_loading
    permitted_classes = [
      Symbol, Hash, Array, String, Integer, Float, TrueClass, FalseClass, NilClass,
      Pawn, Rook, Knight, Bishop, Queen, King ]
    
    begin
      # read the file
      yaml_string = File.read(full_path)
      # load
      laoded_data = YAML.safe_load(yaml_string, permitted_classes: permitted_classes, aliases: true)

      # use the Board.from_h class method to create a new board instance
      new_board = Board.from_h(laoded_data)
      # replace current board and update the renderer with new board instance
      @board = new_board
      @renderer.update_board(@board)
      puts "Game loaded SUCCESSFULLY! from #{full_path}"
    rescue Psych::DisallowedClass => e
      puts 'SECURITY ERROR: Save file contains invalid or disallowed data. Loading failed.'
      puts e.message
      raise InvalidSaveError, 'Save file contains disallowed classes.'
    rescue InvalidSaveError => e
      # Catch validation errors from Board.from_h or within load_game
      puts 'ERROR LOADING GAME: Invalid save file format.'
      puts e.message
    rescue => e
      puts 'An unexpected error occurred during game loading:'
      puts e.message
      puts e.backtrace.join("\n")
      raise 'Failed to load game due to an unexpected error.'
    end
  end
end