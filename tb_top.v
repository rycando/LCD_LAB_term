// FILE: tb_top.v
`timescale 1ns/1ps
module tb_top;
    reg clk_100mhz;
    reg rst_btn;
    reg btn_accel;
    reg btn_decel;
    reg [2:0] gear_sw;

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

        // initial LED should be green (normal) at speed 0
        repeat (5) @(posedge dut.u_clk_div.clk_1khz);
        check_led_color(3'b010, 4'd0);

        // accelerate pulses
        press_accel(5);

        // allow servo gauge to reach the target for gear 1
        repeat (12000) @(posedge dut.u_clk_div.clk_10khz);
        check_servo_high(5'd25);
        check_led_color(3'b100, 4'd3);

        // change gear and decelerate
        #2000000;
        gear_sw = 3'd3;
        #2000000;
        press_decel(1);

        // servo should move back according to new gear ratio and deceleration
        repeat (12000) @(posedge dut.u_clk_div.clk_10khz);
        check_servo_high(5'd10);
        check_led_color(3'b010, 4'd2);

        // accelerate again within caution range (gear 3 max 7)
        press_accel(2);
        repeat (10) @(posedge dut.u_clk_div.clk_1khz);
        check_led_color(3'b110, 4'd4);

        // accelerate to maximum to check high RPM color
        press_accel(3);
        repeat (10) @(posedge dut.u_clk_div.clk_1khz);
        check_led_color(3'b100, 4'd7);

        #5000000;
        $finish;
    end

    task press_accel(input integer count);
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                #1000000; // wait 1ms for debounce domain
                btn_accel = 1'b1;
                #1000000;
                btn_accel = 1'b0;
            end
        end
    endtask

    task press_decel(input integer count);
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                btn_decel = 1'b1;
                #1000000;
                btn_decel = 1'b0;
                #1000000;
            end
        end
    endtask

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

    task check_led_color(input [2:0] expected_rgb, input [3:0] expected_speed);
        begin
            if (leds[7:5] !== expected_rgb) begin
                $display("[ERROR] LED RGB %b != expected %b", leds[7:5], expected_rgb);
                $fatal;
            end
            if (leds[4:1] !== expected_speed) begin
                $display("[ERROR] LED speed bits %b != expected %b", leds[4:1], expected_speed);
                $fatal;
            end
            $display("[INFO] LED color and speed matched: RGB=%b speed=%0d", leds[7:5], leds[4:1]);
        end
    endtask
endmodule
