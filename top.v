// FILE: top.v
module top (
    input  wire clk_100mhz,
    input  wire rst_btn,
    input  wire btn_accel,
    input  wire btn_decel,
    input  wire [2:0] gear_sw,
    output wire servo_pwm,
    output wire [7:0] speed_fnd_sel,
    output wire [7:0] speed_fnd_seg,
    output wire [7:0] gear_seg,
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

    // Debounce and autorepeat for buttons
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

    autorepeat #(
        .INITIAL_HOLD_CYCLES(10'd300), // 300ms 지연 후 반복 시작 (1kHz 기준)
        .REPEAT_CYCLES(10'd150)        // 150ms 주기로 반복 펄스 생성
    ) u_ar_accel (
        .clk(clk_1khz),
        .rst(rst_clean),
        .level_in(accel_clean),
        .pulse_out(accel_pulse)
    );

    autorepeat #(
        .INITIAL_HOLD_CYCLES(10'd300),
        .REPEAT_CYCLES(10'd150)
    ) u_ar_decel (
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

    // FND display: 속도 8자리, 기어 단일 7세그
    wire [31:0] speed_fnd_value;
    assign speed_fnd_value = {24'd0, max_level, speed_level};

    speed_fnd_controller #(
        .CLK_FREQ(1_000),
        .REFRESH_HZ(500)
    ) u_speed_fnd_ctrl (
        .clk(clk_1khz),
        .rst(rst_clean),
        .value(speed_fnd_value),
        .fnd_sel(speed_fnd_sel),
        .fnd_seg(speed_fnd_seg)
    );

    gear_display u_gear_display (
        .gear(gear_sel),
        .gear_seg(gear_seg)
    );

    // RPM 상태 단계와 LED 표현 (RGB + 바그래프)
    localparam [1:0] RPM_NORMAL  = 2'd0;
    localparam [1:0] RPM_CAUTION = 2'd1;
    localparam [1:0] RPM_DANGER  = 2'd2;

    reg [1:0] rpm_stage;
    reg [2:0] rpm_rgb;
    reg [4:0] rpm_bar;

    wire [6:0] scaled_speed = speed_level * 3'd5;
    wire [6:0] threshold_1  = {3'b000, max_level};
    wire [6:0] threshold_2  = threshold_1 << 1;          // 2x
    wire [6:0] threshold_3  = threshold_1 + threshold_2; // 3x
    wire [6:0] threshold_4  = threshold_2 << 1;          // 4x

    always @(*) begin
        if (speed_level >= max_level) begin
            rpm_stage = RPM_DANGER;
        end else if (speed_level >= {1'b0, max_level[3:1]}) begin
            rpm_stage = RPM_CAUTION;
        end else begin
            rpm_stage = RPM_NORMAL;
        end
    end

    always @(*) begin
        case (rpm_stage)
            RPM_DANGER:  rpm_rgb = 3'b100; // Red: 위험 단계
            RPM_CAUTION: rpm_rgb = 3'b110; // Yellow: 주의 단계
            default:     rpm_rgb = 3'b010; // Green: 정상 단계
        endcase
    end

    always @(*) begin
        if (max_level == 0) begin
            rpm_bar = 5'b0;
        end else begin
            rpm_bar[0] = (speed_level > 0);
            rpm_bar[1] = (scaled_speed >= threshold_1);
            rpm_bar[2] = (scaled_speed >= threshold_2);
            rpm_bar[3] = (scaled_speed >= threshold_3);
            rpm_bar[4] = (scaled_speed >= threshold_4);
        end
    end

    assign leds = {rpm_rgb, rpm_bar};
endmodule
