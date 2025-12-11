module servo_driver #(
    parameter integer FRAME_TICKS     = 1_000_000, // 20ms @ 50MHz
    parameter integer MIN_PULSE_TICK  = 50_000,    // 1.0ms @ 50MHz
    parameter integer MAX_PULSE_TICK  = 100_000,   // 2.0ms @ 50MHz
    // 내부 점진적 이동을 위한 파라미터 추가
    parameter integer SLOW_TICK_MAX   = 5_000_000, // 0.1초 주기
    parameter integer STEP_SIZE_PULSE = 1000       // 0.1초마다 움직이는 펄스 폭 크기 (조절 필요)
) (
    input  wire        clk,
    input  wire        rst,       
    input  wire [9:0]  duty_level,  // 0~1000. 이제 목표 듀티 레벨 (Target Duty)
    output wire        pwm_out
);
    
    // --- 1. 레지스터/와이어 선언 ---
    reg [19:0] cnt; // PWM 카운터 (0~1,000,000-1)
    reg [22:0] slow_cnt; // 0.1초 타이머
    
    // 현재 서보 펄스 폭을 저장하는 레지스터 (점진적으로 목표를 추종함)
    reg [19:0] current_high_count; 
    
    // 목표 펄스 폭 (조합 논리로 duty_level 입력에 즉시 반응)
    wire [19:0] target_high_count; 

    // --- 2. 목표 펄스 폭 계산 (조합 논리) ---
    // duty_level (0~1000)을 펄스 폭 (50000~100000)으로 변환
    assign target_high_count = MIN_PULSE_TICK +
                             ((MAX_PULSE_TICK - MIN_PULSE_TICK) * duty_level) / 1000;

    // --- 3. PWM 카운터 (20ms 프레임) ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 20'd0;
        end else if (cnt == FRAME_TICKS - 1) begin
            cnt <= 20'd0;
        end else begin
            cnt <= cnt + 20'd1;
        end
    end

    // --- 4. 점진적 이동 제어 (0.1초 주기) ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            slow_cnt <= 0;
            current_high_count <= MIN_PULSE_TICK; // 초기 위치 설정
        end else begin
            
            // 0.1초 타이머 업데이트
            if (slow_cnt == SLOW_TICK_MAX - 1) begin
                slow_cnt <= 0;
                
                // 목표(target_high_count)와 현재 펄스 폭(current_high_count) 비교
                if (current_high_count < target_high_count) begin
                    // 목표보다 작으면 증가 (오른쪽 이동)
                    if (current_high_count + STEP_SIZE_PULSE > target_high_count)
                        current_high_count <= target_high_count; // 목표 초과 방지
                    else
                        current_high_count <= current_high_count + STEP_SIZE_PULSE;
                        
                end else if (current_high_count > target_high_count) begin
                    // 목표보다 크면 감소 (왼쪽 이동)
                    if (current_high_count - STEP_SIZE_PULSE < target_high_count)
                        current_high_count <= target_high_count; // 목표 초과 방지
                    else
                        current_high_count <= current_high_count - STEP_SIZE_PULSE;
                end
                
                // 목표와 같으면 유지
                
            end else begin
                slow_cnt <= slow_cnt + 1;
            end
        end
    end
    
    // --- 5. PWM 출력 ---
    // 현재 펄스 폭 레지스터를 사용하여 PWM 신호 생성
    assign pwm_out = (cnt < current_high_count);

endmodule