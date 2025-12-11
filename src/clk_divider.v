// clk_divider.v
// 50MHz 입력 기준으로 다중 주기 펄스를 생성하는 모듈

module clk_divider #(
    parameter integer INPUT_FREQ = 50_000_000
) (
    input  wire clk,
    input  wire rst,
    output reg  tick_1hz,
    output reg  tick_10hz,
    output reg  tick_1khz
);
    localparam integer DIV_1HZ   = INPUT_FREQ;
    localparam integer DIV_10HZ  = INPUT_FREQ / 10;
    localparam integer DIV_1KHZ  = INPUT_FREQ / 1000;

    integer cnt_1hz;
    integer cnt_10hz;
    integer cnt_1khz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_1hz  <= 0;
            tick_1hz <= 1'b0;
        end else if (cnt_1hz >= DIV_1HZ - 1) begin
            cnt_1hz  <= 0;
            tick_1hz <= 1'b1;
        end else begin
            cnt_1hz  <= cnt_1hz + 1;
            tick_1hz <= 1'b0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_10hz  <= 0;
            tick_10hz <= 1'b0;
        end else if (cnt_10hz >= DIV_10HZ - 1) begin
            cnt_10hz  <= 0;
            tick_10hz <= 1'b1;
        end else begin
            cnt_10hz  <= cnt_10hz + 1;
            tick_10hz <= 1'b0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_1khz  <= 0;
            tick_1khz <= 1'b0;
        end else if (cnt_1khz >= DIV_1KHZ - 1) begin
            cnt_1khz  <= 0;
            tick_1khz <= 1'b1;
        end else begin
            cnt_1khz  <= cnt_1khz + 1;
            tick_1khz <= 1'b0;
        end
    end
endmodule
