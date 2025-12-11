module servo_pwm #(
    parameter integer INPUT_FREQ   = 50_000_000,
    parameter integer REFRESH_HZ   = 50,
    parameter integer MIN_PULSE_NS = 1_000_000,
    parameter integer MAX_PULSE_NS = 2_000_000
) (
    input  wire clk,
    input  wire rst,
    input  wire [9:0] duty_level,
    output wire pwm_out
);
    localparam integer PERIOD_COUNT = INPUT_FREQ / REFRESH_HZ;
    // Avoid overflow in parameter arithmetic by reducing magnitude before multiply.
    localparam integer MIN_COUNT = (INPUT_FREQ / 1_000_000) * (MIN_PULSE_NS / 1000);
    localparam integer MAX_COUNT = (INPUT_FREQ / 1_000_000) * (MAX_PULSE_NS / 1000);

    reg  [31:0] cnt;
    wire [31:0] high_count = MIN_COUNT + ((MAX_COUNT - MIN_COUNT) * duty_level) / 1000;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 32'd0;
        end else if (cnt >= PERIOD_COUNT - 1) begin
            cnt <= 32'd0;
        end else begin
            cnt <= cnt + 32'd1;
        end
    end

    assign pwm_out = (cnt < high_count);
endmodule
