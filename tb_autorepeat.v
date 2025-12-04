// FILE: tb_autorepeat.v
`timescale 1ns/1ps
module tb_autorepeat;
    reg clk_100mhz;
    reg rst_btn;
    reg btn_accel;
    reg btn_decel;
    reg [2:0] gear_sw;

    wire servo_pwm;
    wire [3:0] fnd_sel;
    wire [7:0] fnd_seg;
    wire [7:0] leds;

    localparam integer INITIAL_HOLD_CYCLES = 300;
    localparam integer REPEAT_CYCLES       = 150;

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
        rst_btn   = 1'b1;
        btn_accel = 1'b0;
        btn_decel = 1'b0;
        gear_sw   = 3'd6;

        #200;
        rst_btn = 1'b0;
        wait_khz_cycles(20);

        apply_hold(1'b1, 50, "가속 짧은 입력: 단일 펄스 기대");
        apply_hold(1'b1, 700, "가속 길게 누르기: 반복 펄스 기대");
        apply_hold(1'b0, 500, "감속 길게 누르기: 반복 펄스 기대");
        apply_hold(1'b1, 320, "재가속: 초기 지연 통과 후 첫 반복 확인");

        #2_000_000;
        $display("[INFO] tb_autorepeat 시나리오 완료");
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

    function integer calc_pulses(input integer hold_cycles);
        integer remaining;
        begin
            if (hold_cycles <= 0) begin
                calc_pulses = 0;
            end else begin
                calc_pulses = 1;
                if (hold_cycles > INITIAL_HOLD_CYCLES) begin
                    remaining  = hold_cycles - INITIAL_HOLD_CYCLES;
                    calc_pulses = calc_pulses + ((remaining + REPEAT_CYCLES - 1) / REPEAT_CYCLES);
                end
            end
        end
    endfunction

    task apply_hold(
        input        is_accel,
        input integer hold_cycles,
        input [256*8:1] tag
    );
        reg [3:0] before_speed;
        reg [3:0] after_speed;
        reg [3:0] expected_speed;
        reg [3:0] max_lv;
        integer pulse_count;
        integer calc_speed;
        begin
            before_speed = dut.u_rpm_ctrl.speed_level;
            max_lv       = dut.u_rpm_ctrl.max_level;
            pulse_count  = calc_pulses(hold_cycles);

            if (is_accel) begin
                calc_speed = before_speed + pulse_count;
                if (calc_speed > max_lv)
                    calc_speed = max_lv;
            end else begin
                calc_speed = before_speed - pulse_count;
                if (calc_speed < 0)
                    calc_speed = 0;
            end
            expected_speed = calc_speed[3:0];

            if (is_accel)
                btn_accel = 1'b1;
            else
                btn_decel = 1'b1;

            wait_khz_cycles(hold_cycles);

            if (is_accel)
                btn_accel = 1'b0;
            else
                btn_decel = 1'b0;

            wait_khz_cycles(25);
            after_speed = dut.u_rpm_ctrl.speed_level;

            if (after_speed !== expected_speed) begin
                $display(
                    "[ERROR] %0s: speed=%0d 기대=%0d (max=%0d, pulses=%0d)",
                    tag, after_speed, expected_speed, max_lv, pulse_count
                );
                $fatal;
            end else begin
                $display(
                    "[INFO] %0s: speed=%0d -> %0d (pulses=%0d)",
                    tag, before_speed, after_speed, pulse_count
                );
            end
        end
    endtask
endmodule
