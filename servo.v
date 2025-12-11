module servo (
    input wire clk,       
    input wire rst,
    input wire l_ctrl,    
    input wire r_ctrl,    
    output wire servo     
);

parameter integer FRAME_TICK = 1000000; 
parameter integer PULSE_0   = 35000;   
parameter integer PULSE_180 = 115000; 
parameter integer STEP_SIZE = 2000;   


parameter integer SLOW_TICK_MAX = 5000000;

// 레지스터 선언
reg [24:0] cnt;             // 프레임 카운터 (FRAME_TICK=1,000,000까지 카운트 가능)
reg [24:0] target_pulse;    // 목표 펄스 폭 레지스터 (PULSE_0 ~ PULSE_180 사이 값)
reg [22:0] slow_cnt;        // 속도 제어용 카운터

// --- target_pulse 변경 로직 (속도 제어) ---
always @(posedge clk or posedge rst) begin
    if (rst) begin
        slow_cnt <= 23'd0;
        target_pulse <= PULSE_0; 
    end
    else begin
        // 1. 느린 클럭 카운터 업데이트
        if (slow_cnt == SLOW_TICK_MAX - 1) begin
            slow_cnt <= 23'd0; // 카운터 리셋
            
            // 2. 0.1초마다 버튼 입력 확인 및 target_pulse 업데이트
            if (r_ctrl) begin
                // 오른쪽 버튼(r_ctrl) 펄스가 들어왔을 때 증가
                if (target_pulse + STEP_SIZE <= PULSE_180) begin
                    target_pulse <= target_pulse + STEP_SIZE;
                end else begin
                    target_pulse <= PULSE_180; // 범위 상한 제한
                end
            end
            else if (l_ctrl) begin
                // 왼쪽 버튼(l_ctrl) 펄스가 들어왔을 때 감소
                if (target_pulse - STEP_SIZE >= PULSE_0) begin
                    target_pulse <= target_pulse - STEP_SIZE;
                end else begin
                    target_pulse <= PULSE_0; // 범위 하한 제한
                end
            end
        end
        else begin
            slow_cnt <= slow_cnt + 23'd1;
        end
    end
end

// --- PWM 프레임 및 출력 로직 ---
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt <= 25'd0;
    end
    else begin
        if (cnt == FRAME_TICK - 1) begin // 20ms 주기 리셋
            cnt <= 25'd0;
        end
        else begin
            cnt <= cnt + 25'd1;
        end
    end
end

// PWM 출력: 카운터가 목표 펄스 폭보다 작을 때 High
assign servo = (cnt < target_pulse);

endmodule