// FILE: tb_top.v
`timescale 1ns/1ps
module tb_top;
    reg clk_100mhz;
    reg rst_btn;
    reg btn_accel;
    reg btn_decel;
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

        // allow servo gauge to reach the target for gear 1
        repeat (12000) @(posedge dut.u_clk_div.clk_10khz);
        check_servo_high(5'd25);

        // change gear and decelerate
        #2000000;
        gear_sw = 3'd3;
        #2000000;
        repeat (1) begin
            btn_decel = 1'b1;
            #1000000;
            btn_decel = 1'b0;
            #1000000;
        end

        // servo should move back according to new gear ratio and deceleration
        repeat (12000) @(posedge dut.u_clk_div.clk_10khz);
        check_servo_high(5'd10);

        #5000000;
        $finish;
    end

    task check_servo_high(input [4:0] expected);
        integer i;
        integer high_count;
        begin
            high_count = 0;
            for (i = 0; i < 200; i = i + 1) begin
                @(posedge dut.u_clk_div.clk_10khz);
                if (servo_pwm) begin
                    high_count = high_count + 1;
                end
            end

            if (high_count !== expected) begin
                $display("[ERROR] Servo PWM high count %0d != expected %0d", high_count, expected);
                $fatal;
            end else begin
                $display("[INFO] Servo PWM high count matched: %0d", high_count);
            end
        end
    endtask
endmodule
