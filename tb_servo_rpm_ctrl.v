// FILE: tb_servo_rpm_ctrl.v
`timescale 1us/1us
module tb_servo_rpm_ctrl;
    reg clk;
    reg rst;
    reg [3:0] speed_level;
    reg [3:0] max_level;
    wire l_ctrl;
    wire r_ctrl;
    wire servo_pwm;

    servo_rpm_ctrl u_servo_rpm_ctrl (
        .clk(clk),
        .rst(rst),
        .speed_level(speed_level),
        .max_level(max_level),
        .l_ctrl(l_ctrl),
        .r_ctrl(r_ctrl)
    );

    servo u_servo (
        .clk(clk),
        .rst(rst),
        .l_ctrl(l_ctrl),
        .r_ctrl(r_ctrl),
        .servo(servo_pwm)
    );

    initial begin
        clk = 1'b0;
        forever #50 clk = ~clk; // 10kHz clock period (100us)
    end

    initial begin
        rst = 1'b1;
        speed_level = 4'd0;
        max_level = 4'd5;
        repeat (5) @(posedge clk);
        rst = 1'b0;

        wait_and_check(5'd5, "정지 상태 기본 펄스");

        speed_level = 4'd3; // target becomes closer to 최대치
        wait_servo_steps(8);
        wait_and_check(5'd17, "가속 후 위치");

        max_level = 4'd9; // 기어 변경으로 목표 위치 축소
        wait_servo_steps(6);
        wait_and_check(5'd11, "기어 변경 후 위치");

        $display("[INFO] tb_servo_rpm_ctrl 완료");
        $finish;
    end

    task wait_servo_steps(input integer steps);
        integer i;
        begin
            for (i = 0; i < steps * 1000; i = i + 1) begin
                @(posedge clk);
            end
        end
    endtask

    task wait_and_check(input [4:0] expected_high, input [127:0] label);
        integer high_count;
        integer i;
        begin
            high_count = 0;
            // 20ms 프레임 동안 PWM High 카운트 측정
            for (i = 0; i < 200; i = i + 1) begin
                @(posedge clk);
                if (servo_pwm) begin
                    high_count = high_count + 1;
                end
            end

            if (high_count !== expected_high) begin
                $display("[ERROR] %s: 측정 %0d, 기대 %0d", label, high_count, expected_high);
                $fatal;
            end else begin
                $display("[INFO] %s: 측정 %0d", label, high_count);
            end
        end
    endtask
endmodule
