// servo_pwm.v
// 50Hz 서보 제어 PWM. 입력 duty_level은 0~1000 범위이며 1.0~2.0ms 펄스로 변환

module servo_pwm #(
    parameter integer INPUT_FREQ   = 50_000_000,
    parameter integer REFRESH_HZ   = 50,
    parameter integer MIN_PULSE_NS = 1_000_000,
    parameter integer MAX_PULSE_NS = 2_000_000
) (
    input  wire clk,
    input  wire rst,
    input  wire [9:0] duty_level,
    output reg  pwm_out
);
    localparam integer PERIOD_COUNT = INPUT_FREQ / REFRESH_HZ;
    localparam integer MIN_COUNT    = (INPUT_FREQ * MIN_PULSE_NS) / 1_000_000_000;
    localparam integer MAX_COUNT    = (INPUT_FREQ * MAX_PULSE_NS) / 1_000_000_000;

    integer cnt;
    integer high_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt        <= 0;
            pwm_out    <= 1'b0;
            high_count <= MIN_COUNT;
        end else begin
            high_count <= MIN_COUNT + ((MAX_COUNT - MIN_COUNT) * duty_level) / 1000;
            if (cnt >= PERIOD_COUNT - 1) begin
                cnt     <= 0;
                pwm_out <= 1'b1;
            end else begin
                cnt <= cnt + 1;
                if (cnt >= high_count)
                    pwm_out <= 1'b0;
                else
                    pwm_out <= 1'b1;
            end
        end
    end
endmodule
