// FILE: engine_sound.v
// Description: 속도 단계에 비례한 파형으로 PIEZO를 구동하는 엔진음 발생기
module engine_sound #(
    parameter integer CLK_FREQ_HZ  = 10_000,
    parameter integer BASE_TONE_HZ = 200,
    parameter integer STEP_TONE_HZ = 150
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] speed_level,
    output reg        piezo
);
    reg [31:0] counter;
    reg [31:0] half_cycle_limit;
    wire [31:0] tone_freq;

    assign tone_freq = BASE_TONE_HZ + (speed_level * STEP_TONE_HZ);

    function [31:0] calc_half_cycle;
        input [31:0] freq;
        begin
            if (freq == 0) begin
                calc_half_cycle = 32'd1;
            end else begin
                calc_half_cycle = CLK_FREQ_HZ / (freq << 1);
                if (calc_half_cycle == 0) begin
                    calc_half_cycle = 32'd1;
                end
            end
        end
    endfunction

    always @(*) begin
        half_cycle_limit = calc_half_cycle(tone_freq);
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 32'd0;
            piezo   <= 1'b0;
        end else if (counter >= half_cycle_limit - 1) begin
            counter <= 32'd0;
            piezo   <= ~piezo;
        end else begin
            counter <= counter + 1'b1;
        end
    end
endmodule
