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
    """Test contact bounce rejection and edge pulse generation."""
    clock = Clock(dut.clk, 20, unit="ns")  # 50 MHz
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    for _ in range(2):
        # 1. Check initial state
        assert dut.sig_debounced.value == 0, "Error: sig_debounced is not 0 after reset"

        # 2. Generate short glitch pulses
        for _ in range(5):
            dut.sig_in.value = 1
            await Timer(50, unit="ns")
            dut.sig_in.value = 0
            await Timer(50, unit="ns")

        assert dut.sig_debounced.value == 0, "Error: glitch noise changed sig_debounced!"
        assert dut.edge_rise.value == 0, "Error: false edge_rise pulse during glitch noise!"

        # 3. Apply stable high input (exceeding STABLE_TIME)
        dut.sig_in.value = 1
        # Wait for propagation
        rise_detected = False
        for _ in range(600_000):
            await RisingEdge(dut.clk)
            if dut.edge_rise.value == 1:
                assert not rise_detected, "Error: edge_rise occurred more than once!"
                rise_detected = True
            if dut.sig_debounced.value == 1 and rise_detected:
                break

        assert rise_detected, "Error: 1-cycle edge_rise pulse not detected!"
        assert dut.sig_debounced.value == 1, "Error: sig_debounced did not transition to high!"

        # 4. Check rising and falling edges
        for _ in range(10):
            await RisingEdge(dut.clk)
            assert dut.edge_rise.value == 0, "Error: 1-cycle edge_rise pulse occured after the initial edge rise"
            assert dut.edge_fall.value == 0, "Error: 1-cycle edge_fall pulse occured before the edge fall"

        dut.sig_in.value = 0

        # Wait for the signal to propagate to sig_debounced from inpu
        for _ in range(3):
            await RisingEdge(dut.clk)
            assert dut.edge_rise.value == 0, "Error: 1-cycle edge_rise pulse occured after the initial edge rise"
            assert dut.edge_fall.value == 0, "Error: 1-cycle edge_fall pulse occured before sig_in propagated"       

        # Check if edge fall is detected 
        await RisingEdge(dut.clk)
        assert dut.edge_rise.value == 0, "Error: 1-cycle edge_rise pulse occured after the initial edge rise"
        assert dut.edge_fall.value == 1, "Error: 1-cycle edge_fall pulse did not occur at the edge fall"       

        # Check if no unexpected edge events occur after the edge fall
        for _ in range(10):
            await RisingEdge(dut.clk)
            assert dut.edge_rise.value == 0, "Error: 1-cycle edge_rise pulse occured again after the initial edge rise"
            assert dut.edge_fall.value == 0, "Error: 1-cycle edge_fall pulse occured again after the edge fall"     


