// FILE: tb_engine_sound.v
`timescale 1us/1us
module tb_engine_sound;
    reg clk;
    reg rst;
    reg [3:0] speed_level;
    wire piezo;

    localparam integer CLK_FREQ_HZ  = 10_000;
    localparam integer BASE_TONE_HZ = 200;
    localparam integer STEP_TONE_HZ = 150;

    engine_sound #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BASE_TONE_HZ(BASE_TONE_HZ),
        .STEP_TONE_HZ(STEP_TONE_HZ)
    ) dut (
        .clk(clk),
        .rst(rst),
        .speed_level(speed_level),
        .piezo(piezo)
    );

    initial begin
        clk = 1'b0;
        forever #50 clk = ~clk; // 10kHz 클록 (100us 주기)
    end

    initial begin
        rst         = 1'b1;
        speed_level = 4'd0;
        #200;
        rst = 1'b0;

        check_level(4'd0);
        check_level(4'd3);
        check_level(4'd8);

        $display("[INFO] 엔진음 주파수 테스트 완료");
        $finish;
    end

    task wait_toggle;
        reg prev;
        begin
            prev = piezo;
            @(posedge clk);
            while (piezo == prev) begin
                @(posedge clk);
            end
        end
    endtask

    task check_level(input [3:0] level);
        integer expected;
        begin
            speed_level = level;
            wait_toggle();
            expected = calc_half_cycle(BASE_TONE_HZ + (level * STEP_TONE_HZ));
            validate_half_cycle(expected, level);
            validate_half_cycle(expected, level);
        end
    endtask

    task validate_half_cycle(input integer expected, input [3:0] level);
        integer cycles;
        reg prev;
        begin
            cycles = 0;
            prev   = piezo;
            @(posedge clk);
            while (piezo == prev) begin
                cycles = cycles + 1;
                @(posedge clk);
            end

            if ((cycles < expected - 1) || (cycles > expected + 1)) begin
                $display("[ERROR] speed_level=%0d: 반주기 %0d 사이클, 기대 %0d±1", level, cycles, expected);
                $fatal;
            end else begin
                $display("[INFO] speed_level=%0d: 반주기 %0d 사이클 (기대 %0d)", level, cycles, expected);
            end
        end
    endtask

    function integer calc_half_cycle(input integer freq);
        integer result;
        begin
            if (freq == 0) begin
                result = 1;
            end else begin
                result = CLK_FREQ_HZ / (freq << 1);
                if (result == 0) begin
                    result = 1;
                end
            end
            calc_half_cycle = result;
        end
    endfunction
endmodule
