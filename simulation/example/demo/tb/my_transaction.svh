// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************

class my_transaction_in extends uvm_sequence_item; //only this can use sequence 
	   // not always exist at run time 
					
	rand bit [31:0] a;
	rand bit [31:0] b;
	rand bit [2:0] op;
	
	function new(string name = "my_transaction_in");
		super.new(name);
	endfunction

	`uvm_object_utils_begin(my_transaction_in)
		`uvm_field_int(a, UVM_ALL_ON)
		`uvm_field_int(b, UVM_ALL_ON)
		`uvm_field_int(op, UVM_ALL_ON)		
	`uvm_object_utils_end 
	
/*  virtual function string convert2string;
		return $psprintf("data: %h", data);
	endfunction : convert2string
	
	virtual function void do_copy(uvm_object tr);
		my_transaction TR;
		if (tr == null)
			`uvm_fatal("my_transaction", "tr is null!!!");
		super.copy(tr);
		$cast (TR, tr);
		a = TR.a;
		b = TR.b;
		op = TR.op;
	endfunction : do_copy 
	*/
endclass 

class my_transaction_out extends uvm_sequence_item; 

	rand bit [31:0] r; 
	
	function new(string name = "my_transaction_out");
		super.new(name);	
	endfunction

	`uvm_object_utils_begin(my_transaction_out)
		`uvm_field_int(r, UVM_ALL_ON)
	`uvm_object_utils_end 
	
endclass 
