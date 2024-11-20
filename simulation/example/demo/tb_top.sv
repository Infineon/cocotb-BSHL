// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************

`timescale 1ns /1ps
import uvm_pkg::*;
import BSHL_test_pkg::*;

module tb_top;
	my_if_in input_if();
	my_if_out output_if();
	my_if_out output_if_ref();

	alu dut(.clk(input_if.clk),
			.a(input_if.a),
			.b(input_if.b),
			.op(input_if.op),
			.r(output_if.r));
	
	ref_model rm(.clk(input_if.clk),
			.a(input_if.a),
			.b(input_if.b),
			.op(input_if.op),
			.r(output_if_ref.r));
		
	initial begin 
	/*	uvm_config_db#(virtual dut_if_in)::set(null, "uvm_test_top.t_env.i_agent.drv", "vif_in", input_if);
		uvm_config_db#(virtual dut_if_in)::set(null, "uvm_test_top.t_env.i_agent.in_mon", "vif_in", input_if);
		uvm_config_db#(virtual dut_if_in)::set(null, "uvm_test_top.t_env.o_agent_dut.out_mon", "vif_in", input_if);
		uvm_config_db#(virtual dut_if_in)::set(null, "uvm_test_top.t_env.o_agent_ref.out_mon", "vif_in", input_if);
	cooresponds to the following line 	
	*/		
		uvm_config_db#(virtual my_if_in)::set(null, "*", "vif_in", input_if);
		uvm_config_db#(virtual my_if_out)::set(null, "uvm_test_top.env.o_agent_dut.out_mon", "vif_out", output_if);
		uvm_config_db#(virtual my_if_out)::set(null, "uvm_test_top.env.o_agent_ref.out_mon", "vif_out", output_if_ref);
	
		run_test("BSHL_api");

	end 
	
	initial begin 	
	  input_if.clk <= 1'b0;
	end 

	always begin	
	    input_if.r <= output_if.r;
 	    #10 input_if.clk = ~input_if.clk ;
	end
	
endmodule 	

