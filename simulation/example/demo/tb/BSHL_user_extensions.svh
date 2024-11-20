// **************************************************************************
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//  *****************************************************************************

`ifndef BSHL_USER_EXTENSIONS_SV
`define BSHL_USER_EXTENSIONS_SV

	import BSHL_pkg::*;
	import my_uvm_pkg::*;

    `include "my_test.svh"

	`include "external_sequence.svh"
	`include "BSHL_lib_imp.svh"
	`include "BSHL_api.svh"

	BSHL_api api;

	// PythonControlledRuntime phase declaration
class uvm_user_phase extends uvm_task_phase;
	protected function new(string name="PythonControlledRuntime");
		super.new(name);
	endfunction
	
	static const string type_name = "uvm_user_phase";
	virtual function string get_type_name();
		return type_name;
	endfunction

	virtual task exec_task(uvm_component comp, uvm_phase phase);
    	BSHL_api TEST;
    	if ($cast(TEST, comp))
      		TEST.i_PythonControlledRuntime(phase);
  	endtask

	//create a singleton object that can be accessed elsewhere
	static uvm_user_phase m_inst;

	static function uvm_user_phase get();
		if(m_inst == null)
			m_inst = new;
		return m_inst;
	endfunction
endclass

`endif //BSHL_USER_EXTENSIONS_SV