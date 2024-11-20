`ifndef BSHL_TEST_PKG_SV
`define BSHL_TEST_PKG_SV

package BSHL_test_pkg;
	import uvm_pkg::*;
    `include "uvm_macros.svh"
	
    `include "BSHL_user_extensions.svh"

	export "DPI-C" function enable_Int_seq_Test;
	export "DPI-C" function enable_Ext_seq_Test;

	import "DPI-C" context task Request_Int_seq_Test_start();
  	import "DPI-C" context task Notify_Int_seq_Test_completion();
	
	import "DPI-C" context task Request_Ext_seq_Test_start();
	import "DPI-C" context task Notify_Ext_seq_Test_completion();

	import "DPI-C" context task S_Recv_Seq_desc();
	import "DPI-C" function void S_Send_Result_back(input transaction_descriptor tr_desc_back);
	
 	export "DPI-C" function add_seq;
	export "DPI-C" task     wait_all_seq_done;
	export "DPI-C" function disable_run;
	export "DPI-C" function try_get_seq_done;
	export "DPI-C" task     wait_delay_ns;

	function void enable_Int_seq_Test();
		get_api();
		api.i_enable_Int_seq_Test();
	endfunction
	
	function void enable_Ext_seq_Test();
		get_api();
		api.i_enable_Ext_seq_Test();
	endfunction

	function void add_seq(input transaction_descriptor tr_desc);
		get_api();
		api.i_add_to_seq_q(tr_desc);
	endfunction

	task wait_all_seq_done();
		get_api();
		api.i_wait_all_seq_done();
	endtask

	function void disable_run();
		get_api();
		api.i_disable_run();
	endfunction

	function bit try_get_seq_done(output transaction_descriptor tr_desc);
		var bit valid;
		get_api();
		api.i_try_get_seq_done(valid, tr_desc);
	endfunction

	task wait_delay_ns(int unsigned time_in_ns);
		get_api();
		api.i_wait_delay_ns(time_in_ns);
	endtask

	function void get_api();
		var uvm_component comp;
		var uvm_root root;
		
		if(api != null)
			return;
		
		root = uvm_root::get();
		comp = root.find("uvm_test_top");
		if(comp != null) begin
			if(!$cast(api, comp)) begin
				`uvm_fatal("BSHL_test_pkg", "get_api(): can not cast test")
			end
		end
		else begin
			`uvm_fatal("BSHL_test_pkg", "get_api(): can not find component")
		end
	endfunction

endpackage: BSHL_test_pkg

`endif // BSHL_TEST_PKG_SV