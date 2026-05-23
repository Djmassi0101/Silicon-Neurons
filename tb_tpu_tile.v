`timescale 1ns/1ps

module tb_tpu_tile;

    reg         clk, rst_n, valid_in;
    reg  [63:0] matrix_row [0:7];
    reg  [7:0]  vector [0:7];
    wire [23:0] output_vec [0:7];
    wire        valid_out;

    tpu_tile uut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .matrix_row(matrix_row),
        .vector    (vector),
        .output_vec(output_vec),
        .valid_out (valid_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/tpu.vcd");
        $dumpvars(0, tb_tpu_tile);
    end

    initial $monitor("t=%0t | valid_out=%b | out[0]=%0d out[1]=%0d out[2]=%0d",
                      $time, valid_out,
                      output_vec[0], output_vec[1], output_vec[2]);

    integer r, c;
    task set_row;
        input integer row_idx;
        input [7:0] e0,e1,e2,e3,e4,e5,e6,e7;
        begin
            matrix_row[row_idx] = {e7,e6,e5,e4,e3,e2,e1,e0};
        end
    endtask

    initial begin
        rst_n    = 0;
        valid_in = 0;
        for (r = 0; r < 8; r = r+1) begin
            matrix_row[r] = 64'd0;
            vector[r]     = 8'd0;
        end
        #12 rst_n = 1;
        set_row(0, 1,0,0,0,0,0,0,0);
        set_row(1, 0,1,0,0,0,0,0,0);
        set_row(2, 0,0,1,0,0,0,0,0);
        set_row(3, 0,0,0,1,0,0,0,0);
        set_row(4, 0,0,0,0,1,0,0,0);
        set_row(5, 0,0,0,0,0,1,0,0);
        set_row(6, 0,0,0,0,0,0,1,0);
        set_row(7, 0,0,0,0,0,0,0,1);
        for (r = 0; r < 8; r = r+1)
            vector[r] = r + 1;

        @(posedge clk); valid_in = 1;
        @(posedge clk); valid_in = 0;
        repeat(4) @(posedge clk);
        #1;

        $display("TEST 1: Identity x [1..8]");
        for (r = 0; r < 8; r = r+1)
            $display("  out[%0d]=%0d (expect %0d) %s",
                r, output_vec[r], r+1,
                (output_vec[r]==r+1) ? "PASS" : "FAIL");
        #20;
        for (r = 0; r < 8; r = r+1)
            matrix_row[r] = 64'h0101010101010101; // 8 ones packed
        for (r = 0; r < 8; r = r+1)
            vector[r] = 8'd1;

        @(posedge clk); valid_in = 1;
        @(posedge clk); valid_in = 0;
        repeat(4) @(posedge clk);
        #1;

        $display("TEST 2: All-ones x [1..1]");
        for (r = 0; r < 8; r = r+1)
            $display("  out[%0d]=%0d (expect 8) %s",
                r, output_vec[r],
                (output_vec[r]==24'd8) ? "PASS" : "FAIL");
        #20;
        for (r = 0; r < 8; r = r+1) begin
            matrix_row[r] = 64'd0;
            matrix_row[r][r*8 +: 8] = r + 1;  // diagonal element
        end
        for (r = 0; r < 8; r = r+1)
            vector[r] = 8'd1;

        @(posedge clk); valid_in = 1;
        @(posedge clk); valid_in = 0;
        repeat(4) @(posedge clk);
        #1;

        $display("TEST 3: Diagonal [1..8] x [1..1]");
        for (r = 0; r < 8; r = r+1)
            $display("  out[%0d]=%0d (expect %0d) %s",
                r, output_vec[r], r+1,
                (output_vec[r]==r+1) ? "PASS" : "FAIL");

        #50 $finish;
    end

endmodule
