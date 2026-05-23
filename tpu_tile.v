module tpu_tile (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [63:0] matrix_row [0:7],
    input  wire [7:0]  vector [0:7],
    output wire [23:0] output_vec [0:7],
    output wire        valid_out
);

    wire [7:0] valid_outs;

    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : engine
            wire [7:0] row_elem [0:7];
            for (j = 0; j < 8; j = j + 1) begin : unpack
                assign row_elem[j] = matrix_row[i][j*8 +: 8];
            end

            dot_product_engine dpe (
                .clk      (clk),
                .rst_n    (rst_n),
                .valid_in (valid_in),
                .row      (row_elem),
                .vec      (vector),
                .result   (output_vec[i]),
                .valid_out(valid_outs[i])
            );
        end
    endgenerate

    assign valid_out = valid_outs[0];

endmodule
