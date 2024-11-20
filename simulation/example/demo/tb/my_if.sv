// **************************************************************************
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//  *****************************************************************************

`timescale 1ns /1ps
interface my_if_in();
        bit clk;
        logic [31:0] a;
        logic [31:0] b;
        logic [2:0] op;
        logic [31:0] r; 

        task get_result(output logic [31:0] result);
        
            //@(posedge clk);
            //$display("give the a %0h ", a);
            //$display("give the r %0h ", r);
            result = r;
            //$display("give the R %0h ", r);
            $display("give the result %0h ", result);
        endtask 

endinterface

interface my_if_out();

        logic [31:0] r;

endinterface

