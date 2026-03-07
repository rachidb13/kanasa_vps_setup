#!/usr/bin/env bash

set -eE  # Exit on error, inherit ERR trap

if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run as root (sudo)"
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# SILENT MODE UTILITIES
# ─────────────────────────────────────────────────────────────
_SPINNER_PID=""
_STEP_CURRENT=0
_STEP_TOTAL=4

# Detect if output is interactive terminal
if [[ -t 1 ]]; then
  _INTERACTIVE="true"
else
  _INTERACTIVE="false"
fi

# ─────────────────────────────────────────────────────────────
# HELPER: _silent_cleanup — trap handler for errors
# ─────────────────────────────────────────────────────────────
_silent_cleanup() {
  if [[ -n "${_SPINNER_PID:-}" ]]; then
    kill "$_SPINNER_PID" 2>/dev/null || true
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
    # Clear the spinner line
    if [[ "$_INTERACTIVE" == "true" ]]; then
      printf "\r%60s\r" " "
    fi
  fi
  echo ""
  echo "❌ Setup failed — an unexpected error occurred "
}

# Register trap only for errors and signals
trap '_silent_cleanup' ERR INT TERM

# ─────────────────────────────────────────────────────────────
# HELPER: _error — display error and exit
# ─────────────────────────────────────────────────────────────
_error() {
  echo ""
  for line in "$@"; do
    echo "$line"
  done
}

# ─────────────────────────────────────────────────────────────
# HELPER: _start_spinner — background spinner with message
# ─────────────────────────────────────────────────────────────
_start_spinner() {
  local msg="$1"
  if [[ "$_INTERACTIVE" != "true" ]]; then
    return 0
  fi
  (
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while true; do
      printf "\r  %s %s " "${frames[$((i % ${#frames[@]}))]}" "$msg"
      sleep 0.1
      ((i++))
    done
  ) &
  _SPINNER_PID=$!
}

# ─────────────────────────────────────────────────────────────
# HELPER: _stop_spinner — kill spinner, show result
# ─────────────────────────────────────────────────────────────
_stop_spinner() {
  local success="${1:-true}"
  if [[ -n "${_SPINNER_PID:-}" ]]; then
    kill "$_SPINNER_PID" 2>/dev/null || true
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
  fi
  if [[ "$_INTERACTIVE" == "true" ]]; then
    if [[ "$success" == "true" ]]; then
      printf "\r  ✔ Done                                                    \n"
    else
      printf "\r  ❌ Failed                                               \n"
    fi
  fi
}

# ─────────────────────────────────────────────────────────────
# HELPER: _clear_spinner — stop spinner without showing status
# ─────────────────────────────────────────────────────────────
_clear_spinner() {
  if [[ -n "${_SPINNER_PID:-}" ]]; then
    kill "$_SPINNER_PID" 2>/dev/null || true
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
    if [[ "$_INTERACTIVE" == "true" ]]; then
      printf "\r%60s\r" " "
    fi
  fi
}


# ─────────────────────────────────────────────────────────────
# MAIN: run_step — silent step runner with spinner
# ─────────────────────────────────────────────────────────────
run_step() {
  local name="$1"
  local script="$2"
  local cover_msg="${3:-}"

  (( _STEP_CURRENT++ )) || true

  if [[ ! -f "$script" ]]; then
    _stop_spinner false
    echo "❌ Setup failed — please check your configuration"
    exit 1
  fi

  if [[ "$_INTERACTIVE" == "true" ]]; then
    # Interactive — spinner + cover message
    local _log="/tmp/kanasa_step_${_STEP_CURRENT}.log"
    _start_spinner "$cover_msg"
    set +e
    bash "$script" > "$_log" 2>&1
    local rc=$?
    set -e
    if [[ $rc -ne 0 ]]; then
      _stop_spinner false
      echo "❌ Setup failed — please check your configuration"
      echo "📋 Log: $_log"
      exit $rc
    fi
    rm -f "$_log"
    _stop_spinner true
  else
    # Piped — line-based progress
    local _log="/tmp/kanasa_step_${_STEP_CURRENT}.log"
    printf "Step %d/%d: %s..." "$_STEP_CURRENT" "$_STEP_TOTAL" "$cover_msg"
    set +e
    bash "$script" > "$_log" 2>&1
    local rc=$?
    set -e
    if [[ $rc -ne 0 ]]; then
      echo "FAILED"
      echo "❌ Setup failed — please check your configuration"
      echo "📋 Log: $_log"
      exit $rc
    fi
    rm -f "$_log"
    echo "done"
  fi
}

