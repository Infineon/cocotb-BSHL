# **************************************************************************
#
#  Author      : See AUTHORS
#  Project     : cocotb-BSHL
#  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
#
#  *****************************************************************************

CWD=$(shell pwd)
PYTHONPATH := $(CWD)/../../source/py
export PYTHONPATH
SIM ?= xcelium
TOPLEVEL_LANG ?= verilog
SIM_ARGS += -uvm -gui  -covoverwrite -coverage u -incdir $(CWD)/demo/tb -incdir $(CWD)/../../source/sv

VERILOG_SOURCES +=$(CWD)/demo/tb/my_uvm_pkg.sv

VERILOG_SOURCES +=$(CWD)/demo/tb/my_if.sv

VERILOG_SOURCES +=$(CWD)/demo/dut/alu.sv
VERILOG_SOURCES +=$(CWD)/demo/dut/refmdl.sv


PLUSARGS += $(CWD)/../../source/sv/BSHL_pkg.sv $(CWD)/demo/tb/BSHL_test_pkg.sv $(CWD)/demo/dpi.cpp
PLUSARGS += $(CWD)/demo/tb_top.sv
MODULE := testbench_cocotb #supported: testbench_cov, testbench_pyvsc
TOPLEVEL = tb_top
include $(shell cocotb-config --makefiles)/Makefile.sim

#SVDPI = /opt/xcelium_22.09.003/CEN/tools.lnx86/include/, should be defined by user themselves
SVDPI = 
DPI_CXX := g++
DPI_FLAGS := -fPIC -shared -I$(SVDPI)
DPI_CPP_FILE := demo/dpi.cpp
libdpi.so: $(DPI_CPP_FILE)
	$(DPI_CXX) $(DPI_FLAGS) -o $@ $^
