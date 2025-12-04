// FILE: top.v
module top (
    input  wire clk_100mhz,
    input  wire rst_btn,
    input  wire btn_accel,
    input  wire btn_decel,
    input  wire [2:0] gear_sw,
    output wire servo_pwm,
    output wire [3:0] fnd_sel,
    output wire [7:0] fnd_seg,
    output wire [7:0] leds
);

    // Clock generation
    wire clk_1khz;
    wire clk_10khz;
    wire clk_1hz;

    clk_divider u_clk_div (
        .clk_100mhz(clk_100mhz),
        .rst(rst_btn),
        .clk_1khz(clk_1khz),
        .clk_10khz(clk_10khz),
        .clk_1hz(clk_1hz)
    );

    // Debounce and one-pulse for buttons
    wire rst_clean;
    wire accel_clean;
    wire decel_clean;

    debounce u_db_rst (
        .clk(clk_1khz),
        .rst(1'b0),
        .noisy_in(rst_btn),
        .clean_out(rst_clean)
    );

    debounce u_db_accel (
        .clk(clk_1khz),
        .rst(rst_clean),
        .noisy_in(btn_accel),
        .clean_out(accel_clean)
    );

    debounce u_db_decel (
        .clk(clk_1khz),
        .rst(rst_clean),
        .noisy_in(btn_decel),
        .clean_out(decel_clean)
    );

    wire accel_pulse;
    wire decel_pulse;

    one_pulse u_op_accel (
        .clk(clk_1khz),
        .rst(rst_clean),
        .level_in(accel_clean),
        .pulse_out(accel_pulse)
    );

    one_pulse u_op_decel (
        .clk(clk_1khz),
        .rst(rst_clean),
        .level_in(decel_clean),
        .pulse_out(decel_pulse)
    );

    // Gear control
    wire [2:0] gear_sel;
    gear_ctrl u_gear_ctrl (
        .gear_in(gear_sw),
        .gear_out(gear_sel)
    );

    // RPM control
    wire [3:0] speed_level;
    wire [3:0] max_level;
    rpm_ctrl u_rpm_ctrl (
        .clk(clk_1khz),
        .rst(rst_clean),
        .accel_pulse(accel_pulse),
        .decel_pulse(decel_pulse),
        .gear(gear_sel),
        .speed_level(speed_level),
        .max_level(max_level)
    );

    // Servo control based on RPM gauge
    wire servo_l_ctrl;
    wire servo_r_ctrl;

    servo_rpm_ctrl u_servo_rpm_ctrl (
        .clk(clk_10khz),
        .rst(rst_clean),
        .speed_level(speed_level),
        .max_level(max_level),
        .l_ctrl(servo_l_ctrl),
        .r_ctrl(servo_r_ctrl)
    );

    // Servo control (predefined)
    servo u_servo (
        .clk(clk_10khz),
        .rst(rst_clean),
        .l_ctrl(servo_l_ctrl),
        .r_ctrl(servo_r_ctrl),
        .servo(servo_pwm)
    );

    // FND display
    wire [15:0] fnd_value;
    assign fnd_value = {4'd0, gear_sel, 1'b0, speed_level};

    fnd_controller #(
        .CLK_FREQ(1_000),
        .REFRESH_HZ(500)
    ) u_fnd_ctrl (
        .clk(clk_1khz),
        .rst(rst_clean),
        .value(fnd_value),
        .fnd_sel(fnd_sel),
        .fnd_seg(fnd_seg)
    );

    reg [2:0] rpm_rgb;

    always @(*) begin
        if (speed_level >= max_level) begin
            rpm_rgb = 3'b100; // Red: high RPM
        end else if (speed_level >= {1'b0, max_level[3:1]}) begin
            rpm_rgb = 3'b110; // Yellow: caution range
        end else begin
            rpm_rgb = 3'b010; // Green: normal RPM
        end
    end

    assign leds = {rpm_rgb, speed_level, 1'b0};
endmodule
