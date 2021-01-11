# Snake-Game
==============

Running the program
-------------------
Move the snake using the arrow keys.

The game provides the following speed levels:

* Earthworm (very slow)
* Centipede (still too slow - but okay)
* Cobra (makes for interesting gameplay)
* Black Mamba (BE CAREFUL! - this is the fastest snake ever discovered)

For added challenge, players can select a level:

* None (open playing field)
* Box (the playing field is surrounded by walls)
* Rooms (the snake operates in a space of four rooms)


Information on compiling the code
---------------------------------

snake.asm contains the code for the game. It is dependent on Irvine32.inc which is not provided in this repository.

why we use Irvine library ?
---------------------------
Usually one wants to use it to avoid writing the code providing that functionality himself. As the assembly code replicating some of the functionality may be tens or hundreds of lines of code (or even thousands for very complex functions), and having it to write every time may be cumbersome.
Also the API provided by Irvine32 functions is often simpler to use than similar API provided by OS services, so it may be often somewhat simpler to use Irvine32 instead of calling the OS services directly.
Procdures used in this code
---------------------------

The for this game is divided into many procedures. There a quick description for each one:

1) main: The main procedure handles printing menus to the user, configuring the game
 and then starting the game.
 
2) initSnake: This procedure initializes the snake to the default position
in the center of the screen.

3) clearMem: This procedure clears the framebuffer, resets the snake position and length,
and sets all the game related flags back to their default value.

4) startGame: This procedure is the main process, and has an infinite loop which exits
when the user presses ESC or when it comes to a collision with a wall or the
snake itself. Upon exit, the procedure resets the game flags to default and
clears the framebuffer.
The procedure decides which direction change has to be made, depending on the
current direction of the snake and the user input from the terminal. The
procedure also delays the game between frames, which controls the gamespeed.

Notes about console interaction:
The ReadConsoleInput procedure reads data structures called INPUT_RECORD from
the termninal input program memory. The procedure takes as input the console
input handle, a pointer to the buffer for holding INPUT_RECORD messages,
number of INPUT_RECORD messages to be read, and a pointer to where to store
the number of INPUT_RECORD messages read in the procedure call.

The INPUT_RECORD is a structure that has an EventType (WORD) and an Event
which can be an event from a keyboard, a mouse, menu event, focus event, etc.
The KEY_EVENT_RECORD has bKeyDown (BOOL), wRepeatCount (WORD),
wVirtualKeyCode (WORD), wVirtualScanCode (WORD) and so on...

5) MoveSnake: This procedure updates the framebuffer, thus moving the snake. The procedure
starts from the snake tail, and searches for the next segment in the
region of the current segment. All segments get updated, while the last
segment gets erased (if no food has been eaten), and a new segment gets
addded to the beginning of the snake, depending on the terminal input.
This procedure also check if there has been a collision, and if the food was
gobbled or not.

6) accessIndex: This procedure accesses the framebuffer and returns the value of the pixel
specified by DH (row index) and DL (column index). The pixel value gets
returned through the register BX.

7) saveIndex: This procedure accesses the framebuffer and writes a value to the pixel
specified by DH (row index) and DL (column index). The pixel value has to be
passed though the register BX .

8) Paint: This procedure reads the contents of the framebuffer, pixel by pixel, and
puts them onto the terminal screen. This includes the snake and the walls.
The color of the walls can be changed in this procedure. The color of the
snake has to be changed here, as well as in the moveSnake procedure.

9) GenLevel: This procedure takes care of generating the level obstacles. There are three
levels; a no obstacle level, a box level, and a level with four rooms. The
level choice gets passed through the AL register (can be 1 to 3). Default
level choice is without obstacles.
Obstacles get written into the framebuffer, as 0FFFFh values.
