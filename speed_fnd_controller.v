// FILE: speed_fnd_controller.v
module speed_fnd_controller #(
    parameter integer CLK_FREQ   = 1_000,
    parameter integer REFRESH_HZ = 500
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] value,
    output reg  [7:0]  fnd_sel,
    output wire [7:0]  fnd_seg
);
    localparam integer DIGIT_COUNT = 8;
    localparam integer DIV_DENOM   = REFRESH_HZ * DIGIT_COUNT;
    localparam integer REFRESH_CNT = (DIV_DENOM == 0) ? 1 : ((CLK_FREQ + DIV_DENOM - 1) / DIV_DENOM);

    reg [$clog2(REFRESH_CNT):0] cnt;
    reg [2:0] digit_idx;
    reg [3:0] current_digit;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt       <= 0;
            digit_idx <= 3'd0;
        end else begin
            if (cnt == REFRESH_CNT - 1) begin
                cnt       <= 0;
                digit_idx <= digit_idx + 3'd1;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end

    always @(*) begin
        case (digit_idx)
            3'd0: current_digit = value[3:0];
            3'd1: current_digit = value[7:4];
            3'd2: current_digit = value[11:8];
            3'd3: current_digit = value[15:12];
            3'd4: current_digit = value[19:16];
            3'd5: current_digit = value[23:20];
            3'd6: current_digit = value[27:24];
            default: current_digit = value[31:28];
        endcase
    end

    always @(*) begin
        case (digit_idx)
            3'd0: fnd_sel = 8'b1111_1110;
            3'd1: fnd_sel = 8'b1111_1101;
            3'd2: fnd_sel = 8'b1111_1011;
            3'd3: fnd_sel = 8'b1111_0111;
            3'd4: fnd_sel = 8'b1110_1111;
            3'd5: fnd_sel = 8'b1101_1111;
            3'd6: fnd_sel = 8'b1011_1111;
            3'd7: fnd_sel = 8'b0111_1111;
            default: fnd_sel = 8'b1111_1111;
        endcase
    end

    fnd_decoder u_decoder (
        .bcd(current_digit),
        .seg(fnd_seg)
    );
endmodule
