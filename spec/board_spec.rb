# frozen_string_literal: true

# spec/chess_game_spec.rb
require 'spec_helper'

RSpec.describe 'Chess Game' do
  describe Board do
    let(:board) { Board.new }

    describe '#initialize' do
      it 'creates an 8x8 grid' do
        grid = board.instance_variable_get(:@grid)
        expect(grid.length).to eq(8)
        expect(grid.all? { |row| row.length == 8 }).to be true
      end

      it 'places pieces in their correct starting positions' do
        expect(board[[0, 0]]).to be_a(Rook)
        expect(board[[0, 1]]).to be_a(Knight)
        expect(board[[0, 2]]).to be_a(Bishop)
        expect(board[[0, 3]]).to be_a(Queen)
        expect(board[[0, 4]]).to be_a(King)
        expect(board[[0, 5]]).to be_a(Bishop)
        expect(board[[0, 6]]).to be_a(Knight)
        expect(board[[0, 7]]).to be_a(Rook)

        8.times { |col| expect(board[[1, col]]).to be_a(Pawn) }

        (2..5).each do |row|
          8.times { |col| expect(board[[row, col]]).to be_nil }
        end

        8.times { |col| expect(board[[6, col]]).to be_a(Pawn) }

        expect(board[[7, 0]]).to be_a(Rook)
        expect(board[[7, 1]]).to be_a(Knight)
        expect(board[[7, 2]]).to be_a(Bishop)
        expect(board[[7, 3]]).to be_a(Queen)
        expect(board[[7, 4]]).to be_a(King)
        expect(board[[7, 5]]).to be_a(Bishop)
        expect(board[[7, 6]]).to be_a(Knight)
        expect(board[[7, 7]]).to be_a(Rook)
      end

      it 'sets the current player to white' do
        expect(board.current_player).to eq(:white)
      end

      it 'initializes en_passant_target to nil' do
        expect(board.en_passant_target).to be_nil
      end

      it 'initializes move_history as an empty array' do
        expect(board.instance_variable_get(:@move_history)).to eq([])
      end
    end

    describe '#move_piece' do
      before do
        @custom_board = Board.new
        8.times { |r| 8.times { |c| @custom_board[[r, c]] = nil } }
        @custom_board[[4, 4]] = Pawn.new(:white) # White pawn at e4
        @custom_board[[3, 3]] = Bishop.new(:black) # Black bishop at d5
        @custom_board[[0, 0]] = Rook.new(:white) # White rook at a8
        @custom_board[[7, 4]] = King.new(:white) # White king at e1
        @custom_board[[0, 4]] = King.new(:black) # Black king at e8
        @custom_board.current_player = :white
      end

      it 'moves a piece from the start to the end position' do
        pawn_pos = [4, 4] # e4
        target_pos = [3, 4] # e5
        pawn = @custom_board[pawn_pos]

        @custom_board.move_piece(pawn_pos, target_pos)

        expect(@custom_board[pawn_pos]).to be_nil
        expect(@custom_board[target_pos]).to eq(pawn)
      end

      it "captures an opponent's piece at the destination" do
        @custom_board[[4, 4]] = Queen.new(:white) # White queen at e4
        queen_pos = [4, 4]
        bishop_pos = [3, 3] # d5
        queen = @custom_board[queen_pos]

        @custom_board.move_piece(queen_pos, bishop_pos)

        expect(@custom_board[queen_pos]).to be_nil
        expect(@custom_board[bishop_pos]).to eq(queen)
      end

      it 'raises InvalidMoveError if there is no piece at the start position' do
        empty_pos = [5, 5]
        target_pos = [4, 5]
        expect { @custom_board.move_piece(empty_pos, target_pos) }.to raise_error(InvalidMoveError, /No piece at/)
      end

      it 'raises InvalidMoveError if the piece belongs to the wrong color' do
        black_bishop_pos = [3, 3]
        target_pos = [4, 4]
        # Adjusted regex to match the actual error message
        expect do
          @custom_board.move_piece(black_bishop_pos,
                                   target_pos)
        end.to raise_error(InvalidMoveError, /It's not your turn\. Move a white piece\./)
      end

      it "raises InvalidMoveError if the move is not in the piece's valid_moves" do
        pawn_pos = [4, 4]
        invalid_target = [4, 5]
        expect { @custom_board.move_piece(pawn_pos, invalid_target) }.to raise_error(InvalidMoveError, /Invalid move/)
      end

      it 'raises CheckError if the move leaves the king in check' do
        check_board = Board.new
        check_board.instance_variable_set(:@grid, Array.new(8) { Array.new(8) })
        white_king_pos = [7, 4]
        white_rook_pos = [7, 0]
        black_rook_pos = [0, 4]
        check_board[white_king_pos] = King.new(:white)
        check_board[white_rook_pos] = Rook.new(:white)
        check_board[black_rook_pos] = Rook.new(:black)
        check_board.current_player = :white

        move_that_causes_check = [white_rook_pos, [6, 0]]

        expect do
          check_board.move_piece(move_that_causes_check[0],
                                 move_that_causes_check[1])
        end.to raise_error(CheckError, /leave your king in check/)
      end

      it 'switches the current player after a valid move' do
        initial_player = @custom_board.current_player
        pawn_pos = [4, 4]
        target_pos = [3, 4]

        @custom_board.move_piece(pawn_pos, target_pos)

        expect(@custom_board.current_player).to eq(:black)
      end

      it 'marks the moved piece as moved' do
        pawn_pos = [4, 4]
        target_pos = [3, 4]
        pawn = @custom_board[pawn_pos]

        expect(pawn.moved).to be false

        @custom_board.move_piece(pawn_pos, target_pos)

        expect(@custom_board[target_pos].moved).to be true
      end
    end

    describe 'Special Moves' do
      before do
        @special_move_board = Board.new
        @special_move_board.instance_variable_set(:@grid, Array.new(8) { Array.new(8) })
        @special_move_board.current_player = :white
      end

      describe 'Castling' do
        it 'allows kingside castling when conditions are met' do
          white_king_pos = [7, 4]
          white_kingside_rook_pos = [7, 7]
          @special_move_board[white_king_pos] = King.new(:white)
          @special_move_board[white_kingside_rook_pos] = Rook.new(:white)
          @special_move_board[[7, 5]] = nil
          @special_move_board[[7, 6]] = nil
          @special_move_board[[0, 4]] = King.new(:black)

          castling_move = [white_king_pos, [7, 6]]

          king = @special_move_board[white_king_pos]
          expect(king.valid_moves(@special_move_board, white_king_pos)).to include([7, 6])

          @special_move_board.move_piece(castling_move[0], castling_move[1])

          expect(@special_move_board[[7, 6]]).to be_a(King)
          expect(@special_move_board[[7, 5]]).to be_a(Rook)
          expect(@special_move_board[white_king_pos]).to be_nil
          expect(@special_move_board[white_kingside_rook_pos]).to be_nil

          expect(@special_move_board[[7, 6]].moved).to be true
          expect(@special_move_board[[7, 5]].moved).to be true
        end

        it 'allows queenside castling when conditions are met' do
          white_king_pos = [7, 4]
          white_queenside_rook_pos = [7, 0]
          @special_move_board[white_king_pos] = King.new(:white)
          @special_move_board[white_queenside_rook_pos] = Rook.new(:white)
          @special_move_board[[7, 1]] = nil
          @special_move_board[[7, 2]] = nil
          @special_move_board[[7, 3]] = nil
          @special_move_board[[0, 4]] = King.new(:black)

          castling_move = [white_king_pos, [7, 2]]

          king = @special_move_board[white_king_pos]
          expect(king.valid_moves(@special_move_board, white_king_pos)).to include([7, 2])

          @special_move_board.move_piece(castling_move[0], castling_move[1])

          expect(@special_move_board[[7, 2]]).to be_a(King)
          expect(@special_move_board[[7, 3]]).to be_a(Rook)
          expect(@special_move_board[white_king_pos]).to be_nil
          expect(@special_move_board[white_queenside_rook_pos]).to be_nil

          expect(@special_move_board[[7, 2]].moved).to be true
          expect(@special_move_board[[7, 3]].moved).to be true
        end

        it 'does not allow castling if the king has moved' do
          white_king_pos = [7, 4]
          white_kingside_rook_pos = [7, 7]
          king = King.new(:white)
          king.mark_moved
          @special_move_board[white_king_pos] = king
          @special_move_board[white_kingside_rook_pos] = Rook.new(:white)
          @special_move_board[[7, 5]] = nil
          @special_move_board[[7, 6]] = nil
          @special_move_board[[0, 4]] = King.new(:black)

          castling_move = [white_king_pos, [7, 6]]

          king = @special_move_board[white_king_pos]
          expect(king.valid_moves(@special_move_board, white_king_pos)).not_to include([7, 6])
          expect { @special_move_board.move_piece(castling_move[0], castling_move[1]) }.to raise_error(InvalidMoveError)
        end

        it 'does not allow castling if the rook has moved' do
          white_king_pos = [7, 4]
          white_kingside_rook_pos = [7, 7]
          rook = Rook.new(:white)
          rook.mark_moved
          @special_move_board[white_king_pos] = King.new(:white)
          @special_move_board[white_kingside_rook_pos] = rook
          @special_move_board[[7, 5]] = nil
          @special_move_board[[7, 6]] = nil
          @special_move_board[[0, 4]] = King.new(:black)

          castling_move = [white_king_pos, [7, 6]]

          king = @special_move_board[white_king_pos]
          expect(king.valid_moves(@special_move_board, white_king_pos)).not_to include([7, 6])
          expect { @special_move_board.move_piece(castling_move[0], castling_move[1]) }.to raise_error(InvalidMoveError)
        end

        it 'does not allow castling if there are pieces between king and rook' do
          white_king_pos = [7, 4]
          white_kingside_rook_pos = [7, 7]
          @special_move_board[white_king_pos] = King.new(:white)
          @special_move_board[white_kingside_rook_pos] = Rook.new(:white)
          @special_move_board[[7, 5]] = Knight.new(:white)
          @special_move_board[[7, 6]] = nil
          @special_move_board[[0, 4]] = King.new(:black)

          castling_move = [white_king_pos, [7, 6]]

          king = @special_move_board[white_king_pos]
          expect(king.valid_moves(@special_move_board, white_king_pos)).not_to include([7, 6])
          expect { @special_move_board.move_piece(castling_move[0], castling_move[1]) }.to raise_error(InvalidMoveError)
        end

        it 'does not allow castling if the king is in check' do
          white_king_pos = [7, 4]
          white_kingside_rook_pos = [7, 7]
          @special_move_board[white_king_pos] = King.new(:white)
          @special_move_board[white_kingside_rook_pos] = Rook.new(:white)
          @special_move_board[[7, 5]] = nil
          @special_move_board[[7, 6]] = nil
          @special_move_board[[0, 4]] = King.new(:black)
          @special_move_board[[7, 1]] = Rook.new(:black) # Black rook attacking e1 (king's start)

          castling_move = [white_king_pos, [7, 6]]

          king = @special_move_board[white_king_pos]
          expect(king.valid_moves(@special_move_board, white_king_pos)).not_to include([7, 6])
          # This should raise CheckError, as the King's valid_moves will filter it out if in check
          expect { @special_move_board.move_piece(castling_move[0], castling_move[1]) }.to raise_error(CheckError)
        end

        it 'does not allow castling if the king passes through an attacked square' do
          white_king_pos = [7, 4]
          white_kingside_rook_pos = [7, 7]
          @special_move_board[white_king_pos] = King.new(:white)
          @special_move_board[white_kingside_rook_pos] = Rook.new(:white)
          @special_move_board[[7, 5]] = nil
          @special_move_board[[7, 6]] = nil
          @special_move_board[[0, 4]] = King.new(:black)
          @special_move_board[[5, 5]] = Bishop.new(:black) # Black bishop attacking f1 (square king passes through)

          castling_move = [white_king_pos, [7, 6]]

          king = @special_move_board[white_king_pos]
          expect(king.valid_moves(@special_move_board, white_king_pos)).not_to include([7, 6])
          expect { @special_move_board.move_piece(castling_move[0], castling_move[1]) }.to raise_error(CheckError)
        end

        it 'does not allow castling if the king lands on an attacked square' do
          white_king_pos = [7, 4]
          white_kingside_rook_pos = [7, 7]
          @special_move_board[white_king_pos] = King.new(:white)
          @special_move_board[white_kingside_rook_pos] = Rook.new(:white)
          @special_move_board[[7, 5]] = nil
          @special_move_board[[7, 6]] = nil
          @special_move_board[[0, 4]] = King.new(:black)
          @special_move_board[[5, 6]] = Bishop.new(:black) # Black bishop attacking g1 (square king lands on)

          castling_move = [white_king_pos, [7, 6]]

          king = @special_move_board[white_king_pos]
          expect(king.valid_moves(@special_move_board, white_king_pos)).not_to include([7, 6])
          expect { @special_move_board.move_piece(castling_move[0], castling_move[1]) }.to raise_error(CheckError)
        end
      end

      describe 'En Passant' do
        it 'allows en passant capture when conditions are met' do
          @special_move_board.instance_variable_set(:@grid, Array.new(8) { Array.new(8) })
          white_pawn_pos = [3, 4] # e5
          black_pawn_pos = [1, 3] # d7
          @special_move_board[white_pawn_pos] = Pawn.new(:white)
          @special_move_board[black_pawn_pos] = Pawn.new(:black)
          @special_move_board[[0, 4]] = King.new(:black)
          @special_move_board[[7, 4]] = King.new(:white)
          @special_move_board.current_player = :black

          @special_move_board.move_piece(black_pawn_pos, [3, 3]) # d7 to d5

          expect(@special_move_board.current_player).to eq(:white)
          expect(@special_move_board.en_passant_target).to eq([2, 3])

          en_passant_capture_move = [white_pawn_pos, [2, 3]]

          white_pawn = @special_move_board[white_pawn_pos]
          expect(white_pawn.valid_moves(@special_move_board, white_pawn_pos)).to include([2, 3])

          @special_move_board.move_piece(en_passant_capture_move[0], en_passant_capture_move[1])

          expect(@special_move_board[[2, 3]]).to be_a(Pawn)
          expect(@special_move_board[[2, 3]].color).to eq(:white)
          expect(@special_move_board[[3, 3]]).to be_nil
          expect(@special_move_board[white_pawn_pos]).to be_nil
        end

        it 'resets en passant target after a turn if not used' do
          @special_move_board.instance_variable_set(:@grid, Array.new(8) { Array.new(8) })
          white_pawn_pos = [3, 4] # e5
          black_pawn_pos = [1, 3] # d7
          @special_move_board[white_pawn_pos] = Pawn.new(:white)
          @special_move_board[black_pawn_pos] = Pawn.new(:black)
          @special_move_board[[0, 4]] = King.new(:black)
          @special_move_board[[7, 4]] = King.new(:white)
          @special_move_board.current_player = :black

          @special_move_board.move_piece(black_pawn_pos, [3, 3])

          expect(@special_move_board.en_passant_target).to eq([2, 3])

          @special_move_board.move_piece([7, 4], [7, 3])

          expect(@special_move_board.current_player).to eq(:black)
          expect(@special_move_board.en_passant_target).to be_nil
        end
      end

      describe 'Pawn Promotion' do
        # Use a helper method to stub gets for promotion tests
        def stub_gets(value)
          allow($stdin).to receive(:gets).and_return(value)
        end

        it 'promotes a white pawn to a Queen when it reaches rank 8' do
          stub_gets("Q\n") # Stub gets for this specific test

          @special_move_board.instance_variable_set(:@grid, Array.new(8) { Array.new(8) })
          white_pawn_pos = [1, 0] # a7
          promotion_square = [0, 0] # a8
          @special_move_board[white_pawn_pos] = Pawn.new(:white)
          @special_move_board[[0, 4]] = King.new(:black)
          @special_move_board[[7, 4]] = King.new(:white)
          @special_move_board.current_player = :white

          @special_move_board.move_piece(white_pawn_pos, promotion_square)

          promoted_piece = @special_move_board[promotion_square]
          expect(promoted_piece).to be_a(Queen)
          expect(promoted_piece.color).to eq(:white)
          expect(@special_move_board[white_pawn_pos]).to be_nil
        end

        it "promotes a black pawn to a Rook when it reaches rank 1 (simulating 'R' input)" do
          stub_gets("R\n") # Stub gets for this specific test

          @special_move_board.instance_variable_set(:@grid, Array.new(8) { Array.new(8) })
          black_pawn_pos = [6, 7] # h2
          promotion_square = [7, 7] # h1
          @special_move_board[black_pawn_pos] = Pawn.new(:black)
          @special_move_board[[0, 4]] = King.new(:black)
          @special_move_board[[7, 4]] = King.new(:white)
          @special_move_board.current_player = :black

          @special_move_board.move_piece(black_pawn_pos, promotion_square)

          promoted_piece = @special_move_board[promotion_square]
          expect(promoted_piece).to be_a(Rook)
          expect(promoted_piece.color).to eq(:black)
          expect(@special_move_board[black_pawn_pos]).to be_nil
        end
      end
    end

    describe 'Check and Checkmate' do
      before do
        @check_board = Board.new
        @check_board.instance_variable_set(:@grid, Array.new(8) { Array.new(8) })
      end

      it 'correctly identifies when the current player is in check' do
        white_king_pos = [7, 4] # e1
        black_rook_pos = [0, 4] # e8
        @check_board[white_king_pos] = King.new(:white)
        @check_board[black_rook_pos] = Rook.new(:black)
        @check_board.current_player = :white

        expect(@check_board.in_check?(:white)).to be true
        expect(@check_board.in_check?(:black)).to be false
      end

      it 'correctly identifies when the current player is NOT in check' do
        white_king_pos = [7, 4]
        black_rook_pos = [0, 0]
        @check_board[white_king_pos] = King.new(:white)
        @check_board[black_rook_pos] = Rook.new(:black)
        @check_board.current_player = :white

        expect(@check_board.in_check?(:white)).to be false
      end

      it 'correctly identifies checkmate' do
        checkmate_board = Board.new
        checkmate_board.instance_variable_set(:@grid, Array.new(8) { Array.new(8) })
        white_king_pos = [0, 0]
        black_queen_pos = [1, 2]
        black_bishop_pos = [2, 1]
        checkmate_board[white_king_pos] = King.new(:white)
        checkmate_board[black_queen_pos] = Queen.new(:black)
        checkmate_board[black_bishop_pos] = Bishop.new(:black)
        checkmate_board[[7, 7]] = King.new(:black)
        checkmate_board.current_player = :white

        expect(checkmate_board.in_check?(:white)).to be true
        expect(checkmate_board.no_legal_moves?(:white)).to be true
        expect(checkmate_board.checkmate?(:white)).to be true
        expect(checkmate_board.checkmate?(:black)).to be false
      end

      it 'correctly identifies stalemate' do
        stalemate_board = Board.new
        stalemate_board.instance_variable_set(:@grid, Array.new(8) { Array.new(8) })
        white_king_pos = [0, 0]
        black_queen_pos = [1, 1]
        stalemate_board[white_king_pos] = King.new(:white)
        stalemate_board[black_queen_pos] = Queen.new(:black)
        stalemate_board[[7, 7]] = King.new(:black)
        stalemate_board.current_player = :white

        expect(stalemate_board.in_check?(:white)).to be false
        expect(stalemate_board.no_legal_moves?(:white)).to be true
        expect(stalemate_board.stalemate?(:white)).to be true
        expect(stalemate_board.stalemate?(:black)).to be false
      end
    end

    describe 'Save and Load' do
      let(:initial_board) { Board.new }
      let(:modified_board) do
        b = Board.new
        b.move_piece([6, 4], [4, 4]) # e2-e4 (White pawn moves 2, sets en passant target)
        b.move_piece([1, 0], [3, 0]) # a7-a5 (Black pawn moves 2, resets en passant target from e2-e4, then sets new)
        b.move_piece([4, 4], [3, 4]) # e4-e5 (White pawn moves 1, resets en passant target to nil)
        b.move_piece([1, 5], [3, 5]) # f7-f5 (Black pawn moves 2, resets en passant target from nil, then sets new)
        b # Return the modified board
      end

      it 'correctly serializes the board state to a hash' do
        serialized_data = initial_board.to_h

        expect(serialized_data).to be_a(Hash)
        expect(serialized_data).to have_key(:grid)
        expect(serialized_data).to have_key(:current_player)
        expect(serialized_data).to have_key(:en_passant_target)
        expect(serialized_data).to have_key(:move_history)

        expect(serialized_data[:grid]).to be_a(Array)
        expect(serialized_data[:grid].length).to eq(8)
        expect(serialized_data[:grid].all? { |row| row.is_a?(Array) && row.length == 8 }).to be true

        white_pawn_data = serialized_data[:grid][6][0]
        expect(white_pawn_data).to be_a(Hash)
        expect(white_pawn_data[:class]).to eq('Pawn')
        expect(white_pawn_data[:color]).to eq(:white)
        expect(white_pawn_data[:moved]).to be false

        expect(serialized_data[:current_player]).to eq(:white)
        expect(serialized_data[:en_passant_target]).to be_nil
        expect(serialized_data[:move_history]).to eq([])
      end

      it 'correctly serializes a board with moves and special states' do
        serialized_data = modified_board.to_h

        expect(serialized_data[:current_player]).to eq(:white)
        expect(serialized_data[:en_passant_target]).to eq([2, 5])

        expect(serialized_data[:grid][6][4]).to be_nil
        expect(serialized_data[:grid][3][4][:class]).to eq('Pawn')
        expect(serialized_data[:grid][3][4][:moved]).to be true

        expect(serialized_data[:grid][1][0]).to be_nil
        expect(serialized_data[:grid][3][0][:class]).to eq('Pawn')
        expect(serialized_data[:grid][3][0][:moved]).to be true

        expect(serialized_data[:grid][1][5]).to be_nil
        expect(serialized_data[:grid][3][5][:class]).to eq('Pawn')
        expect(serialized_data[:grid][3][5][:moved]).to be true

        expect(serialized_data[:move_history]).to be_a(Array)
        expect(serialized_data[:move_history].length).to eq(4)

        first_move = serialized_data[:move_history][0]
        expect(first_move[:from]).to eq([6, 4])
        expect(first_move[:to]).to eq([4, 4])
        expect(first_move[:piece]).to eq('Pawn')
        expect(first_move[:color]).to eq(:white)
        expect(first_move[:captured]).to be_nil
        # Corrected expectation: en_passant_target_before should be nil for the first move
        expect(first_move[:en_passant_target_before]).to be_nil
        expect(first_move[:castling]).to be false

        last_move = serialized_data[:move_history][3]
        expect(last_move[:from]).to eq([1, 5])
        expect(last_move[:to]).to eq([3, 5])
        expect(last_move[:piece]).to eq('Pawn')
        expect(last_move[:color]).to eq(:black)
        expect(last_move[:captured]).to be_nil
        # Corrected expectation based on re-tracing: en_passant_target_before for f7-f5 move is nil
        expect(last_move[:en_passant_target_before]).to be_nil
        expect(last_move[:castling]).to be false
      end

      it 'correctly deserializes a board state from a hash' do
        serialized_data = modified_board.to_h
        loaded_board = Board.from_h(serialized_data)

        expect(loaded_board.current_player).to eq(modified_board.current_player)
        expect(loaded_board.en_passant_target).to eq(modified_board.en_passant_target)

        8.times do |r|
          8.times do |c|
            original_piece = modified_board[[r, c]]
            loaded_piece = loaded_board[[r, c]]

            if original_piece.nil?
              expect(loaded_piece).to be_nil
            else
              expect(loaded_piece).to be_a(original_piece.class)
              expect(loaded_piece.color).to eq(original_piece.color)
              expect(loaded_piece.moved).to eq(original_piece.moved)
            end
          end
        end

        expect(loaded_board.instance_variable_get(:@move_history)).to eq(modified_board.instance_variable_get(:@move_history))
      end

      it 'raises InvalidSaveError for invalid save data format (not a hash)' do
        invalid_data = 'This is not a hash'
        expect { Board.from_h(invalid_data) }.to raise_error(InvalidSaveError, /Invalid save data format/)
      end

      it 'raises InvalidSaveError for missing required keys' do
        invalid_data = { current_player: :white, en_passant_target: nil, move_history: [] } # Missing grid
        # Adjusted regex to match the actual error message
        expect { Board.from_h(invalid_data) }.to raise_error(InvalidSaveError, /Loaded data 'grid' is not a 2D Array\./)
      end

      it 'raises InvalidSaveError for invalid current_player value' do
        invalid_data = { grid: [], current_player: 'red', en_passant_target: nil, move_history: [] }
        # Adjusted regex to match the actual error message
        expect do
          Board.from_h(invalid_data)
        end.to raise_error(InvalidSaveError, /Loaded data 'current_player' is invalid\./)

        invalid_data = { grid: [], current_player: 123, en_passant_target: nil, move_history: [] }
        expect do
          Board.from_h(invalid_data)
        end.to raise_error(InvalidSaveError, /Loaded data 'current_player' is invalid\./)
      end
    end
  end
end
