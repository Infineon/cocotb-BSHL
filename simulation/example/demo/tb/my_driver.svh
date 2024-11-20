// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************

class driver extends uvm_driver #(my_transaction_in);
 	`uvm_component_utils(driver)
	
 	virtual interface my_if_in vif_in;
	
	my_transaction_in in_trans;
	
	function new(string name = "driver", uvm_component parent); //null or not
		super.new(name, parent);
		 `uvm_info("driver","new is called", UVM_LOW);
	endfunction 
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);	
		if(!uvm_config_db#(virtual my_if_in)::get(this, "", "vif_in", vif_in)) 
			`uvm_fatal("driver", "virtual interface must be set for vif_in");		
	endfunction : build_phase 
		
	virtual task get_and_drive();
		while(1) begin 
		seq_item_port.try_next_item(in_trans); //or use get_next_item 
			if (in_trans == null) 
				@(posedge vif_in.clk);
			else begin 
				drive_pkt(in_trans);
				seq_item_port.item_done();  //make sure this transaction in sequencer has been accepted
			// also inform uvm_do in sequence to execute the next uvm_do 
			end 
		end 
	endtask 
	
	virtual task drive_pkt(my_transaction_in tp_trans);
		@(posedge vif_in.clk);	
			vif_in.a <= tp_trans.a;
			vif_in.b <= tp_trans.b;
			vif_in.op <= tp_trans.op;
	endtask 
	
	task run_phase(uvm_phase phase);

	vif_in.a <= 32'h0;
	vif_in.b <= 32'h0;
	vif_in.op <= 3'b0;

	   get_and_drive();									
	endtask 
	
endclass 	
