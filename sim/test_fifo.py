import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

depth = 16

def test_fifo_flags(dut):
    if int(dut.occupancy.value) == 0:
        return dut.empty.value == 1 and all([dut.almost_empty.value == 0, dut.almost_full.value == 0, dut.full.value == 0])
    elif int(dut.occupancy.value) <= int(dut.ALMOST_EMPTY_THRESH.value):
        return dut.almost_empty.value == 1 and all([dut.empty.value == 0, dut.almost_full.value == 0, dut.full.value == 0])
    elif int(dut.occupancy.value) == depth:
        return dut.full.value == 1 and all([dut.empty.value == 0, dut.almost_full.value == 0, dut.almost_empty.value == 0])
    elif int(dut.occupancy.value) >= int(dut.ALMOST_FULL_THRESH.value):
        return dut.almost_full.value == 1 and all([dut.empty.value == 0, dut.full.value == 0, dut.almost_empty.value == 0])
    else:
        return all([dut.empty.value == 0, dut.full.value == 0, dut.almost_empty.value == 0, dut.almost_empty.value == 0])

@cocotb.test()
async def test_fifo_push_pop_flags(dut):
    """Verify write, read, occupancy count, and full/empty flags."""
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    for _ in range(2):
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
        for i in range(depth):
            assert test_fifo_flags(dut), "FIFO occupancy flags are not correct!"
            dut.wr_en.value = 1
            dut.wr_data.value = (i * 7) & 0xFF
            await RisingEdge(dut.clk)

        assert test_fifo_flags(dut), "FIFO occupancy flags are not correct!"

        dut.wr_en.value = 0
        await RisingEdge(dut.clk)

        assert dut.full.value == 1, "FIFO should assert full flag after 16 writes"
        assert dut.empty.value == 0, "FIFO should not be empty"

        # Read and verify FIFO ordering
        dut.rd_en.value = 1
        await RisingEdge(dut.clk)

        for i in range(depth):
            assert test_fifo_flags(dut), "FIFO occupancy flags are not correct!"

            if i == depth - 1:
                dut.rd_en.value = 0  # Deassert on the last cycle to prevent extra read
            await RisingEdge(dut.clk)
            expected = (i * 7) & 0xFF
            assert dut.rd_data.value == expected, f"Data mismatch! Expected: {expected}, got: {dut.rd_data.value}"

        assert test_fifo_flags(dut), "FIFO occupancy flags are not correct!"

        await RisingEdge(dut.clk)
        assert dut.empty.value == 1, "FIFO should be empty after reading all elements"

        ### TEST SIMULTANEOUS R/W
        # Fill FIFO
        for i in range(depth):
            assert test_fifo_flags(dut), "FIFO occupancy flags are not correct!"
            dut.wr_en.value = 1
            dut.wr_data.value = i+1
            await RisingEdge(dut.clk)

        assert test_fifo_flags(dut), "FIFO occupancy flags are not correct!"

        dut.wr_en.value = 1
        dut.rd_en.value = 1
        dut.wr_data.value = 0x67
        await RisingEdge(dut.clk)

        old_occupancy = int(dut.occupancy.value)

        for i in range(depth):
            assert test_fifo_flags(dut), "FIFO occupancy flags are not correct!"

            if i == depth - 1:
                dut.rd_en.value = 0  # Deassert on the last cycle to prevent extra read
                dut.wr_en.value = 0  # Deassert on the last cycle to prevent extra write

            await RisingEdge(dut.clk)
            expected = i+1
            assert dut.rd_data.value == expected, f"Data mismatch! Expected: {expected}, got: {dut.rd_data.value}"
            assert dut.occupancy.value == old_occupancy, "FIFO occupancy should not change after simultaneous read/write"

        assert test_fifo_flags(dut), "FIFO occupancy flags are not correct!"

        await RisingEdge(dut.clk)
        assert dut.full.value == 1, "FIFO should be full after simultaneously reading and writing all elements"

        dut.rd_en.value = 0
        dut.wr_en.value = 0

        # Test readback after simultaneous R/W
        dut.rd_en.value = 1
        await RisingEdge(dut.clk)

        for i in range(depth):
            assert test_fifo_flags(dut), "FIFO occupancy flags are not correct!"

            if i == depth - 1:
                dut.rd_en.value = 0  # Deassert on the last cycle to prevent extra read

            await RisingEdge(dut.clk)
            expected = 0x67
            assert dut.rd_data.value == expected, f"Data mismatch! Expected: {expected}, got: {dut.rd_data.value}"

        assert test_fifo_flags(dut), "FIFO occupancy flags are not correct!"

        await RisingEdge(dut.clk)
        assert dut.empty.value == 1, "FIFO should be empty after reading all elements"

