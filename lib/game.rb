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
end