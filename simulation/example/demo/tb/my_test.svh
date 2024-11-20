// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************

class my_test extends uvm_test;

	`uvm_component_utils(my_test)  

	function new(string name = "my_test", uvm_component parent = null); 
		super.new(name, parent);
	// `uvm_info("test_case","new is called", UVM_LOW);
	endfunction : new   
	
	//extern virtual function void build_phase(uvm_phase phase);
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);		
 	endfunction : build_phase

	virtual function void report_phase(uvm_phase phase);
		uvm_report_server server;
		int err_num;
		super.report_phase(phase);

		server = get_report_server();
		err_num = server.get_severity_count(UVM_ERROR);

		if(err_num != 0) begin 
			$display("TEST CASE FAILED");
		end 
		else begin
			$display("TEST CASE PASSED");
		end
	endfunction : report_phase



endclass
