# FPGA Hangman Game (VHDL)

A hardware implementation of the classic **Hangman Game** (*Jogo da Forca*) developed in **VHDL** for the **Xilinx Spartan-3A/3AN** FPGA board. The system receives player inputs from a **PS/2** keyboard, buffers keystrokes in a **FIFO**, processes the game logic, and displays the progress, remaining attempts, and final result on the onboard **16x2 LCD** screen, while also outputting the ASCII code of the last read key to the **8 onboard LEDs** for debugging.

## Features

* **PS/2 Receiver with Digital Noise Filter (`ps2_rx`):** Captures 11-bit serial frames from a PS/2 keyboard using an 8-stage digital noise filter and falling-edge detector on the keyboard clock line (`ps2c`).
* **Key-Release Detection (`kb_code`):** Identifies the PS/2 *Break Code* (`0xF0`) to register each key only once per press, preventing duplicate reads.
* **Circular FIFO Buffer (`fifo`):** Parameterizable queue with a word width of $B = 8$ bits and depth of $2^W = 8$ entries ($W = 3$), ensuring rapid keystrokes are not lost.
* **Scan Code to ASCII Decoder (`key2ascii`):** Converts PS/2 keyboard scan codes (Set 2) into standard ASCII characters (`0–9`, `A–Z`, Space, Enter, and Backspace).
* **8-Bit 16x2 LCD Controller (`lcd`):** Generates a synchronous $1\ \mu\text{s}$ time base from the $50\text{ MHz}$ system clock and drives display initialization and continuous updates using two Finite State Machines (FSMs).
* **Hangman Game Logic (`lcd`):** Tracks guessed letters of the secret word, manages the countdown of remaining attempts, and handles win/loss states.
* **Visual LED Debugging:** The `tecla[7:0]` output bus displays the binary ASCII code of the most recently read key on the board's 8 LEDs.

## System Architecture

The `lcd` module serves as the **Top-Level** entity of the design, integrating the keyboard input subsystem (`kb_code`), the game logic, and the LCD display controller:

```text
                  +--------------------------------------------------+
                  |                     kb_code                      |
[PS/2 Keyboard] ->| ps2_rx ---> key2ascii ---> fifo (8x8 bits)       |
                  +--------------------------+-----------------------+
                                             | key_code (ASCII) / kb_buf_empty
                                             v
                  +--------------------------------------------------+
                  |                 lcd (Top-Level)                  |
                  |  +----------------------+   +-----------------+  |---> [16x2 LCD (8-bit)]
                  |  |  Hangman Game Logic  |-->| LCD Controller  |  |
                  |  |  (Word + Attempts)   |   | FSM (1 us tick) |  |---> [LEDs tecla(7:0)]
                  |  +----------------------+   +-----------------+  |
                  +--------------------------------------------------+
```

## Module Structure

| Module / Entity | Role in the Project |
| :--- | :--- |
| **`lcd`** *(Top-Level)* | Main entity. Instantiates `kb_code`, generates the $1\ \mu\text{s}$ tick, executes the Hangman game logic, and drives the 8-bit LCD bus (`LCD_DB`, `RS`, `RW`, `OE`). |
| **`kb_code`** | Integrates the PS/2 receiver, ASCII converter, and FIFO. Filters the `0xF0` *break code* and writes the corresponding ASCII character into the buffer upon key release. |
| **`ps2_rx`** | Serial PS/2 receiver with an 8-bit noise filter on `ps2c`, falling-edge detection, and reception FSM (`idle`, `dps`, `load`). |
| **`key2ascii`** | Combinational circuit that maps PS/2 scan codes to standard ASCII codes (letters `A–Z`, digits `0–9`, Space, Enter, and Backspace; unmapped keys return `*`). |
| **`fifo`** | Generic synchronous FIFO memory ($B = 8$ bits, $W = 3 \Rightarrow 8$ words) with read/write pointers and `empty`/`full` status flags. |
| **`.ucf` File (`lcd.ucf`)** | User Constraints File specifying physical pin assignments and the `LVCMOS33` I/O standard for the Spartan-3A/3AN board. |
| **`Forca` / `main`** | Empty stub entities generated during ISE project creation; not required for final synthesis. |

## How the Game Works

1. **Game Start:**
   * **Line 1** of the LCD displays `JOGO DA FORCA`.
   * **Line 2** displays five hidden placeholders (`_____`) representing the secret word **`FORCA`**, along with the attempt counter initialized to **`5`** on the right side.
2. **Playing via PS/2 Keyboard:**
   * Each pressed and released key is converted to ASCII and read from the FIFO.
   * **Correct Guess:** If the typed letter is `F`, `O`, `R`, `C`, or `A`, it is immediately revealed in its corresponding position on Line 2.
   * **Wrong Guess:** Any other key decrements the attempt counter by 1.
3. **End Conditions:**
   * **Victory:** Once all 5 letters are uncovered (`certo_reg = "11111"`), the game enters the win state (`game_win = '1'`), locks further input, and updates the start of Line 1 to **`GANHOU!`**.
   * **Defeat:** When the attempt counter reaches `0` (`game_over = '1'`), the game locks further input and updates the start of Line 1 to **`PERDEU!`**.
4. **Reset:**
   * Asserting the reset signal (`rst`, pin `R13`) restarts the game, restores the 5 attempts, and hides the word again.

## Pinout Mapping (Spartan-3A/3AN)

All pins are configured with the `LVCMOS33` I/O standard:

| Signal | FPGA Pin | Direction | Description |
| :--- | :--- | :--- | :--- |
| `CLK` | `E12` | Input | Onboard main clock ($50\text{ MHz}$) |
| `rst` | `R13` | Input | System reset |
| `ps2c` | `W12` | Input | PS/2 keyboard clock |
| `ps2d` | `V11` | Input | PS/2 keyboard data |
| `OE` | `AB4` | Output | LCD Enable (`E`) |
| `RS` | `Y14` | Output | LCD Register Select |
| `RW` | `W13` | Output | LCD Read/Write |
| `LCD_DB[7:0]` | `Y15, AB16, Y16, AA12, AB12, AB17, AB18, Y13` | Output | 8-bit LCD data bus |
| `tecla[7:0]` | `W21, Y22, V20, V19, U19, U20, T19, R20` | Output | Onboard LEDs displaying the read key's ASCII code |

## Build & Deployment

### Prerequisites
* **Hardware:** **Xilinx Spartan-3A / Spartan-3AN** Starter Kit and a **PS/2 keyboard**.
* **Software:** **Xilinx ISE Design Suite** (e.g., version 14.7).

### Step-by-Step
1. Open **Xilinx ISE** and create or load a project targeting your Spartan-3A/3AN FPGA device.
2. Add the required VHDL source files (`lcd_vhd.vhd`, `kb_code.vhd`, `ps2_vhd.vhd`, `key2ascii.vhd`, `fifo.vhd`) and the constraints file (`lcd.ucf`).
3. Set the **`lcd`** entity as the **Top Module**.
4. Run **Synthesize - XST**, **Implement Design**, and **Generate Programming File**.
5. Connect the board via USB/JTAG and program the generated `.bit` file using **iMPACT**.
6. Plug in the PS/2 keyboard, press reset (`rst`) if needed, and type letters to play.

## Technical Notes

* **Empty Files:** The `Forca` and `main` entities included in the repository are empty stubs and can be safely removed or ignored as long as `lcd` is set as the *Top Module*.
* **Duplicate Library Declarations:** Some source files contain repeated `library IEEE;` blocks from the default ISE template; keeping a single declaration at the top of each file is recommended to avoid unnecessary warnings.
* **Potential Improvements:**
  * Add a word bank (ROM) to vary the secret word across rounds.
  * Track previously guessed wrong letters so repeated presses do not consume extra attempts.
  * Clear trailing characters on Line 1 when displaying `GANHOU!` or `PERDEU!` (overwriting the remaining characters of `JOGO DA FORCA`).