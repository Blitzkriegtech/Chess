# frozen_string_literal: true

# module
module BoardGeneral
  def initialize
    @grid = Array.new(8) { Array.new(8) }
  end

  def [](position)
    row, col = position
    # bound checking
    return nil unless row.between?(0, 7) && col.between?(0, 7)

    @grid[row][col]
  end
end