// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  Description : BSHL_if is an interface class that declares a series of user-customizable functions or tasks.
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************

`ifndef BSHL_IF_SV
`define BSHL_IF_SV

	
interface class BSHL_if;

    pure virtual task i_PythonControlledRuntime(uvm_phase phase);
    pure virtual task i_BlockingWait_Int_seq_Test_start();
    pure virtual task i_BlockingWait_Ext_seq_Test_start();
    pure virtual function void i_enable_Int_seq_Test();
    pure virtual function void i_enable_Ext_seq_Test();
    pure virtual task i_do_seq(transaction_descriptor tr_desc);
	pure virtual task i_dispatch_loop();
	pure virtual function void i_add_to_seq_q(input transaction_descriptor tr_desc);
	pure virtual function void i_try_get_seq_done(ref bit valid, ref transaction_descriptor tr_desc);
	pure virtual function void i_all_seq_done(output bit done);
	pure virtual task i_wait_all_seq_done();
	pure virtual function void i_disable_run();
	pure virtual task i_wait_delay_ns(int unsigned time_in_ns);

endclass

`endif

//task: used for modeling behaviors and can include control flow constructs (if-else, case, loop), can encapsulate a series of procedural statements; do not return value
//function: used for computaion and always return a value. Can not contain delays, event control, or any other constructs that can suspend the execution
//a pure virtual function is a function declared within a base class that has no implementation and must be overridden by derived classes (overriden by BSHL_api.svh)