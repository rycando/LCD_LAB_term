// FILE: fnd_controller.v
module fnd_controller #(
    parameter integer CLK_FREQ    = 1_000,
    parameter integer REFRESH_HZ  = 500
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] value,
    output reg  [3:0]  fnd_sel,
    output wire [7:0]  fnd_seg
);

    localparam integer REFRESH_CNT = CLK_FREQ / (REFRESH_HZ * 4);
    reg [$clog2(REFRESH_CNT):0] cnt;
    reg [1:0] digit_idx;
    reg [3:0] current_digit;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt       <= 0;
            digit_idx <= 2'd0;
        end else begin
            if (cnt == REFRESH_CNT - 1) begin
                cnt       <= 0;
                digit_idx <= digit_idx + 2'd1;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end

    always @(*) begin
        case (digit_idx)
            2'd0: current_digit = value[3:0];
            2'd1: current_digit = value[7:4];
            2'd2: current_digit = value[11:8];
            default: current_digit = value[15:12];
        endcase
    end

    always @(*) begin
        case (digit_idx)
            2'd0: fnd_sel = 4'b1110;
            2'd1: fnd_sel = 4'b1101;
            2'd2: fnd_sel = 4'b1011;
            2'd3: fnd_sel = 4'b0111;
            default: fnd_sel = 4'b1111;
        endcase
    end

    fnd_decoder u_decoder (
        .bcd(current_digit),
        .seg(fnd_seg)
    );
endmodule
