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
    puts ' ' * VERTICAL.length + '' * (TILE_WIDTH / 2) + header # adjusted spacing
  end

  def print_top_border
    border = CORNER_TL + (HORIZONTAL * TILE_WIDTH * 8) + CORNER_TR
    puts border
  end

  def print_bottom_border
    border = CORNER_BL + (HORIZONTAL * TILE_WIDTH * 8) + CORNER_BR
    puts border
  end

  def construct_row(board_row)
    TILE_HEIGHT.times do |line|
      row_data = 8.times.map do |col|
        background = (board_row + col).even? ? 107 : 100 # use ANSII codes directly
        cell_content(board_row, col, line, background)
      end.join

      # show row number only on mid line
      row_number = line == TILE_HEIGHT / 2 ? " #{ROW_NUMBERS[board_row]}" : ''
      puts "#{VERTICAL}#{row_data}#{VERTICAL}#{row_number}"
    end
  end

  def cell_content(board_row, col, line, background_code)
    text = if line == TILE_HEIGHT / 2
             piece = @board[[board_row, col]]
             piece ? piece.symbol.center(TILE_WIDTH) : ' '.center(TILE_WIDTH)
           else
             ' '.center(TILE_WIDTH)

             # White pieces in bright white (97), black pieces in black (30)
             fg_code = @board[[board_row, col]]&.color == :white ? 97 : 30

             "\e[#{fg_code};#{background_code}m#{text}\e[0m"
           end
  end
end
