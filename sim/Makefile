SIM ?= icarus
TOPLEVEL_LANG ?= verilog

PWD = $(shell pwd)
RTL_DIR = $(PWD)/../rtl

.PHONY: all test_debounce test_fifo test_uart clean_all

all: test_debounce test_fifo test_uart

test_debounce:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) sim \
		SIM_BUILD=sim_build/debounce \
		VERILOG_SOURCES="$(RTL_DIR)/debounce_edge_detect.sv waves_debounce.v" \
		COMPILE_ARGS="-s waves_debounce" \
		TOPLEVEL=debounce_edge_detect \
		MODULE=test_debounce

test_fifo:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) sim \
		SIM_BUILD=sim_build/fifo \
		VERILOG_SOURCES="$(RTL_DIR)/sync_fifo.sv waves_fifo.v" \
		COMPILE_ARGS="-s waves_fifo" \
		TOPLEVEL=sync_fifo \
		MODULE=test_fifo

test_uart:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) sim \
		SIM_BUILD=sim_build/uart \
		VERILOG_SOURCES="$(RTL_DIR)/uart_tx.sv waves_uart.v" \
		COMPILE_ARGS="-s waves_uart" \
		TOPLEVEL=uart_tx \
		MODULE=test_uart_tx

clean_all:
	rm -rf sim_build results*.xml *.vcd *.fst

ifneq ($(VERILOG_SOURCES),)
include $(shell cocotb-config --makefiles)/Makefile.sim
endif
