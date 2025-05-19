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
end