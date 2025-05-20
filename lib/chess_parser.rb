# frozen_string_literal: true

# parser class
class ChessParser
  def self.parse(input)
    case input.strip
    when /\A([a-h][1-8])-([a-h][1-8])\z/i # case-insensitivity added
      { command: :move, from: algebraic_to_coords(Regexp.last_match(1)), to: algebraic_to_coords(Regexp.last_match(2)) }
    when /\Asave\s+(\w+)\z/i # case-insensitivity added
      { command: :save, filename: Regexp.last_match(1) }
    when /\Aload\s+(\w+)\z/i # Added case-insensitivity
      { command: :load, filename: Regexp.last_match(1) }
    else
      raise InvalidInputError, 'Invalid input format. Use "e2-e4", "save <name>", or "load <name>".'
    end
  rescue InvalidInputError # re-raise specific error
    raise
  rescue => e # just in case there are any parsing errors
    puts "Error parsing input: #{e.message}"
    raise InvalidInputError, 'An unexpected error occured during input parsing.'
  end

  def self.algebraic_to_coords(position)
    col = position[0].downcase.ord - 'a'.ord # ensuring lowercase for calculation
    row = 8 - position[1].to_i
    [row, col]
  end
end