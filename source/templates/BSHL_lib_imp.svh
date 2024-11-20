`ifndef BSHL_LIB_IMP_SV
`define BSHL_LIB_IMP_SV

class BSHL_lib_imp extends BSHL_lib;

    task l_Notify_Int_seq_Test_completion();
        Notify_Int_seq_Test_completion();
    endtask

    task l_Request_Ext_seq_Test_start();
        Request_Ext_seq_Test_start();
    endtask

    task l_Notify_Ext_seq_Test_completion();
        Notify_Ext_seq_Test_completion();
    endtask

    task l_Request_Int_seq_Test_start();
        Request_Int_seq_Test_start();
    endtask

    task l_S_Recv_Seq_desc();
        S_Recv_Seq_desc();
    endtask

    function void l_S_Send_Result_back(input transaction_descriptor tr_desc_back);
        S_Send_Result_back(tr_desc_back);
    endfunction

    function int l_enable_Test();
        return 1;
    endfunction

    // add a new user-defined task phase
	function void l_add_my_phase();
		uvm_domain dm = uvm_domain::get_common_domain();
    	uvm_phase ph = dm.find(uvm_report_phase::get());
    	dm.add(uvm_user_phase::get(), null, ph, null);
	endfunction

endclass

`endif