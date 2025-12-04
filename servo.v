module servo (
    input wire clk,       
    input wire rst,
    input wire l_ctrl,    
    input wire r_ctrl,    
    output wire servo     
);


parameter integer FRAME_TICK = 200; 

parameter integer PULSE_0   = 5;  
parameter integer PULSE_90  = 15;
parameter integer PULSE_180 = 25; 

parameter integer STEP_SIZE = 2;   

parameter integer SLOW_TICK_MAX = 1000;


reg [7:0] cnt;             
reg [4:0] target_pulse;    
reg [9:0] slow_cnt;        

// --- target_pulse 변경 로직 (속도 제어) ---
always @(posedge clk or posedge rst) begin
    if (rst) begin
        slow_cnt <= 10'd0;
        target_pulse <= PULSE_0; 
    end
    else begin
        if (slow_cnt == SLOW_TICK_MAX - 1) begin
            slow_cnt <= 10'd0; 
            
            if (r_ctrl) begin
                if (target_pulse + STEP_SIZE <= PULSE_180) begin
                    target_pulse <= target_pulse + STEP_SIZE;
                end else begin
                    target_pulse <= PULSE_180; 
                end
            end
            else if (l_ctrl) begin
                
                if (target_pulse - STEP_SIZE >= PULSE_0) begin
                    target_pulse <= target_pulse - STEP_SIZE;
                end else begin
                    target_pulse <= PULSE_0; 
                end
            end
        end
        else begin
            slow_cnt <= slow_cnt + 10'd1;
        end
    end
end

// --- PWM 프레임 및 출력 로직 ---
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt <= 8'd0;
    end
    else begin
        // 20ms 주기 리셋
        if (cnt == FRAME_TICK - 1) begin 
            cnt <= 8'd0;
        end
        else begin
            cnt <= cnt + 8'd1;
        end
    end
end

// PWM 출력: 카운터가 목표 펄스 폭보다 작을 때 High
assign servo = (cnt < target_pulse);

endmodule