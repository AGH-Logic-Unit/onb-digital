import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_uart_tx_single_byte(dut):
    """Verify UART 8N1 frame structure (Start bit, 8 data bits LSB-first, Stop bit)."""
    clock = Clock(dut.clk, 20, unit="ns")  # 50 MHz
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.tx_valid.value = 0
    dut.tx_data.value = 0
    await Timer(100, unit="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    for _ in range(2):
        assert dut.txd.value == 1, "TXD line in IDLE state must remain high (1)"
        assert dut.tx_ready.value == 1, "Transmitter should assert tx_ready after reset"

        # Transmit byte 0xA5 (binary: 10100101)
        test_byte = 0xA5
        dut.tx_data.value = test_byte
        dut.tx_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_valid.value = 0

        # Wait for start bit (txd transition to 0) with safety timeout
        timeout = 1000
        while dut.txd.value == 1 and timeout > 0:
            await RisingEdge(dut.clk)
            timeout -= 1

        assert timeout > 0, "Timeout waiting for start bit (txd transition to 0)!"

        baud_clks = round(50_000_000 / 115_200)

        # Check start bit at its mid-point
        await Timer(baud_clks * 10, unit="ns")
        assert dut.txd.value == 0, "Start bit must be 0"

        # Sample 8 data bits (LSB first)
        received_bits = 0
        for i in range(8):
            await Timer(baud_clks * 20, unit="ns")
            bit = int(dut.txd.value)
            received_bits |= (bit << i)

        assert received_bits == test_byte, f"UART frame error! Expected: {hex(test_byte)}, received: {hex(received_bits)}"

        # Stop bit
        await Timer(baud_clks * 20, unit="ns")
        assert dut.txd.value == 1, "Stop bit must be 1"

        await Timer(baud_clks * 20, unit="ns")
