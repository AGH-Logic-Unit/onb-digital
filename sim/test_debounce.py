import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def reset_dut(dut):
    dut.rst_n.value = 0
    dut.sig_in.value = 0
    await Timer(100, unit="ns")
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

@cocotb.test()
async def test_debouncer_glitch_and_stable(dut):
    """Test contact bounce rejection, stable signal filtering, and 1-cycle edge pulse generation."""
    clock = Clock(dut.clk, 20, unit="ns")  # 50 MHz
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    # 1. Check initial state after reset
    assert dut.sig_debounced.value == 0, "Error: sig_debounced is not 0 after reset!"
    assert dut.edge_rise.value == 0, "Error: edge_rise is not 0 after reset!"
    assert dut.edge_fall.value == 0, "Error: edge_fall is not 0 after reset!"

    # 2. Glitch rejection when low (short positive spikes)
    for _ in range(5):
        dut.sig_in.value = 1
        await Timer(50, unit="ns")
        dut.sig_in.value = 0
        await Timer(50, unit="ns")

    assert dut.sig_debounced.value == 0, "Error: glitch noise changed sig_debounced!"
    assert dut.edge_rise.value == 0, "Error: false edge_rise pulse during glitch noise!"
    assert dut.edge_fall.value == 0, "Error: false edge_fall pulse during glitch noise!"

    # 3. Apply stable high input (exceeding STABLE_TIME_MS)
    dut.sig_in.value = 1
    rise_detected = False
    for _ in range(600_000):
        await RisingEdge(dut.clk)
        if dut.edge_rise.value == 1:
            assert not rise_detected, "Error: edge_rise occurred more than once!"
            rise_detected = True
        assert dut.edge_fall.value == 0, "Error: spurious edge_fall pulse during rising transition!"
        if dut.sig_debounced.value == 1 and rise_detected:
            break

    assert rise_detected, "Error: 1-cycle edge_rise pulse not detected!"
    assert dut.sig_debounced.value == 1, "Error: sig_debounced did not transition to high!"

    # 4. Verify that edge_rise is a 1-cycle pulse (drops back to 0 on the next cycle)
    await RisingEdge(dut.clk)
    assert dut.edge_rise.value == 0, "Error: edge_rise lasted longer than 1 cycle!"
    assert dut.sig_debounced.value == 1, "Error: sig_debounced dropped unexpectedly!"

    for _ in range(2):
        await RisingEdge(dut.clk)
        assert dut.edge_rise.value == 0, "Error: spurious edge_rise pulse!"

    # 5. Glitch rejection when high (short negative spikes)
    for _ in range(5):
        dut.sig_in.value = 0
        await Timer(50, unit="ns")
        dut.sig_in.value = 1
        await Timer(50, unit="ns")

    assert dut.sig_debounced.value == 1, "Error: negative glitch changed sig_debounced!"
    assert dut.edge_rise.value == 0, "Error: false edge_rise pulse during negative glitch!"
    assert dut.edge_fall.value == 0, "Error: false edge_fall pulse during negative glitch!"

    # 6. Apply stable low input (exceeding STABLE_TIME_MS)
    dut.sig_in.value = 0
    fall_detected = False
    for _ in range(600_000):
        await RisingEdge(dut.clk)
        if dut.edge_fall.value == 1:
            assert not fall_detected, "Error: edge_fall occurred more than once!"
            fall_detected = True
        assert dut.edge_rise.value == 0, "Error: spurious edge_rise pulse during falling transition!"
        if dut.sig_debounced.value == 0 and fall_detected:
            break

    assert fall_detected, "Error: 1-cycle edge_fall pulse not detected!"
    assert dut.sig_debounced.value == 0, "Error: sig_debounced did not transition to low!"

    # 7. Verify that edge_fall is a 1-cycle pulse (drops back to 0 on the next cycle)
    await RisingEdge(dut.clk)
    assert dut.edge_fall.value == 0, "Error: edge_fall lasted longer than 1 cycle!"
    assert dut.sig_debounced.value == 0, "Error: sig_debounced rose unexpectedly!"

    # Keep input low for an extra period to ensure sig_debounced holds steady at 0
    for _ in range(100):
        await RisingEdge(dut.clk)
        assert dut.sig_debounced.value == 0, "Error: sig_debounced did not hold low state!"
        assert dut.edge_fall.value == 0, "Error: spurious edge_fall pulse!"

@cocotb.test()
async def test_realistic_bounce(dut):
    """Test erratic bouncing before settling high."""
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    # Simulate chaotic mechanical bounce pattern
    bounce_pattern = [1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1]
    for val in bounce_pattern:
        dut.sig_in.value = val
        await Timer(200, unit="ns")

    # Assert that during bouncing, sig_debounced has not prematurely triggered
    assert dut.sig_debounced.value == 0, "Error: sig_debounced changed state during bouncing!"

    # Hold the input stable high
    dut.sig_in.value = 1
    stabilized = False
    for _ in range(600_000):
        await RisingEdge(dut.clk)
        if dut.sig_debounced.value == 1:
            stabilized = True
            break

    assert stabilized, "Error: Debouncer failed to recognize the settled high state after bouncing!"
