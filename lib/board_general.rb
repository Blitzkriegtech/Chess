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

  def []=(position, value)
    row, col = position
    @grid[row][col] = value
  end

  def move_chess_piece!(move)
    from, to = move
    # bound checking
    unless from.is_a?(Array) && from.length == 2 && from.all? { |coord| coord.between?(0, 7) } &&
      to.is_a?(Array) && to.length == 2 && to.all? { |coord| coord.between?(0, 7) }
      raise ArgumentError, "Invalid move format or out of bounds: #{move.inspect}"
    end

    piece = self[from]
    # ensure there is a piece at the from pos before attempting to move
    raise InvalidMoveError, "No piece at from position #{from}" if piece.nil?

    self[to] = piece # move the piece
    self[from] = nil # empty the from tile/square
  end
end