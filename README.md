# cocotb-BSHL: Bridgepath for Systemverilog to Higher-level Language

<a href="https://www.infineon.com">
<img src="./img/Logo.svg" align="right" alt="Infineon logo">
</a>

This repository contains templates and examples for interfacing cocotb with SystemVerilog methods to
facilitate usage of UVM-SV VIP in cocotb testbenches. It overcomes the limitation of cocotb that works
only on signal level, employing the DPI-C interface.

## Content

In source folder, c/, sv/ and py/ are meant to be project-independent while the templates/ files are
customizable.

## Documentation

Please check the user manual in doc/.

## Usage

A Python virtual environment with Python version==3.9 ,and simulation tool Xcelium are required
(xrun must be in PATH).

Command to create and activate a Python virtual environment:

    python -m venv <environment_name>
    source <environment_name>/bin/activate.csh


For a quick Start (a simple demo), Run following command:

    cd cocotb-BSHL/
    pip install -r requirements.txt
    cd simulation/example
    make

After the GUI of XCelium pops up, you can start the simulation,
results and log information should be reported in the console and .xml file in simulation/example/

You can change the testbench in Makefile. Currently, testbench_cocotb, testbench_pyvsc, testbench_cov are supported.

To better visualize the coverage report of pyvsc, use command: pyucis-viewer coverage_result_pyvsc.xml
