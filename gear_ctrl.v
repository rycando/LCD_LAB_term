// FILE: gear_ctrl.v
module gear_ctrl (
    input  wire [2:0] gear_in,
    output reg  [2:0] gear_out
);
    always @(*) begin
        if (gear_in >= 3'd1 && gear_in <= 3'd6) begin
            gear_out = gear_in;
        end else begin
            gear_out = 3'd1;
        end
    end
endmodule
