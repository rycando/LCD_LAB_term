// button_debouncer.v
// 비동기 버튼/스위치 입력을 동기화 및 디바운스 처리

module button_debouncer #(
    parameter integer STABLE_COUNT = 5
) (
    input  wire clk,
    input  wire rst,
    input  wire tick_1khz,
    input  wire btn_in,
    output reg  btn_state,
    output reg  btn_rise,
    output reg  btn_fall
);
    reg sync_0;
    reg sync_1;
    reg prev_state;
    integer stable_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= btn_in;
            sync_1 <= sync_0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stable_cnt <= 0;
            btn_state  <= 1'b0;
            prev_state <= 1'b0;
            btn_rise   <= 1'b0;
            btn_fall   <= 1'b0;
        end else begin
            btn_rise <= 1'b0;
            btn_fall <= 1'b0;
            if (tick_1khz) begin
                if (sync_1 == btn_state) begin
                    stable_cnt <= 0;
                end else begin
                    if (stable_cnt >= STABLE_COUNT) begin
                        btn_state  <= sync_1;
                        btn_rise   <= (sync_1 & ~btn_state);
                        btn_fall   <= (~sync_1 & btn_state);
                        stable_cnt <= 0;
                    end else begin
                        stable_cnt <= stable_cnt + 1;
                    end
                end
            end
            prev_state <= btn_state;
        end
    end
endmodule
