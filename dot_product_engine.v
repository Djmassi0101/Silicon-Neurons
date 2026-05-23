module dot_product_engine (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [7:0]  row [0:7],
    input  wire [7:0]  vec [0:7],
    output reg  [23:0] result,
    output reg         valid_out
);

    reg [15:0] prod [0:7];
    reg        valid_s1;

    reg [16:0] sum4 [0:3];
    reg        valid_s2;

    reg [17:0] sum2 [0:1];
    reg        valid_s3;

    always @(posedge clk or negedge rst_n) begin
        integer i;
        if (!rst_n) begin
            valid_s1 <= 0;
            for (i=0; i<8; i=i+1) prod[i] <= 0;
        end else begin
            valid_s1 <= valid_in;
            for (i=0; i<8; i=i+1)
                prod[i] <= row[i] * vec[i];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s2 <= 0;
            sum4[0]<=0; sum4[1]<=0; sum4[2]<=0; sum4[3]<=0;
        end else begin
            valid_s2 <= valid_s1;
            sum4[0] <= prod[0] + prod[1];
            sum4[1] <= prod[2] + prod[3];
            sum4[2] <= prod[4] + prod[5];
            sum4[3] <= prod[6] + prod[7];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s3 <= 0;
            sum2[0]<=0; sum2[1]<=0;
        end else begin
            valid_s3 <= valid_s2;
            sum2[0] <= sum4[0] + sum4[1];
            sum2[1] <= sum4[2] + sum4[3];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result    <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_s3;
            result    <= sum2[0] + sum2[1];
        end
    end

endmodule
