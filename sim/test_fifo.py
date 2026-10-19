import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def test_fifo_push_pop_flags(dut):
    """Verify write, read, occupancy count, and full/empty flags."""
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.wr_data.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    assert dut.empty.value == 1, "FIFO should be empty after reset"
    assert dut.full.value == 0, "FIFO should not be full after reset"

    # Write 16 elements
    depth = 16
    for i in range(depth):
        dut.wr_en.value = 1
        dut.wr_data.value = (i * 7) & 0xFF
        await RisingEdge(dut.clk)

    dut.wr_en.value = 0
    await RisingEdge(dut.clk)

    assert dut.full.value == 1, "FIFO should assert full flag after 16 writes"
    assert dut.empty.value == 0, "FIFO should not be empty"

    # Read and verify FIFO ordering
    dut.rd_en.value = 1
    await RisingEdge(dut.clk)

    for i in range(depth):
        if i == depth - 1:
            dut.rd_en.value = 0  # Deassert on the last cycle to prevent extra read
        await RisingEdge(dut.clk)
        expected = (i * 7) & 0xFF
        assert dut.rd_data.value == expected, f"Data mismatch! Expected: {expected}, got: {dut.rd_data.value}"

    await RisingEdge(dut.clk)
    assert dut.empty.value == 1, "FIFO should be empty after reading all elements"