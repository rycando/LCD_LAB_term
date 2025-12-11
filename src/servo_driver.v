// servo_driver.v
// 50MHz 클록 기준 20ms 프레임(1,000,000카운트)에서 1.0~2.0ms 하이 펄스를 발생.

module servo_driver #(
    parameter integer FRAME_TICKS     = 1_000_000, // 20ms @ 50MHz
    parameter integer MIN_PULSE_TICK  = 50_000,    // 1.0ms @ 50MHz
    parameter integer MAX_PULSE_TICK  = 100_000    // 2.0ms @ 50MHz
) (
    input  wire        clk,
    input  wire        rst,         // active-high, async
    input  wire [9:0]  duty_level,  // 0~1000 → 1.0~2.0ms
    output wire        pwm_out
);
    reg [19:0] cnt; // 0~1,000,000-1 카운트
    wire [31:0] high_count;

    // 조합으로 듀티 계산: 프레임 시작에서 하이 유지
    assign high_count = MIN_PULSE_TICK +
                        ((MAX_PULSE_TICK - MIN_PULSE_TICK) * duty_level) / 1000;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 20'd0;
        end else if (cnt == FRAME_TICKS - 1) begin
            cnt <= 20'd0;
        end else begin
            cnt <= cnt + 20'd1;
        end
    end

    assign pwm_out = (cnt < high_count);
endmodule
