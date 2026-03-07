#!/usr/bin/env bash

set -e

if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run as root (sudo)"
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# SILENT MODE DETECTION
# ─────────────────────────────────────────────────────────────
_SPINNER_PID=""
_STEP_CURRENT=0
_STEP_TOTAL=4

if [[ "${KANASA_SILENT:-}" == "1" ]] && [[ -t 1 ]]; then
  _SILENT_MODE="interactive"
elif [[ "${KANASA_SILENT:-}" == "1" ]]; then
  _SILENT_MODE="pipe"
else
  _SILENT_MODE="off"
fi

# ─────────────────────────────────────────────────────────────
# HELPER: _silent_echo — echo wrapper, suppressed in silent mode
# ─────────────────────────────────────────────────────────────
_silent_echo() {
  if [[ "$_SILENT_MODE" == "off" ]]; then
    echo "$@"
  fi
}

# ─────────────────────────────────────────────────────────────
# HELPER: _silent_error — generic error in silent, real in verbose
# ─────────────────────────────────────────────────────────────
_silent_error() {
  local generic_msg="$1"
  shift
  if [[ "$_SILENT_MODE" != "off" ]]; then
    echo ""
    echo "$generic_msg"
  else
    # In verbose mode, print all remaining arguments (real messages)
    for line in "$@"; do
      echo "$line"
    done
  fi
}

# ─────────────────────────────────────────────────────────────
# HELPER: _start_spinner — background spinner with cover message
# ─────────────────────────────────────────────────────────────
_start_spinner() {
  local msg="$1"
  if [[ "$_SILENT_MODE" != "interactive" ]]; then
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
# HELPER: _stop_spinner — kill spinner, show result indicator
# ─────────────────────────────────────────────────────────────
_stop_spinner() {
  local success="${1:-true}"
  if [[ -n "${_SPINNER_PID:-}" ]]; then
    kill "$_SPINNER_PID" 2>/dev/null
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
  fi
  if [[ "$_SILENT_MODE" == "interactive" ]]; then
    if [[ "$success" == "true" ]]; then
      printf "\r  ✔ Done                                                    \n"
    else
      printf "\r  ❌ Failed                                               \n"
    fi
  fi
}

# ─────────────────────────────────────────────────────────────
# HELPER: _silent_cleanup — trap handler for unexpected exits
# ─────────────────────────────────────────────────────────────
_silent_cleanup() {
  local exit_code=$?
  if [[ -n "${_SPINNER_PID:-}" ]]; then
    kill "$_SPINNER_PID" 2>/dev/null
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
  fi
  if [[ "$_SILENT_MODE" != "off" ]] && [[ $exit_code -ne 0 ]]; then
    echo ""
    echo "❌ Setup failed — an unexpected error occurred"
  fi
}

# ─────────────────────────────────────────────────────────────
# MAIN: run_step — mode-aware step runner
# ─────────────────────────────────────────────────────────────
run_step() {
  local name="$1"
  local script="$2"
  local cover_msg="${3:-}"

  (( _STEP_CURRENT++ )) || true

  if [[ ! -f "$script" ]]; then
    if [[ "$_SILENT_MODE" != "off" ]]; then
      _stop_spinner false
      echo "❌ Setup failed — please check your configuration"
      exit 1
    else
      echo "❌ Missing script: $script"
      exit 1
    fi
  fi

  case "$_SILENT_MODE" in
    off)
      # Verbose mode — original behavior
      echo ""
      echo "=============================="
      echo "▶ $name"
      echo "=============================="
      bash "$script"
      echo "✔ $name completed"
      ;;
    interactive)
      # Silent interactive — spinner + cover message
      _start_spinner "$cover_msg"
      set +e
      bash "$script" > /dev/null 2>&1
      local rc=$?
      set -e
      if [[ $rc -ne 0 ]]; then
        _stop_spinner false
        echo "❌ Setup failed — please check your configuration"
        exit $rc
      fi
      _stop_spinner true
      ;;
    pipe)
      # Silent piped — line-based progress
      printf "Step %d/%d: %s..." "$_STEP_CURRENT" "$_STEP_TOTAL" "$cover_msg"
      set +e
      bash "$script" > /dev/null 2>&1
      local rc=$?
      set -e
      if [[ $rc -ne 0 ]]; then
        echo "FAILED"
        echo "❌ Setup failed — please check your configuration"
        exit $rc
      fi
      echo "done"
      ;;
  esac
}
