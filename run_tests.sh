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

SOURCES=(
    top.v clk_divider.v debounce.v autorepeat.v one_pulse.v gear_ctrl.v rpm_ctrl.v
    servo_rpm_ctrl.v servo.v fnd_controller.v speed_fnd_controller.v gear_display.v fnd_decoder.v
)

echo "[INFO] iverilog로 tb_top 시뮬레이션 컴파일 중..."
$IVL_CMD -g2012 -o "${TARGET}_top" "${SOURCES[@]}" tb_top.v
echo "[INFO] tb_top 시뮬레이션 실행..."
$VVP_CMD "${TARGET}_top"

echo "[INFO] iverilog로 tb_display 시뮬레이션 컴파일 중..."
$IVL_CMD -g2012 -o "${TARGET}_display" "${SOURCES[@]}" tb_display.v
echo "[INFO] tb_display 시뮬레이션 실행..."
$VVP_CMD "${TARGET}_display"

echo "[INFO] iverilog로 tb_autorepeat 시뮬레이션 컴파일 중..."
$IVL_CMD -g2012 -o "${TARGET}_autorepeat" "${SOURCES[@]}" tb_autorepeat.v
echo "[INFO] tb_autorepeat 시뮬레이션 실행..."
$VVP_CMD "${TARGET}_autorepeat"
