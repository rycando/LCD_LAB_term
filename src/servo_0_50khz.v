// servo_0_50khz.v
// 50kHz 입력 기준 20ms(1000틱) 프레임, 약 0.7ms 하이 출력 고정.
// FRAME_TICKS=1000 → 20ms@50kHz, PULSE_TICKS 기본값 35 → 약 0.7ms.

module servo_0_50khz #(
    parameter integer FRAME_TICKS = 1000,
    parameter integer PULSE_TICKS = 35
) (
    input  wire clk,   // 50kHz
    input  wire rst,   // active-high, async
    output wire servo  // SERVO_CTRL로 연결
);
    reg [15:0] cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 16'd0;
        end else if (cnt >= FRAME_TICKS - 1) begin
            cnt <= 16'd0;
        end else begin
            cnt <= cnt + 16'd1;
        end
    end

    assign servo = (cnt < PULSE_TICKS);
endmodule
