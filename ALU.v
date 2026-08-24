
`timescale 1ns/1ps
`default_nettype none

// 32-bit arithmetic and logic unit.
// ALUControl encoding:
//   3'b000: ADD
//   3'b001: SUB
//   3'b010: AND
//   3'b011: OR
//   3'b101: signed set-less-than
module ALU(
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [2:0]  ALUControl,
    output reg  [31:0] Result,
    output reg         OverFlow,
    output reg         Carry,
    output wire        Zero,
    output wire        Negative
);

    localparam [2:0] ALU_ADD = 3'b000;
    localparam [2:0] ALU_SUB = 3'b001;
    localparam [2:0] ALU_AND = 3'b010;
    localparam [2:0] ALU_OR  = 3'b011;
    localparam [2:0] ALU_SLT = 3'b101;

    always @(*) begin
        Result   = 32'b0;
        Carry    = 1'b0;
        OverFlow = 1'b0;

        case (ALUControl)
            ALU_ADD: begin
                // Extend the addition by one bit to retain the unsigned carry.
                {Carry, Result} = {1'b0, A} + {1'b0, B};
                OverFlow = (~(A[31] ^ B[31])) & (Result[31] ^ A[31]);
            end

            ALU_SUB: begin
                // Two's-complement subtraction: A - B = A + ~B + 1.
                {Carry, Result} = {1'b0, A} + {1'b0, ~B} + 33'b1;
                OverFlow = (A[31] ^ B[31]) & (Result[31] ^ A[31]);
            end

            ALU_AND: Result = A & B;
            ALU_OR:  Result = A | B;
            ALU_SLT: Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;

            default: begin
                Result   = 32'b0;
                Carry    = 1'b0;
                OverFlow = 1'b0;
            end
        endcase
    end

    assign Zero     = (Result == 32'b0);
    assign Negative = Result[31];

endmodule

`default_nettype wire
