// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  Description : BSHL_pkg is a package that includes several components, among which are BSHL_if and BSHL_lib, as well as the type definition for transaction_descriptor, which is used for communication between SV and the HLL.
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************

`ifndef BSHL_PKG_SV
`define BSHL_PKG_SV

package BSHL_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef struct{ 
		string name;
    	bit rdnwr;
    	int unsigned addr;
    	int unsigned data[4];
    	uvm_status_e status;
	} transaction_descriptor; //definition for descriptor, to commnunicate between SV and python

    `include "BSHL_if.svh"
	`include "BSHL_lib.svh"
    
endpackage: BSHL_pkg

`endif // BSHL_PKG_SV