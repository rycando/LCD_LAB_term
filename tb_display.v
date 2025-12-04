// FILE: tb_display.v
`timescale 1ns/1ps
module tb_display;
    reg clk;
    reg rst;
    reg [31:0] speed_value;
    reg [2:0] gear_value;

    wire [7:0] speed_sel;
    wire [7:0] speed_seg;
    wire [7:0] gear_seg;

    speed_fnd_controller #(
        .CLK_FREQ(16),
        .REFRESH_HZ(2)
    ) u_speed (
        .clk(clk),
        .rst(rst),
        .value(speed_value),
        .fnd_sel(speed_sel),
        .fnd_seg(speed_seg)
    );

    gear_display u_gear (
        .gear(gear_value),
        .gear_seg(gear_seg)
    );

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    initial begin
        rst = 1'b1;
        speed_value = pack_speed(4'd3, 4'd7);
        gear_value = 3'd2;
        #35;
        rst = 1'b0;

        check_speed_display("초기 속도/최대치", 4'd3, 4'd7);
        check_gear_display("초기 기어", 3'd2);

        speed_value = pack_speed(4'd9, 4'd4);
        gear_value = 3'd5;
        check_speed_display("속도/최대치 변경", 4'd9, 4'd4);
        check_gear_display("기어 변경", 3'd5);

        $display("[INFO] tb_display 완료");
        $finish;
    end

    function [31:0] pack_speed(input [3:0] speed, input [3:0] max_level);
        begin
            pack_speed = {24'd0, max_level, speed};
        end
    endfunction

    function [7:0] expected_seg(input [3:0] bcd);
        begin
            case (bcd)
                4'd0: expected_seg = 8'b1100_0000;
                4'd1: expected_seg = 8'b1111_1001;
                4'd2: expected_seg = 8'b1010_0100;
                4'd3: expected_seg = 8'b1011_0000;
                4'd4: expected_seg = 8'b1001_1001;
                4'd5: expected_seg = 8'b1001_0010;
                4'd6: expected_seg = 8'b1000_0010;
                4'd7: expected_seg = 8'b1111_1000;
                4'd8: expected_seg = 8'b1000_0000;
                default: expected_seg = 8'b1001_0000; // 9
            endcase
        end
    endfunction

    task capture_speed_digits(output [7:0] digit_seg [0:7]);
        integer captured;
        reg [7:0] seen_mask;
        begin
            captured = 0;
            seen_mask = 8'b0;
            while (captured < 8) begin
                @(posedge clk);
                case (speed_sel)
                    8'b1111_1110: if (!seen_mask[0]) begin digit_seg[0] = speed_seg; seen_mask[0] = 1'b1; captured = captured + 1; end
                    8'b1111_1101: if (!seen_mask[1]) begin digit_seg[1] = speed_seg; seen_mask[1] = 1'b1; captured = captured + 1; end
                    8'b1111_1011: if (!seen_mask[2]) begin digit_seg[2] = speed_seg; seen_mask[2] = 1'b1; captured = captured + 1; end
                    8'b1111_0111: if (!seen_mask[3]) begin digit_seg[3] = speed_seg; seen_mask[3] = 1'b1; captured = captured + 1; end
                    8'b1110_1111: if (!seen_mask[4]) begin digit_seg[4] = speed_seg; seen_mask[4] = 1'b1; captured = captured + 1; end
                    8'b1101_1111: if (!seen_mask[5]) begin digit_seg[5] = speed_seg; seen_mask[5] = 1'b1; captured = captured + 1; end
                    8'b1011_1111: if (!seen_mask[6]) begin digit_seg[6] = speed_seg; seen_mask[6] = 1'b1; captured = captured + 1; end
                    8'b0111_1111: if (!seen_mask[7]) begin digit_seg[7] = speed_seg; seen_mask[7] = 1'b1; captured = captured + 1; end
                    default: ;
                endcase
            end
        end
    endtask

    task check_speed_display(input [256*8:1] tag, input [3:0] speed, input [3:0] max_lv);
        reg [7:0] digits [0:7];
        integer i;
        begin
            capture_speed_digits(digits);

            if (digits[0] !== expected_seg(speed)) begin
                $display("[ERROR] %0s: 0번 자리 %b 기대값 %b", tag, digits[0], expected_seg(speed));
                $fatal;
            end

            if (digits[1] !== expected_seg(max_lv)) begin
                $display("[ERROR] %0s: 1번 자리 %b 기대값 %b", tag, digits[1], expected_seg(max_lv));
                $fatal;
            end

            for (i = 2; i < 8; i = i + 1) begin
                if (digits[i] !== expected_seg(4'd0)) begin
                    $display("[ERROR] %0s: %0d번 자리 %b 기대값 %b", tag, i, digits[i], expected_seg(4'd0));
                    $fatal;
                end
            end

            $display("[INFO] %0s: speed=%0d max=%0d", tag, speed, max_lv);
        end
    endtask

    task check_gear_display(input [256*8:1] tag, input [2:0] gear);
        begin
            @(posedge clk);
            if (gear_seg !== expected_seg({1'b0, gear})) begin
                $display("[ERROR] %0s: 기어 세그 %b 기대값 %b", tag, gear_seg, expected_seg({1'b0, gear}));
                $fatal;
            end
            $display("[INFO] %0s: gear=%0d", tag, gear);
        end
    endtask
endmodule
