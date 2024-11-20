// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************

class monitor_in extends uvm_monitor;
 `uvm_component_utils(monitor_in)
	
	virtual interface my_if_in vif_in;
	uvm_analysis_port #(my_transaction_in) ap; //declare analysis port between monitor and scoreboard 
	my_transaction_in previous_transaction;
    my_transaction_in current_transaction;
	uvm_event transaction_changed;
	bit result;

	function new(string name = "monitor_in", uvm_component parent); 
		super.new(name, parent);
	endfunction 

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(!uvm_config_db#(virtual my_if_in)::get(this, "", "vif_in", vif_in))
		  `uvm_fatal("monitor", "virtual interface must be set for vif_in");

		ap = new("ap", this); //instantiate analysis port
		`uvm_info(get_type_name(), "Build Phase", UVM_LOW);

		if (!uvm_config_db#(uvm_event)::get(this, "", "transaction_changed", transaction_changed))
			`uvm_fatal("monitor_out", "Failed to get input_changed event from config DB");

	endfunction

	task run_phase(uvm_phase phase);

		previous_transaction = my_transaction_in::type_id::create("previous_transaction");
        current_transaction = my_transaction_in::type_id::create("current_transaction");
		///`uvm_info(get_type_name(), "collect one pkt from input vif", UVM_LOW);
		collect_one_pkt(current_transaction); 
	endtask  

	virtual task collect_one_pkt(my_transaction_in tr);
		tr.a = 0;
		tr.b = 0;
		while(1) begin  //always to colletct data
			@(posedge vif_in.clk);
			///`uvm_info(get_type_name(), "Running1", UVM_LOW);
			tr.op = vif_in.op;
			//`uvm_info(get_type_name(), $sformatf("a is 32'b%32b, b is 32'b%32b, op is 32'b%32b", tr.a, tr.b, tr.op), UVM_LOW);
			///`uvm_info(get_type_name(), "Running2", UVM_LOW);
			result = tr.compare(previous_transaction);
			//result = 0;
			if (!result) begin
				transaction_changed.trigger();
				///`uvm_info(get_type_name(), "Trigger the event of Transaction Changed", UVM_LOW);
				ap.write(tr);
        	end
			previous_transaction.copy(tr);
			tr.a = vif_in.a;
			tr.b = vif_in.b;
			///`uvm_info(get_type_name(), "Running3", UVM_LOW);
		end
	endtask 
endclass 

class monitor_out extends uvm_monitor;
 `uvm_component_utils(monitor_out)

	virtual interface my_if_in vif_in;
	virtual interface my_if_out vif_out;
	uvm_analysis_port #(my_transaction_out) ap; //declare analysis port between monitor and scoreboard
	uvm_event transaction_changed;

	function new(string name = "monitor_out", uvm_component parent); 
		super.new(name, parent);
		ap = new("ap", this); //instantiate analysis port
	endfunction 

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		if(!uvm_config_db#(virtual my_if_in)::get(this, "", "vif_in", vif_in))
		  `uvm_fatal("monitor", "virtual interface must be set for vif_in");
		
		if(!uvm_config_db#(virtual my_if_out)::get(this, "", "vif_out", vif_out)) 
		  `uvm_fatal("monitor", "virtual interface must be set for vif_out");

		if (!uvm_config_db#(uvm_event)::get(this, "", "transaction_changed", transaction_changed))
			`uvm_fatal("monitor", "Failed to get transaction_changed event from config DB");

	endfunction

	task run_phase(uvm_phase phase);		
		my_transaction_out tr;
		tr =  my_transaction_out::type_id::create("tr");		
		//`uvm_info(get_type_name(), "collect one pkt from OUTput vif", UVM_LOW);
		collect_one_pkt(tr);
	endtask 
	  
	task collect_one_pkt(my_transaction_out tr);
		
		while(1) begin  //always to colletct data 
			///`uvm_info(get_type_name(), "wait input change", UVM_LOW);
			transaction_changed.wait_trigger();
			tr.r = vif_out.r;
			///`uvm_info(get_type_name(),  $sformatf("Changed and output is   32'h%h", tr.r), UVM_LOW);
			ap.write(tr);
		end
	endtask 
	
endclass