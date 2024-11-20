// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************

class my_agent_base extends uvm_agent;

	`uvm_component_utils(my_agent_base)
	
	driver drv;
	monitor_in in_mon;
	monitor_out out_mon;
	
	uvm_analysis_port # (my_transaction_in) ap;
	uvm_analysis_port # (my_transaction_out) ap_o;
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
	    `uvm_info(get_type_name(),"new is called", UVM_LOW);
	endfunction

	 virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		  if (is_active == UVM_ACTIVE) begin 
			drv = driver::type_id::create("drv", this);
			in_mon = monitor_in::type_id::create("in_mon", this);
		  end
		  else 		  
		 	out_mon = monitor_out::type_id::create("out_mon", this);
		`uvm_info(get_type_name(),"build phase is called", UVM_LOW);
	endfunction 

	 virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
			if (is_active == UVM_ACTIVE) begin 
				this.ap = in_mon.ap;
			  end 
			else 
			  	this.ap_o = out_mon.ap; 
	endfunction 
endclass


class my_agent extends my_agent_base;
	`uvm_component_utils(my_agent)
	
	sequencer seqr;
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	 virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		  if (is_active == UVM_ACTIVE) begin
			seqr = sequencer::type_id::create("seqr", this);
		  end
	endfunction 

	 virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(phase);
			if (is_active == UVM_ACTIVE) begin
				drv.seq_item_port.connect(seqr.seq_item_export);
			end
	endfunction

endclass