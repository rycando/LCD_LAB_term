// seven_seg_display.v
// Multiplex controller for 8-digit 7-segment (active-low), limited to digits 6~8.

module seven_seg_display (
    input  wire        clk,
    input  wire        rst,
    input  wire        tick_1khz,
    input  wire [31:0] value,
    output reg  [7:0]  seg,
    output reg  [7:0]  an
);
    reg [1:0] digit_idx;
    wire [2:0] active_digit;
    wire [3:0] digit_val;

    function [3:0] nibble;
        input [31:0] v;
        input [1:0]  idx;
        begin
            case (idx)
                2'd0: nibble = v[11:8]; // hundreds
                2'd1: nibble = v[7:4];  // tens
                default: nibble = v[3:0]; // ones
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
            digit_idx <= 2'd0;
            seg       <= 8'hff;
            an        <= 8'hff;
        end else if (tick_1khz) begin
            if (digit_idx == 2'd2)
                digit_idx <= 2'd0;
            else
                digit_idx <= digit_idx + 1'b1;
            seg <= decoded;
            an  <= ~(8'b1 << active_digit);
        end
    end

    assign active_digit = 3'd5 + digit_idx; // use digits 6, 7, 8
    assign digit_val    = nibble(value, digit_idx);
endmodule
