# frozen_string_literal: true

require 'rspec'

RSpec.describe Board do
  subject(:board) { described_class.new }

  describe '#initialize' do
    it 'sets up initial chess board config' do
      expect(board.grid[0][0]).to be_a(Rook)
      expect(board.grid[7][7]).to be_a(Rook)
      expect(board.grid[0][4]).to be_a(King)
    end
  end
end