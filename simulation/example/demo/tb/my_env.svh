// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************

class my_env extends uvm_env;
 `uvm_component_utils(my_env)
	
	my_agent i_agent;
	my_agent o_agent_dut;
	my_agent o_agent_ref;
		
	scoreboard sb;
	api_virtual_sequencer api_seqr;

	uvm_event transaction_changed;

/*	uvm_tlm_analysis_fifo #(my_transaction_in) in_agt_fifo;
	uvm_tlm_analysis_fifo #(my_transaction_out) out_agt_exp_fifo;
	uvm_tlm_analysis_fifo #(my_transaction_out) out_agt_act_fifo;
*/			
	function new(string name = "my_env", uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase); 

		i_agent = my_agent::type_id::create("i_agent", this);
		o_agent_dut = my_agent::type_id::create("o_agent_dut", this);
		o_agent_ref = my_agent::type_id::create("o_agent_ref", this);
		
		i_agent.is_active = UVM_ACTIVE;
		o_agent_dut.is_active = UVM_PASSIVE;
		o_agent_ref.is_active = UVM_PASSIVE;
				
		sb = scoreboard::type_id::create("sb", this);
		api_seqr = api_virtual_sequencer::type_id::create("api_seqr", this);

		transaction_changed = new("transaction_changed");
   		uvm_config_db#(uvm_event)::set(this, "*", "transaction_changed", transaction_changed);

	/*	in_agt_fifo = new("in_agt_fifo", this);
		out_agt_exp_fifo = new("out_agt_exp_fifo", this);
		out_agt_act_fifo = new("out_agt_act_fifo", this);
	*/		
		`uvm_info(get_type_name(),"build phase is called", UVM_LOW);
	endfunction	
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
	/*	i_agent.ap.connect(in_agt_fifo.analysis_export); //connect i_agent with scoreboard = connect monitor with scoreboard
		sb.in_port.connect(in_agt_fifo.blocking_get_export);

		o_agent_ref.ap_o.connect(out_agt_exp_fifo.analysis_export); // connect ref_monitor with scoreboard
		sb.exp_port.connect(out_agt_exp_fifo.blocking_get_export);
		
		o_agent_dut.ap_o.connect(out_agt_act_fifo.analysis_export); // connect dut_monitor with scoreboard
		sb.act_port.connect(out_agt_act_fifo.blocking_get_export);
	*/
		i_agent.ap.connect(sb.in_monitor_imp);
		o_agent_ref.ap_o.connect(sb.out_ref_monitor_imp); 
		o_agent_dut.ap_o.connect(sb.out_act_monitor_imp);
		api_seqr.seqr = i_agent.seqr;
		api_seqr.state_mon.ap.connect(i_agent.seqr.imp);
		//i_agent.ap.connect(api_seqr.ap_i);
		o_agent_dut.ap_o.connect(api_seqr.state_mon.out_state_monitor_imp);
	/*	
		uvm_config_db #(sequencer)::set(this, "*", "seqr", i_agent.seqr);
		uvm_config_db #(external_sequencer)::set(this, "*", "ext_seqr", i_agent_ext.ext_seqr);
	*/
	endfunction
		
/*	connect_phase(simplified)
	
	(end of elaboration phase in virtual sequencer is not needed)
*/
		
endclass : my_env 


