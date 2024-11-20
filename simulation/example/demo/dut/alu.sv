// **************************************************************************
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  Description : ALU DUT
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//  *****************************************************************************


module alu(
    input logic clk, // clock
    input logic signed [31:0] a, b, // input
    input logic [2:0] op, // Operation
    output logic signed [31:0] r // output
);

logic signed [31:0] R1, R2, R3;

always @(posedge clk) begin
	R1 <= a;
	R2 <= b;
    case (op)
        3'b000: R3 <= R1 + R2;     // addition
        3'b001: R3 <= R1 - R2;     // subtraction
        3'b010: R3 <= ~R1;           // NOT
        3'b011: R3 <= ~(R1 & R2);  // NOR
        3'b100: R3 <= ~(R1 | R2);  // NAND
        3'b101: R3 <= R1 & R2;     // AND
        3'b110: R3 <= R1 | R2;     // OR
        3'b111: R3 <= R1 ^ R2;     // XOR
        default: R3 <= 32'bx;          // 'x' (unknown) for other cases
    endcase
end

assign r = R3;

endmodule

