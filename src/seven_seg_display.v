// seven_seg_display.v
// 8자리 7세그먼트 멀티플렉싱 드라이버 (active-low)

module seven_seg_display (
    input  wire        clk,
    input  wire        rst,
    input  wire        tick_1khz,
    input  wire [31:0] value,
    output reg  [7:0]  seg,
    output reg  [7:0]  an
);
    reg [2:0] digit_idx;
    wire [3:0] digit_val;

    function [3:0] nibble;
        input [31:0] v;
        input [2:0]  idx;
        begin
            case (idx)
                3'd0: nibble = v[3:0];
                3'd1: nibble = v[7:4];
                3'd2: nibble = v[11:8];
                3'd3: nibble = v[15:12];
                3'd4: nibble = v[19:16];
                3'd5: nibble = v[23:20];
                3'd6: nibble = v[27:24];
                default: nibble = v[31:28];
            endcase
        end
    endfunction

    wire [7:0] decoded;
    seg7_decoder decoder(
        .value(digit_val),
        .seg(decoded)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            digit_idx <= 3'd0;
            seg       <= 8'hff;
            an        <= 8'hff;
        end else if (tick_1khz) begin
            digit_idx <= digit_idx + 1'b1;
            seg       <= decoded;
            an        <= ~(8'b1 << digit_idx);
        end
    end

    assign digit_val = nibble(value, digit_idx);
endmodule
