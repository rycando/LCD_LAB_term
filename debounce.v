// FILE: debounce.v
module debounce #(
    parameter integer STABLE_COUNT = 16
) (
    input  wire clk,
    input  wire rst,
    input  wire noisy_in,
    output reg  clean_out
);

    reg [$clog2(STABLE_COUNT):0] cnt;
    reg sync_0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_0    <= 1'b0;
            clean_out <= 1'b0;
            cnt       <= 0;
        end else begin
            if (noisy_in == clean_out) begin
                cnt <= 0;
            end else begin
                if (cnt == STABLE_COUNT - 1) begin
                    clean_out <= noisy_in;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            sync_0 <= noisy_in;
        end
    end
endmodule
