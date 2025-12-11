// engine_model.v
// Compute speed/rpm state from throttle, brake, and gear selection.

module engine_model #(
    parameter integer SPEED_MAX      = 400,
    parameter integer IDLE_RPM       = 800,
    parameter integer WARNING_RPM    = 5500,
    parameter integer OVERLOAD_RPM   = 7000,
    parameter integer RPM_LIMIT      = 8000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        tick_10hz,
    input  wire        throttle,
    input  wire        brake,
    input  wire [2:0]  gear,
    output reg  [8:0]  speed_kmh,
    output reg  [13:0] rpm,
    output wire        overload
);
    reg [8:0] next_speed;
    localparam integer FINAL_DRIVE = 41;    // 4.1 represented with 0.1 fixed-point
    localparam integer WHEEL_PER   = 6000;  // 60.00 (0.01 fixed-point) to widen rpm swing up to 8000 rpm

    // Gear ratios: 0.01 fixed-point
    localparam integer GEAR1 = 360;
    localparam integer GEAR2 = 219;
    localparam integer GEAR3 = 141;
    localparam integer GEAR4 = 100;
    localparam integer GEAR5 = 83;
    localparam integer GEAR6 = 72;

    function [13:0] calc_rpm;
        input [8:0] speed;
        input [2:0] g;
        reg [63:0] wheel_rpm_fp; // 0.01 fixed-point
        integer    gear_fp;
        reg [63:0] result_fp;
        begin
            if (g == 0) begin
                calc_rpm = IDLE_RPM;
            end else begin
                wheel_rpm_fp = speed * WHEEL_PER;
                case (g)
                    3'd1: gear_fp = GEAR1;
                    3'd2: gear_fp = GEAR2;
                    3'd3: gear_fp = GEAR3;
                    3'd4: gear_fp = GEAR4;
                    3'd5: gear_fp = GEAR5;
                    default: gear_fp = GEAR6;
                endcase
                // rpm = wheel_rpm * final_drive * gear_ratio
                result_fp = wheel_rpm_fp * FINAL_DRIVE * gear_fp;
                calc_rpm  = result_fp / 1_000_000;
                if (calc_rpm < IDLE_RPM) begin
                    calc_rpm = IDLE_RPM;
                end else if (calc_rpm > RPM_LIMIT) begin
                    calc_rpm = RPM_LIMIT;
                end
            end
        end
    endfunction

    function [3:0] accel_step;
        input [2:0] g;
        begin
            case (g)
                3'd1: accel_step = 4'd2;
                3'd2: accel_step = 4'd3;
                3'd3: accel_step = 4'd4;
                3'd4: accel_step = 4'd5;
                3'd5: accel_step = 4'd6;
                3'd6: accel_step = 4'd6;
                default: accel_step = 4'd0;
            endcase
        end
    endfunction

    function [3:0] brake_step;
        input [2:0] g;
        begin
            case (g)
                3'd1: brake_step = 4'd4;
                3'd2: brake_step = 4'd5;
                3'd3: brake_step = 4'd6;
                3'd4: brake_step = 4'd7;
                3'd5: brake_step = 4'd7;
                default: brake_step = 4'd8;
            endcase
        end
    endfunction

    function [8:0] gear_speed_max;
        input [2:0] g;
        begin
            case (g)
                3'd1: gear_speed_max = 9'd30;
                3'd2: gear_speed_max = 9'd70;
                3'd3: gear_speed_max = 9'd130;
                3'd4: gear_speed_max = 9'd200;
                3'd5: gear_speed_max = 9'd300;
                3'd6: gear_speed_max = 9'd400;
                default: gear_speed_max = SPEED_MAX[8:0];
            endcase
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            speed_kmh <= 9'd0;
            rpm       <= IDLE_RPM;
        end else if (tick_10hz) begin
            next_speed = speed_kmh;
            if (brake) begin
                if (speed_kmh <= brake_step(gear))
                    next_speed = 9'd0;
                else
                    next_speed = speed_kmh - brake_step(gear);
            end else if (throttle) begin
                if (speed_kmh < gear_speed_max(gear)) begin
                    if (speed_kmh + accel_step(gear) >= gear_speed_max(gear))
                        next_speed = gear_speed_max(gear);
                    else
                        next_speed = speed_kmh + accel_step(gear);
                end else if (speed_kmh + accel_step(gear) >= SPEED_MAX) begin
                    next_speed = SPEED_MAX[8:0];
                end else begin
                    next_speed = speed_kmh + accel_step(gear);
                end
            end else begin
                if (speed_kmh > 0)
                    next_speed = speed_kmh - 1'b1;
            end

            speed_kmh <= next_speed;
            rpm       <= calc_rpm(next_speed, gear);
        end
    end

    assign overload = (rpm >= OVERLOAD_RPM);
endmodule
