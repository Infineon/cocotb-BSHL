class external_sequence extends uvm_sequence #(my_transaction_in);

	rand bit [31:0] a;
	rand bit [31:0] b;
	rand bit [2:0] op; 
	my_transaction_in in_trans;
	rand bit [31:0] result;

    `uvm_object_utils(external_sequence)
	`uvm_declare_p_sequencer(sequencer)
	//`uvm_declare_p_sequencer(api_virtual_sequencer)

    function new(string name = "external_sequence");
        super.new(name);
    endfunction

	virtual task body();
		in_trans = my_transaction_in::type_id::create("in_trans");
		start_item(in_trans);
		if(!in_trans.randomize() with { a == local::a; b == local::b; op == local::op; } )
			`uvm_fatal("seq_py", {get_full_name(), ".in_trans: contradiction"})
		finish_item(in_trans);
		p_sequencer.get_result(result);
		//p_sequencer.get_result_from_mon(result);
		//p_sequencer.state_mon.get_result(result);
		//p_sequencer.in_if.get_result(result);
		`uvm_info(get_type_name(),  $sformatf("result received: %0h",result), UVM_LOW);
		///get_response(in_trans);

	endtask

endclass