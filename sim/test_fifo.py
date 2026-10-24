import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge

async def reset_dut(dut):
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.wr_data.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

@cocotb.test()
async def test_fifo_push_pop_flags(dut):
    """Verify write, read, occupancy count, full/empty and almost flags with overflow/underflow protection."""
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    # 1. Verify initial reset state
    assert dut.empty.value == 1, "Error: FIFO should be empty after reset"
    assert dut.full.value == 0, "Error: FIFO should not be full after reset"
    assert dut.almost_empty.value == 1, "Error: almost_empty should be 1 after reset"
    assert dut.almost_full.value == 0, "Error: almost_full should be 0 after reset"
    assert dut.occupancy.value == 0, "Error: occupancy should be 0 after reset"

    # 2. Write 16 elements and check occupancy + threshold flags progressively
    depth = 16
    for i in range(depth):
        dut.wr_en.value = 1
        dut.wr_data.value = (i * 7) & 0xFF
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)

        expected_occ = i + 1
        assert dut.occupancy.value == expected_occ, f"Error: occupancy mismatch! Expected {expected_occ}, got {dut.occupancy.value}"
        assert dut.empty.value == 0, "Error: empty flag must be 0 when FIFO has items"

        if expected_occ <= 2:
            assert dut.almost_empty.value == 1, f"Error: almost_empty should be 1 at occupancy {expected_occ}"
        else:
            assert dut.almost_empty.value == 0, f"Error: almost_empty should be 0 at occupancy {expected_occ}"

        if expected_occ >= 14:
            assert dut.almost_full.value == 1, f"Error: almost_full should be 1 at occupancy {expected_occ}"
        else:
            assert dut.almost_full.value == 0, f"Error: almost_full should be 0 at occupancy {expected_occ}"

    dut.wr_en.value = 0
    await RisingEdge(dut.clk)
    assert dut.full.value == 1, "Error: FIFO should assert full flag after 16 writes"

    # 3. Overflow protection: write when full should be ignored
    dut.wr_en.value = 1
    dut.wr_data.value = 0xAA
    await RisingEdge(dut.clk)
    dut.wr_en.value = 0
    await RisingEdge(dut.clk)
    assert dut.full.value == 1, "Error: full flag must remain 1 after overflow attempt"
    assert dut.occupancy.value == depth, "Error: occupancy must remain 16 after overflow attempt"

    # 4. Read 16 elements and verify FIFO ordering (1-cycle read latency)
    dut.rd_en.value = 1
    await RisingEdge(dut.clk)

    for i in range(depth):
        if i == depth - 1:
            dut.rd_en.value = 0  # Deassert on the last cycle to prevent extra read
        await RisingEdge(dut.clk)
        expected = (i * 7) & 0xFF
        assert dut.rd_data.value == expected, f"Data mismatch! Expected: {expected}, got: {dut.rd_data.value}"

    await RisingEdge(dut.clk)
    assert dut.empty.value == 1, "Error: FIFO should be empty after reading all elements"
    assert dut.almost_empty.value == 1, "Error: almost_empty should be 1 after reading all elements"
    assert dut.almost_full.value == 0, "Error: almost_full should be 0 after reading all elements"
    assert dut.occupancy.value == 0, "Error: occupancy should be 0 after reading all elements"

    # 5. Underflow protection: read when empty should be ignored
    dut.rd_en.value = 1
    await RisingEdge(dut.clk)
    dut.rd_en.value = 0
    await RisingEdge(dut.clk)
    assert dut.empty.value == 1, "Error: empty flag must remain 1 after underflow attempt"
    assert dut.occupancy.value == 0, "Error: occupancy must remain 0 after underflow attempt"

@cocotb.test()
async def test_fifo_simultaneous_read_write(dut):
    """Verify simultaneous read and write (occupancy remains constant, data order preserved)."""
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    # Pre-fill FIFO with 4 items
    prefill = [0x11, 0x22, 0x33, 0x44]
    for val in prefill:
        dut.wr_en.value = 1
        dut.wr_data.value = val
        await RisingEdge(dut.clk)
    dut.wr_en.value = 0
    await RisingEdge(dut.clk)
    assert dut.occupancy.value == 4, "Error: occupancy should be 4 after prefill"

    # Simultaneous push & pop: write [0x55, 0x66, 0x77] while reading prefill items
    # Initial read request
    dut.rd_en.value = 1
    dut.wr_en.value = 1
    dut.wr_data.value = 0x55
    await RisingEdge(dut.clk)

    # Next cycle: write 0x66, read 0x11
    dut.wr_data.value = 0x66
    await RisingEdge(dut.clk)
    assert dut.rd_data.value == 0x11, f"Simultaneous read error! Expected 0x11, got {dut.rd_data.value}"
    assert dut.occupancy.value == 4, f"Occupancy must stay 4 during simultaneous rw, got {dut.occupancy.value}"

    # Next cycle: write 0x77, read 0x22
    dut.wr_data.value = 0x77
    await RisingEdge(dut.clk)
    assert dut.rd_data.value == 0x22, f"Simultaneous read error! Expected 0x22, got {dut.rd_data.value}"
    assert dut.occupancy.value == 4, f"Occupancy must stay 4 during simultaneous rw, got {dut.occupancy.value}"

    # Stop writing, continue reading
    dut.wr_en.value = 0
    await RisingEdge(dut.clk)
    assert dut.rd_data.value == 0x33, f"Simultaneous read error! Expected 0x33, got {dut.rd_data.value}"

    # Read remaining items: 0x44, 0x55, 0x66, 0x77
    remaining = [0x44, 0x55, 0x66, 0x77]
    for i, val in enumerate(remaining):
        if i == len(remaining) - 1:
            dut.rd_en.value = 0
        await RisingEdge(dut.clk)
        assert dut.rd_data.value == val, f"Data mismatch on remaining items! Expected {hex(val)}, got {dut.rd_data.value}"

    await RisingEdge(dut.clk)
    assert dut.empty.value == 1, "FIFO should be empty after draining all items"
    assert dut.occupancy.value == 0, "Occupancy should be 0 after draining all items"
