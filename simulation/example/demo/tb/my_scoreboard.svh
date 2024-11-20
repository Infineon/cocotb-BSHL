// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************

`uvm_analysis_imp_decl(_in_monitor)
//`uvm_analysis_imp_decl(_in_ext_monitor)
`uvm_analysis_imp_decl(_out_monitor_ref)
`uvm_analysis_imp_decl(_out_monitor_act)

class scoreboard extends uvm_scoreboard;
 	`uvm_component_utils(scoreboard)

	  uvm_analysis_imp_in_monitor # (my_transaction_in, scoreboard) in_monitor_imp;
//	  uvm_analysis_imp_in_ext_monitor # (my_transaction_in, scoreboard) in_ext_monitor_imp;
 	  uvm_analysis_imp_out_monitor_ref # (my_transaction_out, scoreboard) out_ref_monitor_imp; 
  	  uvm_analysis_imp_out_monitor_act # (my_transaction_out, scoreboard) out_act_monitor_imp;

  
	  my_transaction_out expect_queue[$];
	  my_transaction_out actual_queue[$];
	  my_transaction_in input_queue[$];

	  
	  my_transaction_out get_expect, get_actual, act_tr_copy, exp_tr_copy;
	  my_transaction_in get_input, in_tr_copy, get_temp;
	
	  bit result; 	
	  real percentage = 0;
   	  int counter = 0;
	  int exp_counter = 0;

/*************************************************************/
/***********     covergroup definition            *************/
/*************************************************************/
	covergroup cg_in;
		in_a: coverpoint get_input.a{ bins all_ones = {32'hFFFFFFFF};
				              bins all_zeros = {32'h0};
						          bins small_values = {[1:10000000]};             
                      bins medium_values = {[30000000:100000000]};
                      bins large_values = {[200000000:$]};
                      bins other_values = default;
					}

		in_b: coverpoint get_input.b{ bins all_ones = {32'hFFFFFFFF};
				              bins all_zeros = {32'h0};						      
                      bins small_values = {[1:10000000]};             
                      bins medium_values = {[30000000:100000000]};
                      bins large_values = {[200000000:$]};
                      bins other_values = default;
					}

		in_op: coverpoint get_input.op{ bins op_1[] = {[0:7]} ;
          }                               

    zeros_or_ones: cross in_a, in_b {
                     bins one_zero = binsof(in_a.all_ones) || binsof (in_b.all_zeros);
                     bins zero_one = binsof(in_a.all_zeros) || binsof (in_b.all_ones);
                     ignore_bins the_others = binsof(in_a.other_values) && binsof(in_b.other_values);
          }      

	endgroup: cg_in

  covergroup cg_trans;
		out_r: coverpoint get_input.op{ bins op_after_op[] = (7 => [4:6],1 );
				             bins noname = (1,2 => [3:5],7 );                 
                     bins same_op[] = (5 [*2]);
                     bins add = (0 => 5 [->2] => 0);
					}          
	endgroup: cg_trans

  covergroup cg_out;
		out_r: coverpoint get_expect.r{ bins special_points = {32'hFFFFFFFF,32'h0};				                
                     bins values = {[10:200000]};
                     bins values2 = {[700000:2000000]};
                     bins values3 = {[7000000:400000000]};
					}
	endgroup: cg_out



/*************************************************************/
/***********     scoreboard phases            *************/
/*************************************************************/
	 function new(string name = "scoreboard", uvm_component parent);
		super.new(name, parent);
		  cg_in = new;
		  cg_out =new;
      	  cg_trans = new;     
	 endfunction 

	 virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		in_monitor_imp = new("in_monitor_imp", this);
		//in_ext_monitor_imp = new("in_ext_monitor_imp", this);
		out_ref_monitor_imp = new("out_ref_monitor_imp", this);
		out_act_monitor_imp = new("out_act_monitor_imp", this);
		
		get_expect = my_transaction_out::type_id ::create("get_expect");		
		get_actual = my_transaction_out::type_id ::create("get_actual");
		get_input  = my_transaction_in::type_id ::create("get_input");
		act_tr_copy = my_transaction_out::type_id::create("act_tr_copy");
		exp_tr_copy = my_transaction_out::type_id::create("exp_tr_copy");
		in_tr_copy = my_transaction_in::type_id::create("in_tr_copy");
		get_temp = my_transaction_in::type_id::create("get_temp");
		
	 endfunction 


	  task run_phase(uvm_phase phase);
	
		`uvm_info(get_type_name(), "run phase is called", UVM_LOW);

		get_temp.a = 0;
		get_temp.b = 0;
		get_temp.op = 0;

		forever begin
			//`uvm_info(get_type_name(), "Waiting the queue to be filled...", UVM_LOW);
			wait((expect_queue.size()>0) && (actual_queue.size()>0) && (input_queue.size()>0));

		    	percentage = (cg_in.get_coverage()+cg_trans.get_coverage()+cg_out.get_coverage())/3;

				get_expect = expect_queue.pop_front();
				//get_expect.print();
				get_actual = actual_queue.pop_front();
				//get_actual.print();
				get_input = input_queue.pop_front();
				//get_input.print();
				
				result = get_expect.compare(get_actual);
				if (result) begin 
				    `uvm_info(get_type_name(), $sformatf("compare SUCCESSFULLY\n 32'h%h %0s  32'h%h  equals  32'h%h", get_temp.a, get_operation(get_temp.op),get_temp.b, get_actual.r), UVM_LOW);	
         			`uvm_info(get_type_name(), $sformatf("current coverage of input = %f", cg_in.get_coverage()), UVM_LOW);	
				end 
				else begin			
			 		`uvm_error(get_type_name(), "compare FAILED");
				end

				get_temp.copy(get_input);

			end
		`uvm_info(get_type_name(), "end of run phase", UVM_LOW);
	
	endtask 

	virtual function void extract_phase(uvm_phase phase);		
   	  	 super.extract_phase(phase);
         percentage = (cg_in.get_coverage()+cg_trans.get_coverage()+cg_out.get_coverage())/3;
	  	 `uvm_info(get_type_name(), $sformatf("current coverage of input = %f", cg_in.get_coverage()), UVM_LOW);
       `uvm_info(get_type_name(), $sformatf("current coverage of opeartion = %f", cg_trans.get_coverage()), UVM_LOW);
		   `uvm_info(get_type_name(), $sformatf("current coverage of output = %f", cg_out.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("current average coverage = %f", percentage), UVM_LOW);
       `uvm_info(get_type_name(), $sformatf("current counter = %d", counter), UVM_LOW);
	endfunction: extract_phase

     /********** get_operation is to decode from op to know which operation it is**/
     /*******************************************************************/
	 function string get_operation(bit [2:0] input_value);  		 
		string operation;
		case(input_value) 
		    3'b000: operation = "+";
			  3'b001: operation = "-";
			  3'b010: operation = "NOT";
			  3'b011: operation = "NAND";
			  3'b100: operation = "NOR";
			  3'b101: operation = "AND";
			  3'b110: operation ="OR";
			  3'b111: operation ="XOR";
			  default:operation ="no operation";
		  endcase 

	  return operation; 
	endfunction


  extern function void write_in_monitor(my_transaction_in tr);
 // extern function void write_in_ext_monitor(my_transaction_in tr);
  extern function void write_out_monitor_ref(my_transaction_out tr);
  extern function void write_out_monitor_act(my_transaction_out tr);
	
endclass 	
/*
  function void scoreboard::write_in_monitor(my_transaction_in tr);
		
		in_tr_copy.copy(tr);
		input_queue.push_back(in_tr_copy);

		cg_in.sample();
		cg_trans.sample();

  endfunction 
*/
  function void scoreboard::write_in_monitor(my_transaction_in tr);

	    counter = counter +1;
		`uvm_info(get_type_name(), $sformatf("in current counter = %d", counter), UVM_LOW);
		
		if(counter >= 4) begin
			in_tr_copy.copy(tr);
			input_queue.push_back(in_tr_copy);
			//in_tr_copy.print();

			cg_in.sample();
			cg_trans.sample();
		end
	//`uvm_info(get_type_name(), "write in monitor function called ", UVM_LOW);
	//`uvm_info(get_type_name(), $sformatf("input queue size: %d",input_queue.size()), UVM_LOW);
  endfunction 

  function void scoreboard::write_out_monitor_ref(my_transaction_out tr);

	if(counter >= 4) begin
		exp_tr_copy.copy(tr);
		expect_queue.push_back(exp_tr_copy);
		cg_out.sample();
		//exp_tr_copy.print();
	end

  endfunction 
  
  function void scoreboard::write_out_monitor_act(my_transaction_out tr);

	if(counter >= 4) begin
    	act_tr_copy.copy(tr);
    	actual_queue.push_back(act_tr_copy);
		//act_tr_copy.print();
	end

  endfunction  
