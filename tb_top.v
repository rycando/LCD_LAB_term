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
        clk_100mhz = 1'b0;
        forever #5 clk_100mhz = ~clk_100mhz;
    end

    initial begin
        rst_btn    = 1'b1;
        btn_accel  = 1'b0;
        btn_decel  = 1'b0;
        gear_sw    = 3'd1;

        #200;
        rst_btn = 1'b0;
        wait_khz_cycles(25);
        check_leds("초기 상태: 기어1, 속도0");

        press_accel(1);
        wait_khz_cycles(8);
        check_leds("가속 1회: 기어1, 주의 LED 및 2세그먼트 바");

        press_accel(1);
        wait_khz_cycles(8);
        check_leds("가속 2회: 기어1, 주의 LED 및 4세그먼트 바");

        press_accel(1);
        wait_khz_cycles(8);
        check_leds("가속 3회: 기어1, 위험 LED 및 풀바");

        gear_sw = 3'd6; // 높은 기어로 변경하여 여유 RPM 확인
        wait_khz_cycles(10);
        check_leds("기어6 변경: 동일 속도에서 정상 LED 회복 및 바그래프 축소");

        press_accel(5); // 속도 8까지 증가
        wait_khz_cycles(10);
        check_leds("가속 5회 누적: 기어6, 주의 LED로 전환 및 중간 바그래프");

        press_accel(7); // 최대 RPM 도달
        wait_khz_cycles(12);
        check_leds("최대 RPM 도달: 기어6, 위험 LED 및 풀바");

        press_decel(1);
        wait_khz_cycles(10);
        check_leds("감속 1회: 기어6, 주의 LED 및 4/5 바");

        #5_000_000;
        $display("[INFO] 테스트 완료");
        $finish;
    end

    task wait_khz_cycles(input integer count);
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                @(posedge dut.u_clk_div.clk_1khz);
            end
        end
    endtask

    task press_accel(input integer count);
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                btn_accel = 1'b1;
                wait_khz_cycles(20);
                btn_accel = 1'b0;
                wait_khz_cycles(5);
            end
        end
    endtask

    task press_decel(input integer count);
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                btn_decel = 1'b1;
                wait_khz_cycles(20);
                btn_decel = 1'b0;
                wait_khz_cycles(5);
            end
        end
    endtask

    function [2:0] calc_rpm_rgb(input [3:0] speed, input [3:0] max_level);
        begin
            if (speed >= max_level) begin
                calc_rpm_rgb = 3'b100;
            end else if (speed >= {1'b0, max_level[3:1]}) begin
                calc_rpm_rgb = 3'b110;
            end else begin
                calc_rpm_rgb = 3'b010;
            end
        end
    endfunction

    function [4:0] calc_rpm_bar(input [3:0] speed, input [3:0] max_level);
        reg [6:0] scaled_speed;
        reg [6:0] threshold_1;
        reg [6:0] threshold_2;
        reg [6:0] threshold_3;
        reg [6:0] threshold_4;
        begin
            if (max_level == 0) begin
                calc_rpm_bar = 5'b0;
            end else begin
                scaled_speed = speed * 3'd5;
                threshold_1 = {3'b000, max_level};
                threshold_2 = threshold_1 << 1;
                threshold_3 = threshold_1 + threshold_2;
                threshold_4 = threshold_2 << 1;

                calc_rpm_bar[0] = (speed > 0);
                calc_rpm_bar[1] = (scaled_speed >= threshold_1);
                calc_rpm_bar[2] = (scaled_speed >= threshold_2);
                calc_rpm_bar[3] = (scaled_speed >= threshold_3);
                calc_rpm_bar[4] = (scaled_speed >= threshold_4);
            end
        end
    endfunction

    task check_leds(input [256*8:1] tag);
        reg [2:0] expected_rgb;
        reg [4:0] expected_bar;
        reg [3:0] speed;
        reg [3:0] max_lv;
        begin
            speed       = dut.u_rpm_ctrl.speed_level;
            max_lv      = dut.u_rpm_ctrl.max_level;
            expected_rgb = calc_rpm_rgb(speed, max_lv);
            expected_bar = calc_rpm_bar(speed, max_lv);

            if (leds[7:5] !== expected_rgb) begin
                $display("[ERROR] %0s: RGB %b 기대값 %b (speed=%0d max=%0d)", tag, leds[7:5], expected_rgb, speed, max_lv);
                $fatal;
            end

            if (leds[4:0] !== expected_bar) begin
                $display("[ERROR] %0s: 바그래프 %b 기대값 %b (speed=%0d max=%0d)", tag, leds[4:0], expected_bar, speed, max_lv);
                $fatal;
            end

            $display("[INFO] %0s: RGB=%b 바그래프=%b speed=%0d/%0d", tag, leds[7:5], leds[4:0], speed, max_lv);
        end
    endtask
endmodule
