#!/usr/bin/env bash
set -euo pipefail

IVL_CMD=iverilog
VVP_CMD=vvp

TARGET=sim_top

if ! command -v "$IVL_CMD" >/dev/null 2>&1; then
    echo "[ERROR] iverilog 명령을 찾을 수 없습니다. 패키지를 설치하거나 도구를 경로에 추가하세요." >&2
    exit 127
fi

if ! command -v "$VVP_CMD" >/dev/null 2>&1; then
    echo "[ERROR] vvp 명령을 찾을 수 없습니다. 패키지를 설치하거나 도구를 경로에 추가하세요." >&2
    exit 127
fi

echo "[INFO] iverilog로 tb_top 시뮬레이션 컴파일 중..."
$IVL_CMD -g2012 -o "$TARGET" \
    top.v clk_divider.v debounce.v one_pulse.v gear_ctrl.v rpm_ctrl.v servo_rpm_ctrl.v servo.v \
    fnd_controller.v fnd_decoder.v dc_pwm_gen.v tb_top.v

echo "[INFO] 시뮬레이션 실행..."
$VVP_CMD "$TARGET"
