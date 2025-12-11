// gear_selector.v
// DIP 스위치로부터 단수를 계산하고 가장 높은 단수를 우선 적용

module gear_selector (
    input  wire rst,
    input  wire [5:0] gear_sw,
    output reg  [2:0] gear_level
);
    always @(*) begin
        if (rst) begin
            gear_level = 3'd0;
        end else if (gear_sw[5]) begin
            gear_level = 3'd6;
        end else if (gear_sw[4]) begin
            gear_level = 3'd5;
        end else if (gear_sw[3]) begin
            gear_level = 3'd4;
        end else if (gear_sw[2]) begin
            gear_level = 3'd3;
        end else if (gear_sw[1]) begin
            gear_level = 3'd2;
        end else if (gear_sw[0]) begin
            gear_level = 3'd1;
        end else begin
            gear_level = 3'd0;
        end
    end
endmodule
