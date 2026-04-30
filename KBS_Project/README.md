# Oregon Trail Knowledge-Based System

This project is an Oregon Trail-style game built with a CLIPS rule-based knowledge system. It can be played through the included Pygame GUI, or directly through a CLIPS terminal session.

## Requirements

### Required for the GUI

- Python 3.10 or newer
- pip
- Python packages listed in `requirements_gui.txt`:
  - `clipspy`
  - `pygame`

### Optional for terminal-only play

- A local CLIPS installation if you want to run the `.clp` files directly without the Python GUI

## Project Files

- `oregon_trail_gui.py` - graphical Pygame interface for the game
- `requirements_gui.txt` - Python dependencies for the GUI
- `run_gui.bat` - Windows launcher for the GUI
- `definitions.clp` - global state and templates
- `kernel.clp` - shared CLIPS helper functions
- `data.clp` - game data such as locations, names, and item definitions
- `game.clp` - main CLIPS game rules and gameplay functions
- `run.bat` - CLIPS command script for terminal play

## Setup

From the project folder, install the Python dependencies:

```bat
python -m pip install -r requirements_gui.txt
```

## How to Run the GUI

Run the included launcher:

```bat
run_gui.bat
```

Or run the Python file directly:

```bat
python oregon_trail_gui.py
```

## How to Play

1. Choose a starting profession:
   - Banker starts with the most money.
   - Carpenter starts with a moderate amount of money.
   - Farmer starts with the least money.
2. Name five companions, or leave name fields blank to generate random names.
3. Buy starting supplies before beginning the trail.
4. Each day, choose an action:
   - `Travel` moves toward the next location.
   - `Rest` improves party fatigue and health.
   - `Trade` lets you accept or skip supply trades.
   - `Repair Wheel`, `Repair Axle`, or `Repair Tongue` fixes broken wagon parts if you have spare parts.
5. Watch the log, inventory, party health, wagon status, and map to plan your next move.
6. Reach the Willamette Valley alive to win.

## Additional Mechanics

- Fatigue causes your companions and yourself to lose twice as much health than before.
- Make sure to get clothes for snowstorms !!!

## GUI Controls

- Use the mouse to click buttons and make selections.
- Use the mouse wheel to scroll the trail log.
- On the trade screen, press `Esc` to finish trading and return to the trail.

## Running in CLIPS

If you have CLIPS installed, you can play the text version by loading the CLIPS command script from the project directory:

```bat
clips -f2 run.bat
```

You can also enter the commands from `run.bat` manually in a CLIPS session:

```clips
(unwatch all)
(clear)
(load definitions.clp)
(load kernel.clp)
(load data.clp)
(load game.clp)
(reset)
(run)
```

The terminal version prompts for typed commands such as `travel`, `rest`, `trade`, `repair`, `inventory`, `party`, `wagon`, `done`, and `quit`.