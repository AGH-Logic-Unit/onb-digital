## Onboarding Tasks Submission – AGH Logic Unit

**Contributor:** @<username>

---

### 1. Implementation Summary & Design Decisions
* **Task 1 (Debouncer):** *(Briefly explain how you calculated counter bounds and generated the 1-cycle edge pulses)*
* **Task 2 (Sync FIFO):** *(How did you handle pointer progression and occupancy update during simultaneous read & write?)*
* **Task 3 (UART TX):** *(Briefly describe your FSM state transitions and baud rate prescaler mechanism)*

---

### 2. Pre-Review Hardware Quality Checklist
- [ ] **Verification:** Ran `make clean_all && make all` and all 3 testbenches passed locally.
- [ ] **Simulation Waveforms:** Generated waveforms with `WAVES=1` and inspected signal transitions.
- [ ] **No Latches:** All combinational outputs have default values and complete `case`/`if` coverage.
- [ ] **Coding Rules:** Non-blocking assignments (`<=`) in sequential blocks, blocking (`=`) in combinational blocks.
- [ ] **Parameterization:** Modules scale cleanly if parameters (e.g., `DEPTH`, `CLK_FREQ_HZ`) are changed.
- [ ] **Interfaces:** All module port names, widths, and active-low resets (`rst_n`) remain untouched.
- [ ] **Git Hygiene:** Changes are committed incrementally across development (not a single bulk commit at the end) with clear commit messages (Conventional Commits encouraged).

---

### 3. Waveform Evidence (Surfer / optional GTKWave)
*Please attach screenshots illustrating key corner cases:*
1. **Debouncer:** Glitch filtering and the 1-cycle edge pulses (rising & falling).
   <!-- [Paste image here] -->
2. **FIFO:** Full/empty flag transitions, occupancy, and read/write ordering.
   <!-- [Paste image here] -->
3. **UART TX:** Start bit, data serialization (LSB first), Stop bit timing, and tx_ready handshake.
   <!-- [Paste image here] -->

---

### 4. Reflection & Learning Notes
* **Most challenging bug encountered & how you solved it:**
  *(e.g., off-by-one counter cycle, Cocotb delta-cycle sampling, etc.)*
* **Questions or areas where you'd like feedback from reviewers:**
  *(e.g., coding style, resource utilization, alternative FSM architectures)*
