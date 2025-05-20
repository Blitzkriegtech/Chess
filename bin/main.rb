#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/game'
require_relative '../lib/how_to_play'

HowToPlay.banner
loop do
  puts "\nWELCOME! PLAYERS!"
  puts "\nGAME OPTIONS:"
  puts '[1] New Game'
  puts '[2] Load Game'
  puts '[3] How to Play'
  puts '[4] QUIT'

  choice = gets&.chomp

  if choice.nil? || choice.empty?
    puts "\nEXITING GAME"
    exit
  end

  case choice.strip
  when '1'
    puts "Commencing new game... ... ... . . "
    game = Game.new
    game.play
    break
  when '2'
    print 'Enter saved file name to continue: '
    filename = gets&.chomp
    if filename.nil? || filename.empty?
      puts 'NO FILENAME entered. Return to game menu.'
      next
    end

    begin
      game = Game.new
      game.load_game(filename)
      game.play
      break
    rescue InvalidInputError, InvalidSaveError => e
      puts "ERROR LOADING GAME: #{e.message}"
    rescue => e
      puts "An unexpected error occurred during loading: #{e.message}"
      puts e.backtrace.join("\n")
    end
  when '3'
    puts "\n"
    HowToPlay.instructions
  when '4'
    puts 'EXITING GAME. BYE!'
    exit
  else
    puts 'INVALID CHOICE. Please enter a number between 1 and 4.'
  end
end