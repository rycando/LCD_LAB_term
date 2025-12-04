// FILE: gear_display.v
module gear_display (
    input  wire [2:0] gear,
    output wire [7:0] gear_seg
);
    wire [3:0] gear_bcd;
    assign gear_bcd = {1'b0, gear};

    fnd_decoder u_decoder (
        .bcd(gear_bcd),
        .seg(gear_seg)
    );
endmodule
