// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************

class sequencer extends uvm_sequencer #(my_transaction_in);
    `uvm_component_utils(sequencer)
	uvm_analysis_imp#(my_transaction_out, sequencer) imp;
	virtual interface my_if_in in_if;
	logic [31:0] result_temp = 32'b0;
	my_transaction_out o_queue[$];
	my_transaction_out o_copy, o_temp;


	function new(string name, uvm_component parent);
		super.new(name, parent);
		imp = new("imp", this);
		`uvm_info(get_type_name(), "New Phase", UVM_LOW);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		o_copy = my_transaction_out::type_id::create("o_copy");
		o_temp = my_transaction_out::type_id::create("o_temp");
		if(!uvm_config_db #(virtual my_if_in)::get(this, "", "vif_in", in_if)) begin
			`uvm_fatal(get_name(), "configDB: could not find my_if_in");
		end
	endfunction

	function void write(my_transaction_out tr);
			$display("SEQR received the tr %0h", tr);
			$display("tr.r is %h", tr.r);
			o_copy.copy(tr);
			$display("o_copy.r is %h", o_copy.r);
			o_queue.push_front(o_copy);
			result_temp = tr.r;
			$display("result_temp is %h", result_temp);
	endfunction

	task get_result (output logic [31:0] result);
			$display("result_temp is %h", result_temp);
			result = result_temp;
        	$display("give the result %h", result);
			o_temp = o_queue.pop_front();
			$display("o_temp.r is %h", o_temp.r);
	endtask
	/*
	task get_result_from_mon(output logic [31:0] result);
		my_transaction_out trans_o;
		bit success;
		success = seqr_fifo_out.try_get(trans_o);
		if(success) begin
			result = trans_o.r;
		end
	endtask
	*/
endclass

//`uvm_analysis_imp_decl(_in_state_monitor)
`uvm_analysis_imp_decl(_out_state_monitor)
class state_monitor extends uvm_monitor;

	`uvm_component_utils(state_monitor)
	//uvm_analysis_imp_in_state_monitor #(my_transaction_in, state_monitor) in_state_monitor_imp;
	uvm_analysis_imp_out_state_monitor #(my_transaction_out, state_monitor) out_state_monitor_imp;
	uvm_analysis_port #(my_transaction_out) ap;

	//my_transaction_out output_queue[$];
	//my_transaction_in input_queue[$];  

	//my_transaction_out get_output;
	//my_transaction_in get_input;

	function new(string name = "state_monitor", uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		//in_state_monitor_imp = new("in_state_monitor_imp", this);
		out_state_monitor_imp = new("out_state_monitor_imp", this);
		ap = new("ap", this);
		//get_input = my_transaction_in::type_id::create("get_input", this);
		//get_output = my_transaction_out::type_id::create("get_output", this);
	endfunction

	//function void write_in_state_monitor(my_transaction_in tr);
	//	input_queue.push_back(tr);
	//endfunction

	function void write_out_state_monitor(my_transaction_out tr);
		$display("State_Mon received the tr %0h", tr);
		ap.write(tr);
	endfunction
	/*
	task get_result(output logic [31:0] result);
			get_output = output_queue.pop_front();
            result = get_output.r;
            $display("give the result %0h ", result);
    endtask 
	*/
endclass


class api_virtual_sequencer extends uvm_sequencer;
	sequencer seqr;
	state_monitor state_mon;
	//uvm_analysis_export #(my_transaction_in) ap_i;
	//uvm_analysis_export #(my_transaction_out) ap_o;
	`uvm_component_utils(api_virtual_sequencer)

	function new(string name = "api_virtual_sequencer", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		seqr = sequencer::type_id::create("seqr", this);
		state_mon = state_monitor::type_id::create("state_monitor", this);
		//ap_o = new("ap_o", this);
		//ap_i = new("ap_i", this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		$display("here?");
		state_mon.ap.connect(seqr.imp);
	endfunction

endclass

