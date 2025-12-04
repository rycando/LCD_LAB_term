// FILE: tb_top.v
`timescale 1ns/1ps
module tb_top;
    reg clk_100mhz;
    reg rst_btn;
    reg btn_accel;
    reg btn_decel;
    reg btn_servo_left;
    reg btn_servo_right;
    reg [2:0] gear_sw;

    wire dc_pwm;
    wire servo_pwm;
    wire [3:0] fnd_sel;
    wire [7:0] fnd_seg;
    wire [7:0] leds;

    top dut (
        .clk_100mhz(clk_100mhz),
        .rst_btn(rst_btn),
        .btn_accel(btn_accel),
        .btn_decel(btn_decel),
        .btn_servo_left(btn_servo_left),
        .btn_servo_right(btn_servo_right),
        .gear_sw(gear_sw),
        .dc_pwm(dc_pwm),
        .servo_pwm(servo_pwm),
        .fnd_sel(fnd_sel),
        .fnd_seg(fnd_seg),
        .leds(leds)
    );

    initial begin
        clk_100mhz = 0;
        forever #5 clk_100mhz = ~clk_100mhz;
    end

    initial begin
        rst_btn = 1'b1;
        btn_accel = 1'b0;
        btn_decel = 1'b0;
        btn_servo_left = 1'b0;
        btn_servo_right = 1'b0;
        gear_sw = 3'd1;
        #200;
        rst_btn = 1'b0;

        // accelerate pulses
        repeat (5) begin
            #1000000; // wait 1ms for debounce domain
            btn_accel = 1'b1;
            #1000000;
            btn_accel = 1'b0;
        end

        // change gear and decelerate
        #2000000;
        gear_sw = 3'd3;
        #2000000;
        repeat (3) begin
            btn_decel = 1'b1;
            #1000000;
            btn_decel = 1'b0;
            #1000000;
        end

        // servo control
        repeat (2) begin
            btn_servo_right = 1'b1;
            #1000000;
            btn_servo_right = 1'b0;
            #2000000;
        end

        repeat (2) begin
            btn_servo_left = 1'b1;
            #1000000;
            btn_servo_left = 1'b0;
            #2000000;
        end

        #5000000;
        $finish;
    end
endmodule
