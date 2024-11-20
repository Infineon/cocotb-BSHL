`ifndef BSHL_API_SV
`define BSHL_API_SV

class BSHL_api extends my_test implements BSHL_if;

	int m_timeout_us = 50;
	int loop_counter = 0;

	internal_sequence seq0;
	external_sequence seq_py;

	`uvm_component_utils_begin(BSHL_api)
	//	`uvm_field_object(seq_py, UVM_DEFAULT)
	`uvm_component_utils_end

	my_env env;
	BSHL_lib lib;

	uvm_queue #(transaction_descriptor) m_seq_done_q = new(); 
	uvm_queue #(transaction_descriptor) m_seq_q = new();
	//UVM builtin class, provides a queue that allows users to store and manage items in FIFO manner; 
	//here the queue will store items of type: transaction_descriptor
	
	protected bit Int_seq_Test_start;
	protected bit m_enable;
	protected bit Ext_seq_Test_start;

	function new(string name = "BSHL_api", uvm_component parent = null);
		super.new(name, parent);
		Ext_seq_Test_start = 0;
		Int_seq_Test_start = 0;
		m_enable = 1;
		lib.l_add_my_phase();
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = my_env::type_id::create("env", this);
	endfunction

	extern virtual task i_PythonControlledRuntime(uvm_phase phase);
	extern virtual task run_phase(uvm_phase phase);

	extern virtual task i_BlockingWait_Int_seq_Test_start();
	extern virtual task i_BlockingWait_Ext_seq_Test_start();
	extern virtual function void i_enable_Int_seq_Test();
	extern virtual function void i_enable_Ext_seq_Test();

	extern virtual task i_do_seq(transaction_descriptor tr_desc);
	extern virtual task i_dispatch_loop();
	extern virtual function void i_add_to_seq_q(input transaction_descriptor tr_desc);
	extern virtual function void i_try_get_seq_done(ref bit valid, ref transaction_descriptor tr_desc);
	extern virtual function void i_all_seq_done(output bit done);
	extern virtual task i_wait_all_seq_done();
	extern virtual function void i_disable_run();
	extern virtual task i_wait_delay_ns(int unsigned time_in_ns);

endclass: BSHL_api

task BSHL_api::run_phase(uvm_phase phase);

	seq0 = internal_sequence::type_id::create("seq0", this); //:: the scope resolution operator, to access static members of an object or an instance
	seq0.repetitions = 30; // . the member access operator, to access non-static members
	seq0.starting_phase = phase;
	
	phase.raise_objection(this);

	// Using Python sequence to run the verification
	i_BlockingWait_Ext_seq_Test_start();
	if(Ext_seq_Test_start == 1) begin
		fork
			lib.l_S_Recv_Seq_desc();
			i_dispatch_loop();
		join
	end
	lib.l_Notify_Ext_seq_Test_completion();

	// Using SV self sequence to run the verification
	i_BlockingWait_Int_seq_Test_start();
	while (Int_seq_Test_start && (env.sb.percentage < 95)) begin
		seq0.start(env.api_seqr.seqr);
		seq0.repetitions = seq0.repetitions;
		`uvm_info(get_type_name(),  $sformatf("So far the percentage is: %f",env.sb.percentage), UVM_LOW);
	end
	`uvm_info(get_type_name(),  $sformatf("okay, now sv announces python that SV-vip is finished"), UVM_LOW);
	lib.l_Notify_Int_seq_Test_completion();

	phase.drop_objection(this);
endtask

// A new task phase which is after the report phase
// In this phase, raise an obejction and never drop it to block the sv-vip
task BSHL_api::i_PythonControlledRuntime(uvm_phase phase);
	phase.raise_objection(this);
	`uvm_info("TEST", $sformatf("In %s phase", phase.get_name()), UVM_LOW)
	#10;
	`uvm_info("SV_VIP", "is blocking to handover control to python.", UVM_LOW)
	report_summarize();
endtask

// Keep calling until get response and meanwhile consuming simulation time
task BSHL_api::i_BlockingWait_Int_seq_Test_start();
	while (!Int_seq_Test_start) begin
		#20ns
		`uvm_info(get_type_name(),  $sformatf("Requesting Int_seq_Test..."), UVM_LOW);
       	lib.l_Request_Int_seq_Test_start();
    end
endtask

task BSHL_api::i_BlockingWait_Ext_seq_Test_start();
	while (!Ext_seq_Test_start) begin
		#20ns
		`uvm_info(get_type_name(),  $sformatf("Requesting Ext_seq_Test..."), UVM_LOW);
		lib.l_Request_Ext_seq_Test_start();
	end
endtask

function void BSHL_api::i_enable_Int_seq_Test();
	Int_seq_Test_start = lib.l_enable_Test();
endfunction

function void BSHL_api::i_enable_Ext_seq_Test();
	Ext_seq_Test_start = lib.l_enable_Test();
endfunction

function void BSHL_api::i_add_to_seq_q(input transaction_descriptor tr_desc);
	m_seq_q.push_back(tr_desc);
endfunction

function void BSHL_api::i_try_get_seq_done(ref bit valid, ref transaction_descriptor tr_desc);
	if(m_seq_done_q.size()) begin
		tr_desc = m_seq_done_q.pop_front();
		valid = 1;
		return;
	end
	valid = 0;
endfunction

function void BSHL_api::i_all_seq_done(output bit done);
	done = ((m_seq_q.size() == 0) && (m_seq_done_q.size() > 0));
endfunction

task BSHL_api::i_wait_all_seq_done();
	var bit done;
	do begin
		#100ns;
		i_all_seq_done(done);
	end while(!done);
endtask

function void BSHL_api::i_disable_run();
	m_enable = 0;
endfunction

task BSHL_api::i_wait_delay_ns(int unsigned time_in_ns);
	#(1ns * time_in_ns);
endtask

task BSHL_api::i_dispatch_loop();
	`uvm_info(get_name(), "i_dispatch_loop", UVM_LOW)
	
	while(m_enable && loop_counter < 100) begin

		const var time timeout_value = 1us * m_timeout_us;
		transaction_descriptor next_seq;
		transaction_descriptor next_seq_copy;
		fork
			begin
				wait(m_seq_q.size() > 0);
				next_seq = m_seq_q.pop_front();
				next_seq_copy = next_seq;

				i_do_seq(next_seq);
				
				m_seq_done_q.push_back(next_seq_copy);
				`uvm_info(get_name(), "Note: putting py_seq into sv sequencer", UVM_LOW)
			end
			begin
				#timeout_value;
				`uvm_fatal(get_name(), "Note: Timeout processing sequence queue")
			end
			begin
				wait (m_enable == 0);
				`uvm_info(get_name(), "Note: dispatch_loop() has been stopped by caller", UVM_LOW)
			end
		join_any
		disable fork;
		loop_counter = loop_counter + 1;
	end
endtask

task BSHL_api::i_do_seq(transaction_descriptor tr_desc);
	var uvm_status_e status;
	var string seq_name = tr_desc.name;
	transaction_descriptor tr_desc_back;

	status = UVM_IS_OK;

	`uvm_info(get_name(), "Dispatching sequence", UVM_MEDIUM)

	$display("Name: %0s", tr_desc.name); //display without any padding
	$display("Rdnwr: %0b", tr_desc.rdnwr);
	$display("Address: %0h", tr_desc.addr);
	$display("Data[0]: %0h, Data[1]: %0h, Data[2]: %0h, Data[3]: %0h", 
			tr_desc.data[0], tr_desc.data[1], tr_desc.data[2], tr_desc.data[3]);
	$display("Status: %0s", tr_desc.status.name());

	case(seq_name)
		"random" : begin
			seq_py = external_sequence::type_id::create(seq_name);
			if(!seq_py.randomize() with{
				a == tr_desc.data[0];
				b == tr_desc.data[1];
				op == tr_desc.data[2];
			} ) `uvm_fatal("seq_py", "failed to randomize the sequence.");
			seq_py.start(env.api_seqr.seqr);
			`uvm_info(get_type_name(),  $sformatf("result can be used in api.svh: %0h", seq_py.result), UVM_LOW);
			tr_desc_back = tr_desc;
			tr_desc_back.data[3] = seq_py.result;
			//$display(tr_desc_back.data[3]);
			//$display(tr_desc_back.data[1]);
			lib.l_S_Send_Result_back(tr_desc_back);
		end
	endcase
	tr_desc.status = status;
endtask

`endif