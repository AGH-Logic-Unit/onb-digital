import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def uart_receive_byte(dut, baud_clks):
    """Wait for start bit, sample 8 data bits (LSB-first) and stop bit at bit midpoints."""
    timeout = 2000
    while int(dut.txd.value) == 1 and timeout > 0:
        await RisingEdge(dut.clk)
        timeout -= 1
    assert timeout > 0, "Timeout waiting for UART start bit (txd transition to 0)!"

    # Midpoint of start bit
    await Timer(baud_clks * 10, unit="ns")
    assert int(dut.txd.value) == 0, "UART Start bit must be 0!"

    # Sample 8 data bits (LSB first) at bit midpoints
    received = 0
    for i in range(8):
        await Timer(baud_clks * 20, unit="ns")
        bit = int(dut.txd.value)
        received |= (bit << i)

    # Midpoint of stop bit
    await Timer(baud_clks * 20, unit="ns")
    assert int(dut.txd.value) == 1, "UART Stop bit must be 1!"

    return received

@cocotb.test()
async def test_uart_tx_single_byte(dut):
    """Verify UART 8N1 single byte transmission, tx_ready handshake, and bit timing."""
    clock = Clock(dut.clk, 20, unit="ns")  # 50 MHz
    cocotb.start_soon(clock.start())
    baud_clks = round(50_000_000 / 115_200)

    dut.rst_n.value = 0
    dut.tx_valid.value = 0
    dut.tx_data.value = 0
    await Timer(100, unit="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # 1. Check IDLE line states
    assert dut.txd.value == 1, "TXD line in IDLE state must remain high (1)"
    assert dut.tx_ready.value == 1, "Transmitter should assert tx_ready after reset"

    # 2. Transmit byte 0xA5
    test_byte = 0xA5
    dut.tx_data.value = test_byte
    dut.tx_valid.value = 1
    await RisingEdge(dut.clk)
    dut.tx_valid.value = 0

    # 3. Verify tx_ready drops to 0 during transmission
    await RisingEdge(dut.clk)
    assert dut.tx_ready.value == 0, "tx_ready must be deasserted (0) during transmission!"

    # 4. Receive and verify byte framing
    rx_byte = await uart_receive_byte(dut, baud_clks)
    assert rx_byte == test_byte, f"UART frame error! Expected: {hex(test_byte)}, received: {hex(rx_byte)}"

    # 5. Verify transmitter returns to IDLE with tx_ready high
    timeout = 1000
    while dut.tx_ready.value == 0 and timeout > 0:
        await RisingEdge(dut.clk)
        timeout -= 1
    assert timeout > 0, "Timeout waiting for tx_ready to assert after transmission!"
    assert dut.tx_ready.value == 1, "tx_ready must return to 1 after stop bit completes!"
    assert dut.txd.value == 1, "TXD line must return to 1 (IDLE) after stop bit!"

@cocotb.test()
async def test_uart_tx_back_to_back(dut):
    """Verify continuous back-to-back multi-byte transmission."""
    clock = Clock(dut.clk, 20, unit="ns")  # 50 MHz
    cocotb.start_soon(clock.start())
    baud_clks = round(50_000_000 / 115_200)

    dut.rst_n.value = 0
    dut.tx_valid.value = 0
    dut.tx_data.value = 0
    await Timer(100, unit="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    assert dut.tx_ready.value == 1, "tx_ready must be asserted after reset"

    test_bytes = [0x3C, 0xA5, 0x55]

    for byte in test_bytes:
        # Wait until transmitter is ready
        timeout = 10_000
        while dut.tx_ready.value == 0 and timeout > 0:
            await RisingEdge(dut.clk)
            timeout -= 1
        assert timeout > 0, "Timeout waiting for tx_ready between bytes!"

        dut.tx_data.value = byte
        dut.tx_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_valid.value = 0

        rx = await uart_receive_byte(dut, baud_clks)
        assert rx == byte, f"Mismatch in back-to-back transmission! Expected {hex(byte)}, got {hex(rx)}"

    # Wait for transmitter to complete stop bit and return to IDLE
    timeout = 1000
    while dut.tx_ready.value == 0 and timeout > 0:
        await RisingEdge(dut.clk)
        timeout -= 1
    assert timeout > 0, "Timeout waiting for tx_ready after last byte!"
    assert dut.tx_ready.value == 1, "tx_ready must remain 1 after all bytes are sent!"
    assert dut.txd.value == 1, "TXD line must remain 1 in IDLE!"
