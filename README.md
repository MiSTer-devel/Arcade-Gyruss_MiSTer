# Gyruss for [MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki)
An FPGA implementation of Gyruss for the MiSTer platform

## Credits
- Sorgelig - MiSTer project lead
- MiSTer-X - Original Gyruss core design (https://github.com/MrX-8B/MiSTer-Arcade-Gyruss)
- Ace - New Gyruss core design & Konami custom chip implementations
- ElectronAsh - Assistance with Konami custom chip implementations
- Artemio Urbina - Hardware references for video and audio output
- JimmyStones - High score saving support & pause feature
- Kitrinx - ROM loader
- ThePulseRifle - Playtesting

## Features
- Timing-accurate logic model made to match the original as closely as possible
- Keyboard and joystick controls
- High score saving (To save your scores, use the 'Save Settings' option in the OSD)
- T80s CPU by Daniel Wallner with fixes by MikeJ, Sorgelig, and others
- Greg Miller's cycle-accurate MC6809E CPU core with modifications by Sorgelig and bugfixes by Arnim Laeuger and Jotego as the basis for the KONAMI-1 custom encrypted MC6809E
- JT49 sound core by Jotego with modifications to the volume scale by Ace
- T48 MCU by Arnim Laeuger configured as an i8039
- Fully-tuned switchable low-pass filters

## Installation
Place `*.rbf` into the "_Arcade/cores" folder on your SD card.  Then, place `*.mra` into the "_Arcade" folder and ROM files from MAME into "games/mame".

### ****ATTENTION****
ROMs are not included. In order to use this arcade core, you must provide the correct ROMs.

To simplify the process, .mra files are provided in the releases folder that specify the required ROMs along with their checksums.  The ROM's .zip filename refers to the corresponding file in the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for information on how to setup and use the environment.

Quick reference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/games/mame/<mame rom>.zip
/games/hbmame/<hbmame rom>.zip

## Controls
### Keyboard
| Key | Function |
| --- | --- |
| 1 | 1-Player Start |
| 2 | 2-Player Start |
| 5, 6 | Coin |
| 9 | Service Credit |
| Arrow keys | Movement |
| CTRL | Shot |

## Known Issues
1) The volume scale for the AY-3-8910s requires further tuning for proper accuracy
