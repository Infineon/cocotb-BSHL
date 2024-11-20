// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  Description : BSHL_lib serves as a library that houses all the functions or tasks that users do not need to modify or rewrite. Users are not required to understand the internal implementation of these functions. Users can directly call functions from within this library.
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************

`ifndef BSHL_LIB_SV
`define BSHL_LIB_SV

virtual class BSHL_lib;

    virtual task l_Notify_Int_seq_Test_completion();
        //Notify_Int_seq_Test_completion();
    endtask

    virtual task l_Request_Ext_seq_Test_start();
        //Request_Ext_seq_Test_start();
    endtask

    virtual task l_Notify_Ext_seq_Test_completion();
        //Notify_Ext_seq_Test_completion();
    endtask

    virtual task l_Request_Int_seq_Test_start();
    //    Request_Int_seq_Test_start();
    endtask
    
    virtual task l_S_Recv_Seq_desc();
    //    S_Recv_Seq_desc();
    endtask
    
    virtual function void l_S_Send_Result_back(input transaction_descriptor tr_desc_back);
    //    S_Send_Result_back(tr_desc_back);
    endfunction
    
    virtual function int l_enable_Test();
    //    return 1;
    endfunction
    
    // add a new user-defined task phase
	virtual function void l_add_my_phase();
	//	uvm_domain dm = uvm_domain::get_common_domain();
    //	uvm_phase ph = dm.find(uvm_report_phase::get());
    //	dm.add(uvm_user_phase::get(), null, ph, null);
	endfunction
    
endclass

`endif