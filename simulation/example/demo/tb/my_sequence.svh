// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************


/**
 * Class: sequence
 * 
 * TODO: Add class documentation
 */
class internal_sequence extends uvm_sequence #(my_transaction_in);
 `uvm_object_utils(internal_sequence)
	
//  rand bit [31:0] a;
	my_transaction_in in_trans;
	int repetitions = 1;
	
	function new(string name = "internal_sequence");
		super.new(name);
	endfunction
	
	virtual task body();
    repeat (repetitions) begin 
  	  `uvm_do(in_trans); 
    end
    
	//	if (starting_phase !=null)
		//	starting_phase.raise_objection(this);
	
	//	`uvm_info("my_sequence", "send one transaction", UVM_LOW);
	
	
  	/*	uvm_do coresponds to the following 

			in_trans = new("in_trans");
			assert( in_trans.randomize());
			start_item(in_trans);
			finish_item(in_trans);
		*/ 
		
	
	//	if (starting_phase !=null)
		//	starting_phase.drop_objection(this);
	endtask 
		
endclass

