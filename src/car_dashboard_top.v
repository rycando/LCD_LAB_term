// car_dashboard_top.v
// 차량 계기판 기능을 통합한 최상위 모듈

module car_dashboard_top (
    input  wire clk_50mhz,
    input  wire dip_sw8_reset,
    input  wire [5:0] dip_sw_gears,
    input  wire key_accel_n,
    input  wire key_brake_n,
    output wire [7:0] led_rpm,
    output wire [7:0] seg_single,
    output wire [7:0] ar_seg,
    output wire [7:0] ar_sel,
    output wire servo_ctrl,
    output wire piezo_out,
    output wire f_led1_r,
    output wire f_led1_g,
    output wire f_led1_b,
    output wire f_led2_r,
    output wire f_led2_g,
    output wire f_led2_b,
    output wire f_led3_r,
    output wire f_led3_g,
    output wire f_led3_b,
    output wire f_led4_r,
    output wire f_led4_g,
    output wire f_led4_b
);
    wire rst = dip_sw8_reset;

    wire tick_1hz;
    wire tick_10hz;
    wire tick_1khz;

    clk_divider #(
        .INPUT_FREQ(50_000_000)
    ) u_divider (
        .clk(clk_50mhz),
        .rst(rst),
        .tick_1hz(tick_1hz),
        .tick_10hz(tick_10hz),
        .tick_1khz(tick_1khz)
    );

    wire deb_accel;
    wire deb_brake;

    button_debouncer u_accel (
        .clk(clk_50mhz),
        .rst(rst),
        .tick_1khz(tick_1khz),
        .btn_in(~key_accel_n),
        .btn_state(deb_accel),
        .btn_rise(),
        .btn_fall()
    );

    button_debouncer u_brake (
        .clk(clk_50mhz),
        .rst(rst),
        .tick_1khz(tick_1khz),
        .btn_in(~key_brake_n),
        .btn_state(deb_brake),
        .btn_rise(),
        .btn_fall()
    );

    wire [2:0] gear_level;
    gear_selector u_gear (
        .rst(rst),
        .gear_sw(dip_sw_gears),
        .gear_level(gear_level)
    );

    wire [8:0] speed_kmh;
    wire [13:0] rpm;
    wire overload;
    engine_model u_engine (
        .clk(clk_50mhz),
        .rst(rst),
        .tick_10hz(tick_10hz),
        .throttle(deb_accel),
        .brake(deb_brake),
        .gear(gear_level),
        .speed_kmh(speed_kmh),
        .rpm(rpm),
        .overload(overload)
    );

    // rpm LED: rpm 비율을 8단계로 분할
    reg [7:0] led_level;
    always @(*) begin
        if (rpm < 1000)
            led_level = 8'b0000_0001;
        else if (rpm < 2500)
            led_level = 8'b0000_0011;
        else if (rpm < 4000)
            led_level = 8'b0000_0111;
        else if (rpm < 5500)
            led_level = 8'b0000_1111;
        else if (rpm < 6500)
            led_level = 8'b0001_1111;
        else if (rpm < 7200)
            led_level = 8'b0011_1111;
        else if (rpm < 7800)
            led_level = 8'b0111_1111;
        else
            led_level = 8'b1111_1111;
    end
    assign led_rpm = led_level;

    // Full Color LED 상태
    reg color_r;
    reg color_g;
    reg color_b;
    always @(*) begin
        if (rpm < 5500) begin
            color_r = 1'b0;
            color_g = 1'b1;
            color_b = 1'b1;
        end else if (rpm < 7000) begin
            color_r = 1'b1;
            color_g = 1'b1;
            color_b = 1'b0;
        end else begin
            color_r = 1'b1;
            color_g = 1'b0;
            color_b = 1'b0;
        end
    end

    assign f_led1_r = color_r;
    assign f_led1_g = color_g;
    assign f_led1_b = color_b;
    assign f_led2_r = color_r;
    assign f_led2_g = color_g;
    assign f_led2_b = color_b;
    assign f_led3_r = color_r;
    assign f_led3_g = color_g;
    assign f_led3_b = color_b;
    assign f_led4_r = color_r;
    assign f_led4_g = color_g;
    assign f_led4_b = color_b;

    // 기어 표시용 단일 7세그
    wire [7:0] gear_seg;
    seg7_decoder u_gear_seg (
        .value({1'b0, gear_level}),
        .seg(gear_seg)
    );
    assign seg_single = gear_seg;

    // 속도 표시용 8자리 7세그 (오른쪽 정렬)
    reg [31:0] speed_value;
    always @(*) begin
        speed_value = 32'hffff_ffff;
        speed_value[3:0]  = speed_kmh % 10;
        speed_value[7:4]  = (speed_kmh / 10) % 10;
        speed_value[11:8] = (speed_kmh / 100) % 10;
    end

    seven_seg_display u_speed (
        .clk(clk_50mhz),
        .rst(rst),
        .tick_1khz(tick_1khz),
        .value(speed_value),
        .seg(ar_seg),
        .an(ar_sel)
    );

    // 서보 제어: rpm을 0~1000 범위로 정규화하여 duty 전달
    wire [9:0] servo_level = (rpm >= 8000) ? 10'd1000 : (rpm * 10'd1000) / 14'd8000;
    servo_pwm u_servo (
        .clk(clk_50mhz),
        .rst(rst),
        .duty_level(servo_level),
        .pwm_out(servo_ctrl)
    );

    piezo_beeper u_piezo (
        .clk(clk_50mhz),
        .rst(rst),
        .rpm(rpm),
        .piezo_out(piezo_out)
    );
endmodule
