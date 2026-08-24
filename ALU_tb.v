// SPDX-License-Identifier: Apache-2.0
// Copyright 2023 MERL-DSU
// Modified from the supplied source for this repository, 2026.

`timescale 1ns/1ps
`default_nettype none

// Directed ALU verification covering arithmetic, logic, signed comparison,
// status flags, overflow boundaries, and the unsupported-control default path.
module ALU_tb;

    reg  [31:0] A;
    reg  [31:0] B;
    reg  [2:0]  ALUControl;
    wire [31:0] Result;
    wire        OverFlow;
    wire        Carry;
    wire        Zero;
    wire        Negative;

    integer error_count;

    ALU dut (
        .A          (A),
        .B          (B),
        .ALUControl (ALUControl),
        .Result     (Result),
        .OverFlow   (OverFlow),
        .Carry      (Carry),
        .Zero       (Zero),
        .Negative   (Negative)
    );

`ifdef DUMP_VCD
    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, ALU_tb);
    end
`endif

    task run_case;
        input [255:0] test_name;
        input [31:0]  test_a;
        input [31:0]  test_b;
        input [2:0]   test_control;
        input [31:0]  expected_result;
        input         expected_carry;
        input         expected_overflow;
        reg           expected_zero;
        reg           expected_negative;
        begin
            A          = test_a;
            B          = test_b;
            ALUControl = test_control;
            #1;

            expected_zero     = (expected_result == 32'b0);
            expected_negative = expected_result[31];

            if ((Result   !== expected_result)   ||
                (Carry    !== expected_carry)    ||
                (OverFlow !== expected_overflow) ||
                (Zero     !== expected_zero)     ||
                (Negative !== expected_negative)) begin
                $display("FAIL %-24s A=%h B=%h R=%h/%h C=%b/%b V=%b/%b Z=%b/%b N=%b/%b",
                         test_name, A, B,
                         Result, expected_result,
                         Carry, expected_carry,
                         OverFlow, expected_overflow,
                         Zero, expected_zero,
                         Negative, expected_negative);
                error_count = error_count + 1;
            end
            else begin
                $display("PASS %-24s R=%h Z=%b N=%b C=%b V=%b",
                         test_name, Result, Zero, Negative, Carry, OverFlow);
            end
        end
    endtask

    initial begin
        error_count = 0;

        run_case("10 + 20",              32'd10,       32'd20,       3'b000, 32'd30,       1'b0, 1'b0);
        run_case("FFFFFFFF + 1",         32'hFFFFFFFF, 32'd1,        3'b000, 32'd0,        1'b1, 1'b0);
        run_case("signed add overflow",  32'h7FFFFFFF, 32'd1,        3'b000, 32'h80000000, 1'b0, 1'b1);
        run_case("7 - 3",                32'd7,        32'd3,        3'b001, 32'd4,        1'b1, 1'b0);
        run_case("3 - 7",                32'd3,        32'd7,        3'b001, 32'hFFFFFFFC, 1'b0, 1'b0);
        run_case("signed sub overflow",  32'h80000000, 32'd1,        3'b001, 32'h7FFFFFFF, 1'b1, 1'b1);
        run_case("AND",                  32'hF0F0AA55, 32'h0FF00F0F, 3'b010, 32'h00F00A05, 1'b0, 1'b0);
        run_case("OR",                   32'hF0F0AA55, 32'h0FF00F0F, 3'b011, 32'hFFF0AF5F, 1'b0, 1'b0);
        run_case("SLT: -1 < 1",          32'hFFFFFFFF, 32'd1,        3'b101, 32'd1,        1'b0, 1'b0);
        run_case("SLT: 5 < 4",           32'd5,        32'd4,        3'b101, 32'd0,        1'b0, 1'b0);
        run_case("unsupported control",  32'h12345678, 32'h89ABCDEF, 3'b111, 32'd0,        1'b0, 1'b0);

        if (error_count == 0) begin
            $display("TEST ALU PASSED");
            $finish;
        end
        else begin
            $fatal(1, "TEST ALU FAILED: %0d error(s)", error_count);
        end
    end

endmodule

`default_nettype wire
