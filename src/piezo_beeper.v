// piezo_beeper.v
// 엔진 rpm에 따라 주파수가 변화하는 피에조 스퀘어파 발생기

module piezo_beeper #(
    parameter integer INPUT_FREQ = 50_000_000,
    parameter integer FREQ_MIN   = 200,
    parameter integer FREQ_MAX   = 2000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [13:0] rpm,
    output reg         piezo_out
);
    integer divider;
    integer counter;

    function integer clamp_freq;
        input [13:0] rpm_val;
        integer freq;
        begin
            freq = FREQ_MIN + (rpm_val * (FREQ_MAX - FREQ_MIN)) / 8000;
            if (freq < FREQ_MIN) freq = FREQ_MIN;
            if (freq > FREQ_MAX) freq = FREQ_MAX;
            clamp_freq = freq;
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            divider   <= INPUT_FREQ / (2 * FREQ_MIN);
            counter   <= 0;
            piezo_out <= 1'b0;
        end else begin
            divider <= INPUT_FREQ / (2 * clamp_freq(rpm));
            if (counter >= divider) begin
                counter   <= 0;
                piezo_out <= ~piezo_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
