`ifndef BSHL_USER_EXTENSIONS_SV
`define BSHL_USER_EXTENSIONS_SV

	typedef struct{ 
		string name;
    	bit rdnwr;
    	int unsigned addr;
    	int unsigned data[4];
    	uvm_status_e status;
	} transaction_descriptor;
	
	import rival2_tb_pkg::*;
  	import spi_if_v2_pkg::*;
  	import sys_if_pkg::*;
  	import rival2_sbif_pkg::*;

	import BSHL_pkg::*;

	`include "seq_sandbox.svh"
	`include "rival2_tb_test_common.svh"
	`include "test_sandbox.svh"	

	// `include "BSHL_api.svh"
	`include "BSHL_lib_imp.svh"
	`include "external_sequence.svh"
	`include "sandbox_api.svh"

	sandbox_api api;

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
    	sandbox_api TEST;
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

`endif