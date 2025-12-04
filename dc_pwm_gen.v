// FILE: dc_pwm_gen.v
module dc_pwm_gen #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer PWM_FREQ  = 20_000,
    parameter integer MAX_LEVEL = 15
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] speed_level,
    output reg        pwm_out
);

    localparam integer PWM_PERIOD = CLK_FREQ / PWM_FREQ;
    reg [31:0] counter;
    reg [31:0] duty_count;

    always @(*) begin
        duty_count = (speed_level * PWM_PERIOD) / MAX_LEVEL;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 32'd0;
            pwm_out <= 1'b0;
        end else begin
            if (counter >= PWM_PERIOD - 1) begin
                counter <= 32'd0;
            end else begin
                counter <= counter + 32'd1;
            end
            pwm_out <= (counter < duty_count) ? 1'b1 : 1'b0;
        end
    end
endmodule
