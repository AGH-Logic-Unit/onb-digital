# AGH Logic Unit – Onboarding Repository

Official starter pack for **AGH Logic Unit**. The objective of this track is hands-on onboarding into digital design using SystemVerilog and automated hardware verification with Cocotb.

## Getting Started (Quickstart)

1. **Fork this repository** to your GitHub account.
2. Clone your fork locally (recommended OS: Linux or Windows with WSL2):
   ```bash
   git clone https://github.com/<your-username>/logic-unit-onboarding.git
   cd logic-unit-onboarding
   ```

3. Install required system tools:
   ```bash
   sudo apt-get update && sudo apt-get install -y iverilog python3-pip python3-venv
   ```

   Waveforms can be inspected using **[Surfer](https://surfer-project.org/)** (recommended):
   * **Online (no install needed):** Open [app.surfer-project.org](https://app.surfer-project.org) in your browser and drag-and-drop the generated waveform file.
   * **Desktop app (optional):** Install locally via Cargo (`cargo install surfer`) or download from [GitHub Releases](https://github.com/surfer-project/surfer/releases).

   *(Optional fallback)* If Surfer does not work in your environment, you can install and use **GTKWave**:
   ```bash
   sudo apt-get install -y gtkwave
   ```

4. Create a Python virtual environment and install Cocotb:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r sim/requirements.txt
   ```

5. Verify your simulation setup (tests will initially fail until you complete the implementation in `rtl/`):
   ```bash
   cd sim
   make test_debounce
   ```

   > **Tip:** To generate waveforms (`.fst`) for inspection in Surfer or GTKWave, append `WAVES=1`:
   > ```bash
   > make test_debounce WAVES=1
   > ```
   > The waveform trace will be generated in `sim_build/debounce/debounce_edge_detect.fst`.

## Tasks to Complete

Complete the module implementations in `rtl/`:

* `debounce_edge_detect.sv` – two-stage input synchronizer, contact bounce filtering, and edge detection.
* `sync_fifo.sv` – synchronous circular FIFO buffer with status flags and simultaneous read/write handling.
* `uart_tx.sv` – UART serial transmitter with finite state machine (FSM) and baud rate prescaler.

## Git Workflow & Commit Guidelines

Good version control habits are an essential part of engineering teamwork:
* **Commit incrementally:** Commit your work in logical steps as you progress (e.g., at least one commit per task or milestone). **Do not push everything in a single bulk commit at the end.**
* **Descriptive commit messages:** Use clear, informative commit messages explaining what was changed. Following [Conventional Commits](https://www.conventionalcommits.org/) format is strongly encouraged:
  * `feat(debounce): implement 2-stage synchronizer and counter filter`
  * `fix(fifo): handle simultaneous read/write occupancy update`
  * `feat(uart): implement baud prescaler and 8N1 FSM`

Once all local tests (`make all`) pass with **PASS** status, open a Pull Request targeting the `main` branch of the original repository using the provided template.

---

## Resources

### Digital circuits basics and understanding

* Ben Eater's [YouTube](https://www.youtube.com/@BenEater) and [website](https://eater.net) - protocols, electronics, computing
* [Nand2Tetris](https://nand2tetris.org) course - boolean logic, gates, registers, hierarchical design, ALU, CPU, memory
* H. Neemann's [Digital](https://github.com/hneemann/digital) - digital circuits simulator (with export to Verilog/VHDL)
* [NandGame](https://nandgame.com/) - interactive web game, from gate to CPU
* [Falstad Circuit Simulator](https://www.falstad.com/circuit/) - interactive browser-based electronic and logic simulation
* Harris & Harris: Digital Design & Computer Architecture - comprehensive textbook from logic gates to RISC-V

### Hardware Description Languages

* [ChipVerify](https://chipverify.com) - reference, tutorials, SystemVerilog, Verilog
* [HDLBits](https://hdlbits.01xz.net) - interactive Verilog learning platform
* [EDA Playground](https://edaplayground.com/) - in-browser IDE for running Verilog/SystemVerilog simulations with zero setup
* [Cliff Cummings (Sunburst Design) Papers](http://www.sunburst-design.com/papers/) - industry-standard papers on non-blocking assignments, FIFOs, and CDC

### Hardware Verification & Cocotb

* [Cocotb Documentation](https://docs.cocotb.org) - official guides, coroutines, triggers, and testbench structure
* [Cocotb GitHub Examples](https://github.com/cocotb/cocotb/tree/master/examples) - reference designs and testbench patterns
* [cocotb-coverage](https://github.com/mflow/cocotb-coverage) - functional coverage (covergroups, coverpoints) extension for Cocotb
* [Verification Academy](https://verificationacademy.com/) - industry methodology, assertions, and verification concepts

### Git

* [Git101](https://github.com/AGH-Logic-Unit/git101) - ALU's cheatsheet
* [Learn Git Branching](https://learngitbranching.js.org/) - interactive visual tutorial for branches, merges, and rebases
* [Conventional Commits](https://www.conventionalcommits.org/) - standard specification for meaningful commit messages
* [Oh Shit, Git!?!](https://ohshitgit.com/) - practical survival guide for recovering from common git mistakes

### Hardware Protocols & Interfaces

* [Analog Devices: UART Communication Protocol](https://www.analog.com/en/resources/analog-dialogue/articles/uart-a-hardware-communication-protocol.html) - engineering guide on 8N1 serial framing, baud rates, and timing

### RTL Coding Style & Best Practices

* [lowRISC Verilog/SystemVerilog Style Guide](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md) - industry standard for clean RTL design (OpenTitan)
* [Stuart Sutherland: Standard Gotchas in SystemVerilog](https://sutherland-hdl.com/papers/2006-SNUG-Boston_standard_gotchas_paper.pdf) - classic paper on common hardware design and simulation pitfalls

### Tooling & Waveform Inspection

* [Surfer Manual](https://gitlab.com/surfer-project/surfer) - user manual, features, and keybindings for the Surfer waveform viewer
