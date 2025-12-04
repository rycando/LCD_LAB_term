// FILE: autorepeat.v
module autorepeat #(
    parameter [15:0] INITIAL_HOLD_CYCLES = 16'd400,
    parameter [15:0] REPEAT_CYCLES       = 16'd150
) (
    input  wire clk,
    input  wire rst,
    input  wire level_in,
    output reg  pulse_out
);
    reg prev_level;
    reg repeating;
    reg [15:0] hold_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prev_level <= 1'b0;
            repeating  <= 1'b0;
            hold_count <= 16'd0;
            pulse_out  <= 1'b0;
        end else begin
            pulse_out <= 1'b0;

            if (level_in) begin
                if (!prev_level) begin
                    // 첫 눌림 시 즉시 펄스 발생
                    pulse_out  <= 1'b1;
                    hold_count <= 16'd0;
                    repeating  <= 1'b0;
                end else if (!repeating) begin
                    if (hold_count >= (INITIAL_HOLD_CYCLES - 1'b1)) begin
                        pulse_out  <= 1'b1;
                        hold_count <= 16'd0;
                        repeating  <= 1'b1;
                    end else begin
                        hold_count <= hold_count + 16'd1;
                    end
                end else begin
                    if (hold_count >= (REPEAT_CYCLES - 1'b1)) begin
                        pulse_out  <= 1'b1;
                        hold_count <= 16'd0;
                    end else begin
                        hold_count <= hold_count + 16'd1;
                    end
                end
            end else begin
                hold_count <= 16'd0;
                repeating  <= 1'b0;
            end

            prev_level <= level_in;
        end
    end
endmodule
