// servo_lr_10khz.v
// 10kHz 입력 기준 20ms(200틱) 프레임, 좌/우 제어로 0°/90°/180° 선택.
// FRAME_TICKS=200 → 20ms@10kHz, 기본 펄스(틱) 0°=7, 90°=15, 180°=23 → 약 0.7/1.5/2.3ms.

module servo_lr_10khz #(
    parameter integer FRAME_TICKS     = 200,
    parameter integer PULSE_TICKS_0   = 7,
    parameter integer PULSE_TICKS_90  = 15,
    parameter integer PULSE_TICKS_180 = 23
) (
    input  wire clk,     // 10kHz
    input  wire rst,     // active-high, async
    input  wire l_ctrl,  // 1이면 0° 방향
    input  wire r_ctrl,  // 1이면 180° 방향
    output wire servo
);
    reg [15:0] cnt;
    reg [15:0] current_pulse;

    // 각도 선택: l_ctrl=1,r_ctrl=1이면 이전 상태 유지(버튼 동시 입력 보존)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_pulse <= PULSE_TICKS_90;
        end else if (l_ctrl && !r_ctrl) begin
            current_pulse <= PULSE_TICKS_0;
        end else if (!l_ctrl && r_ctrl) begin
            current_pulse <= PULSE_TICKS_180;
        end else if (!l_ctrl && !r_ctrl) begin
            current_pulse <= PULSE_TICKS_90;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 16'd0;
        end else if (cnt >= FRAME_TICKS - 1) begin
            cnt <= 16'd0;
        end else begin
            cnt <= cnt + 16'd1;
        end
    end

    assign servo = (cnt < current_pulse);
endmodule
