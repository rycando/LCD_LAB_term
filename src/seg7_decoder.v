// seg7_decoder.v
// 0~9 및 일부 문자를 7세그먼트 패턴으로 변환 (active-low)

module seg7_decoder (
    input  wire [3:0] value,
    output reg  [7:0] seg
);
    always @(*) begin
        case (value)
            4'd0: seg = 8'b1100_0000;
            4'd1: seg = 8'b1111_1001;
            4'd2: seg = 8'b1010_0100;
            4'd3: seg = 8'b1011_0000;
            4'd4: seg = 8'b1001_1001;
            4'd5: seg = 8'b1001_0010;
            4'd6: seg = 8'b1000_0010;
            4'd7: seg = 8'b1111_1000;
            4'd8: seg = 8'b1000_0000;
            4'd9: seg = 8'b1001_0000;
            default: seg = 8'b1111_1111;
        endcase
    end
endmodule
