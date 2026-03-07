#!/usr/bin/env bash
set -eE
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (sudo)" >&2
  exit 1
fi
_SPINNER_PID=""
_STEP_CURRENT=0
_STEP_TOTAL=4
_silent_cleanup() {
  if [[ -n "${_SPINNER_PID:-}" ]]; then
    kill "$_SPINNER_PID" 2>/dev/null || true
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
    printf "\r%60s\r" " " >&2
  fi
}
trap '_silent_cleanup' INT TERM
_error() {
  echo ""
  for line in "$@"; do
    echo "$line"
  done
}
_start_spinner() {
  local msg="$1"
  if [[ -n "${_SPINNER_PID:-}" ]]; then
    kill "$_SPINNER_PID" 2>/dev/null || true
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
  fi
  (
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while true; do
      printf "\r  %s %s   " "${frames[$((i % ${#frames[@]}))]}" "$msg" >&2
      sleep 0.12
      ((i++)) || true
    done
  ) &
  _SPINNER_PID=$!
}
_stop_spinner() {
  if [[ -n "${_SPINNER_PID:-}" ]]; then
    kill "$_SPINNER_PID" 2>/dev/null || true
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
  fi
  printf "\r  ✔ Done                                                    \n" >&2
}
_clear_spinner() {
  if [[ -n "${_SPINNER_PID:-}" ]]; then
    kill "$_SPINNER_PID" 2>/dev/null || true
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
    printf "\r%60s\r" " " >&2
  fi
}
run_step() {
  local name="$1"
  local script="$2"
  local cover_msg="${3:-}"
  (( _STEP_CURRENT++ )) || true
  if [[ ! -f "$script" ]]; then
    _clear_spinner
    printf "Setup failed -- please check your configuration\n" >&2
    exit 1
  fi
  local _log="/tmp/kanasa_step_${_STEP_CURRENT}.log"
  _start_spinner "$cover_msg"
  local rc=0
  ( set +eE; bash "$script" > "$_log" 2>&1 ) || rc=$?
  if [[ $rc -ne 0 ]]; then
    _stop_spinner
    printf "Setup failed -- please check your configuration\n" >&2
    printf "Log: %s\n" "$_log" >&2
    exit $rc
  fi
  rm -f "$_log"
  _stop_spinner
}