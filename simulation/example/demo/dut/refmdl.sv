// **************************************************************************
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  Description : ref model
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//  *****************************************************************************

`timescale 1ns /1ps
module ref_model(clk, a,b, op, r);

    input bit clk;
    input logic [31:0]  a;
    input logic [31:0] b;
    input logic [2:0]  op;
    output bit [31:0]  r;

	reg [31:0] aa,bb;
	
always@(posedge clk)
      begin
	    aa <= a;
	    bb <= b;
        case(op)
        3'b000: r <= aa+bb;
        3'b001: r <= aa-bb;
        3'b010: r <= ~aa;
        3'b011: r <= ~(aa&bb);
        3'b100: r <= ~(aa|bb);
        3'b101: r <= aa&bb;
        3'b110: r <= aa|bb;
        3'b111: r <= aa^bb;
        default:
            begin
                r<=32'h0;
                $display("unknown operation");
            end
       endcase
     end

endmodule
        

