// FILE: servo_rpm_ctrl.v
module servo_rpm_ctrl #(
    parameter integer PULSE_MIN     = 5,
    parameter integer PULSE_MAX     = 25,
    parameter integer STEP_SIZE     = 2,
    parameter integer SLOW_TICK_MAX = 1000
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] speed_level,
    input  wire [3:0] max_level,
    output reg        l_ctrl,
    output reg        r_ctrl
);

    localparam integer PULSE_RANGE = PULSE_MAX - PULSE_MIN;

    reg [4:0] current_pulse;
    reg [9:0] slow_cnt;
    reg [5:0] desired_pulse;

    always @(*) begin
        if (max_level == 4'd0) begin
            desired_pulse = PULSE_MIN[5:0];
        end else begin
            desired_pulse = PULSE_MIN[5:0] + (PULSE_RANGE * speed_level) / max_level;
            if (desired_pulse > PULSE_MAX[5:0]) begin
                desired_pulse = PULSE_MAX[5:0];
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_pulse <= PULSE_MIN[4:0];
            slow_cnt <= 10'd0;
        end else begin
            if (slow_cnt == SLOW_TICK_MAX - 1) begin
                slow_cnt <= 10'd0;
                if (desired_pulse > current_pulse) begin
                    if (desired_pulse - current_pulse <= STEP_SIZE[4:0]) begin
                        current_pulse <= desired_pulse[4:0];
                    end else begin
                        current_pulse <= current_pulse + STEP_SIZE[4:0];
                    end
                end else if (desired_pulse < current_pulse) begin
                    if (current_pulse - desired_pulse <= STEP_SIZE[4:0]) begin
                        current_pulse <= desired_pulse[4:0];
                    end else begin
                        current_pulse <= current_pulse - STEP_SIZE[4:0];
                    end
                end
            end else begin
                slow_cnt <= slow_cnt + 10'd1;
            end
        end
    end

    always @(*) begin
        if (desired_pulse > current_pulse) begin
            l_ctrl = 1'b0;
            r_ctrl = 1'b1;
        end else if (desired_pulse < current_pulse) begin
            l_ctrl = 1'b1;
            r_ctrl = 1'b0;
        end else begin
            l_ctrl = 1'b0;
            r_ctrl = 1'b0;
        end
    end
endmodule
