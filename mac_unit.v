module mac_unit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output reg  [15:0] product
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            product <= 16'h0000;
        else
            product <= a * b;
    end

end
