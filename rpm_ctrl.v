// FILE: rpm_ctrl.v
module rpm_ctrl #(
    parameter integer MAX_L1 = 3,
    parameter integer MAX_L2 = 5,
    parameter integer MAX_L3 = 7,
    parameter integer MAX_L4 = 9,
    parameter integer MAX_L5 = 12,
    parameter integer MAX_L6 = 15
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       accel_pulse,
    input  wire       decel_pulse,
    input  wire [2:0] gear,
    output reg  [3:0] speed_level
);

    reg [3:0] max_level;

    always @(*) begin
        case (gear)
            3'd1: max_level = MAX_L1[3:0];
            3'd2: max_level = MAX_L2[3:0];
            3'd3: max_level = MAX_L3[3:0];
            3'd4: max_level = MAX_L4[3:0];
            3'd5: max_level = MAX_L5[3:0];
            3'd6: max_level = MAX_L6[3:0];
            default: max_level = MAX_L1[3:0];
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            speed_level <= 4'd0;
        end else begin
            if (accel_pulse && speed_level < max_level) begin
                speed_level <= speed_level + 4'd1;
            end else if (decel_pulse && speed_level > 0) begin
                speed_level <= speed_level - 4'd1;
            end else begin
                speed_level <= speed_level;
            end
        end
    end
endmodule
