# CHESS
## How to Play CLI Chess

This is a command-line interface (CLI) chess game. You'll interact with the game by typing commands into your terminal.

**1. Starting the Game:**

* Run the main game script from your terminal. (This will be the `main.rb` or similar file).
* A new game will start automatically (unless you choose to load one). White moves first.

**2. Making a Move:**

* The board will be displayed, showing the current position.
* The game will prompt the current player to enter a move.
* Enter your move using **algebraic notation** in the format `[start_square]-[end_square]`.
    * Examples:
        * `e2-e4` (Move piece from e2 to e4)
        * `g1-f3` (Move piece from g1 to f3)
        * `a7-a8` (Move piece from a7 to a8 - might trigger promotion)

**3. Special Moves:**

* **Castling:** Enter the King's move two squares towards the Rook (e.g., White King from e1 to g1 would be `e1-g1`, White King from e1 to c1 would be `e1-c1`). The game will automatically move the corresponding Rook if the castling move is legal.
* **En Passant:** If an opponent's pawn has just moved two squares forward and is now beside your pawn, you can capture it using the standard diagonal pawn capture move to the square the opponent's pawn **skipped over**. The game will handle removing the captured pawn correctly.
* **Pawn Promotion:** When your pawn reaches the opposite end of the board (rank 8 for White, rank 1 for Black), the game will prompt you to choose which piece to promote it to.
    * Enter `Q` for Queen.
    * Enter `R` for Rook.
    * Enter `B` for Bishop.
    * Enter `N` for Knight.

**4. Saving and Loading:**

* **Save Game:** At your turn, type `save [filename]` and press Enter. Replace `[filename]` with a name for your save file (e.g., `save mygame1`). The game state will be saved to a file in a `saves` directory.
* **Load Game:** At your turn, type `load [filename]` and press Enter. Replace `[filename]` with the name of a saved game file (e.g., `load mygame1`). The game will attempt to load that save state.

**5. Errors:**

* If you enter an invalid move or command, the game will print an error message (e.g., "Invalid move," "Wrong color," "Save file not found") and prompt you to try again.

**6. Ending the Game:**

* The game automatically ends when a checkmate or stalemate occurs.
* You can typically exit the game at any time by pressing `Ctrl + C` in your terminal.

---