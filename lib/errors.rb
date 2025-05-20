# frozen_string_literal: true

# custom error classes for chess game
class ChessError < StandardError
  # Base class for game-specific errors
end

class InvalidMoveError < ChessError
  # Raised when a move is invalid according to chess rules (excluding check)
end

class CheckError < InvalidMoveError
  # Raised when a move would leave the king in check
end

class InvalidInputError < ChessError
  # Raised when user input format is incorrect or refers to non-existent items
end

class InvalidSaveError < ChessError
  # Raised when a save file is corrupted or has an unexpected format
end