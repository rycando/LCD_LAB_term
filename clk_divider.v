// FILE: clk_divider.v
module clk_divider #(
    parameter integer INPUT_FREQ   = 100_000_000,
    parameter integer OUT1KHZ_FREQ = 1_000,
    parameter integer OUT10KHZ_FREQ = 10_000,
    parameter integer OUT1HZ_FREQ  = 1
) (
    input  wire clk_100mhz,
    input  wire rst,
    output reg  clk_1khz,
    output reg  clk_10khz,
    output reg  clk_1hz
);

    localparam integer DIV_1KHZ   = INPUT_FREQ / (2 * OUT1KHZ_FREQ);
    localparam integer DIV_10KHZ  = INPUT_FREQ / (2 * OUT10KHZ_FREQ);
    localparam integer DIV_1HZ    = INPUT_FREQ / (2 * OUT1HZ_FREQ);

    reg [$clog2(DIV_1KHZ):0] cnt_1khz;
    reg [$clog2(DIV_10KHZ):0] cnt_10khz;
    reg [$clog2(DIV_1HZ):0] cnt_1hz;

    always @(posedge clk_100mhz or posedge rst) begin
        if (rst) begin
            cnt_1khz <= 0;
            clk_1khz <= 1'b0;
        end else begin
            if (cnt_1khz == DIV_1KHZ - 1) begin
                cnt_1khz <= 0;
                clk_1khz <= ~clk_1khz;
            end else begin
                cnt_1khz <= cnt_1khz + 1'b1;
            end
        end
    end

    always @(posedge clk_100mhz or posedge rst) begin
        if (rst) begin
            cnt_10khz <= 0;
            clk_10khz <= 1'b0;
        end else begin
            if (cnt_10khz == DIV_10KHZ - 1) begin
                cnt_10khz <= 0;
                clk_10khz <= ~clk_10khz;
            end else begin
                cnt_10khz <= cnt_10khz + 1'b1;
            end
        end
    end

    always @(posedge clk_100mhz or posedge rst) begin
        if (rst) begin
            cnt_1hz <= 0;
            clk_1hz <= 1'b0;
        end else begin
            if (cnt_1hz == DIV_1HZ - 1) begin
                cnt_1hz <= 0;
                clk_1hz <= ~clk_1hz;
            end else begin
                cnt_1hz <= cnt_1hz + 1'b1;
            end
        end
    end

endmodule
