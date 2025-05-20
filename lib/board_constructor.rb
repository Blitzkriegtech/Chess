# frozen_string_literal: true

# board renderer class
class BoardConstructor
  attr_reader :board

  def initialize(board)
    @board = board
  end

  # update the board instance (used after loading)
  def update_board(new_board)
    @board = new_board
  end

  # constants for constructing the board
  COL_LETTERS = [*('a'..'h')].freeze
  ROW_NUMBERS = [*('1'..'8')].reverse.freeze
  TILE_WIDTH = 8
  TILE_HEIGHT = 3
  VERTICAL = '│'
  HORIZONTAL = '─'
  CORNER_TL = '┌'
  CORNER_TR = '┐'
  CORNER_BL = '└'
  CORNER_BR = '┘'

  def construct_board
    print_col_letters
    print_top_border
    8.times { |row| construct_row(row) }
    print_bottom_border
    print_col_letters
  end

  private

  def print_col_letters
    header = COL_LETTERS.map { |ltr| ltr.center(TILE_WIDTH) }.join
    puts ' ' * (VERTICAL.length) + '' * (TILE_WIDTH / 2) + header # adjusted spacing
  end

  def print_top_border
    border = CORNER_TL + (HORIZONTAL * TILE_WIDTH) + CORNER_TR
    puts border
  end

  def print_bottom_border
    border = CORNER_BL + (HORIZONTAL * TILE_WIDTH) + CORNER_BR
    puts border
  end
end