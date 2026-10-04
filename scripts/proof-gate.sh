#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# proof-gate.sh — run the whole package identity gate, and report every section.
#
# This is the single entry point used by CI (.github/workflows/proof-gates.yml)
# and by a developer locally. It runs every section, accumulates the results, and
# exits non-zero if any section failed. It does not stop at the first failure: a
# gate that reports one defect and hides the other four is a gate nobody can plan
# against.
#
# Nothing here is allowed to skip. A missing Agda is a failure, not a pass with a
# note; a missing generated module is a failure; a section that examined nothing
# is a failure. That is the difference between a check and a decoration, and
# standards/docs/CICD-SIGNAL-DISCIPLINE.adoc is explicit that a check which
# cannot fail is worse than no check, because it reports green and is counted as
# coverage.
#
# Usage:
#   scripts/proof-gate.sh [--repo-name NAME] [--root DIR] [--section NAME]...
#   scripts/proof-gate.sh --list
set -uo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

repo_name=""
root="."
selected=()

SECTIONS=(
  toolchain
  identity
  live-identity
  committed-generator-drift
  proofs
  rejections
  trusted-base
  trusted-base-self-test
  identity-self-test
)

usage() { sed -n '4,25p' "$0" | sed 's/^# \{0,1\}//'; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-name) repo_name="${2:?--repo-name needs a name}"; shift 2 ;;
    --repo-name=*) repo_name="${1#--repo-name=}"; shift ;;
    --root) root="${2:?--root needs a directory}"; shift 2 ;;
    --root=*) root="${1#--root=}"; shift ;;
    --section) selected+=("${2:?--section needs a name}"); shift 2 ;;
    --section=*) selected+=("${1#--section=}"); shift ;;
    --list) printf '%s\n' "${SECTIONS[@]}"; exit 0 ;;
    -h | --help) usage; exit 0 ;;
    *) printf 'FAIL: proof-gate: unknown argument %s\n' "$1" >&2; exit 2 ;;
  esac
done

for s in "${selected[@]:-}"; do
  [ -n "$s" ] || continue
  found=0
  for known in "${SECTIONS[@]}"; do
    if [ "$s" = "$known" ]; then found=1; break; fi
  done
  if [ "$found" -eq 0 ]; then
    printf 'FAIL: proof-gate: unknown section %s (known: %s)\n' "$s" "${SECTIONS[*]}" >&2
    exit 2
  fi
done

wanted() {
  local s="$1"
  if [ "${#selected[@]}" -eq 0 ]; then return 0; fi
  local w
  for w in "${selected[@]}"; do
    if [ "$s" = "$w" ]; then return 0; fi
  done
  return 1
}

declare -A result=()
declare -A detail=()

run_section() { # name, description, command...
  local name="$1" desc="$2"
  shift 2
  if ! wanted "$name"; then return 0; fi
  printf '\n────────────────────────────────────────────────────────────\n'
  printf 'section: %s — %s\n' "$name" "$desc"
  printf '────────────────────────────────────────────────────────────\n'
  local status=0
  "$@" || status=$?
  if [ "$status" -eq 0 ]; then
    result["$name"]="PASS"
    detail["$name"]="$desc"
  else
    result["$name"]="FAIL"
    detail["$name"]="$desc (exit $status)"
    printf 'section %s FAILED with exit %d\n' "$name" "$status"
  fi
}

# 1. The toolchain. Fail-closed: without a prover there is no proof, and this
#    section says so rather than letting the proof sections report nothing.
toolchain_check() {
  if ! command -v agda >/dev/null 2>&1; then
    cat >&2 <<'MSG'
no agda on PATH.

This gate does not skip when the prover is missing: an unchecked proof is not a
proof. Install Agda 2.6.4.3 (the version CI pins), or run the container CI uses:

    podman run --rm -v "$PWD":/w -w /w debian:13-slim sh -c \
      'apt-get update && apt-get install -y --no-install-recommends agda-bin && bash scripts/proof-gate.sh'
MSG
    return 1
  fi
  printf 'agda: %s\n' "$(agda --version)"
  printf 'CI pins Agda 2.6.4.3; a different local version is reported, not enforced.\n'
}

identity_args=(bash tests/check-identity.sh --root "$root")
if [ -n "$repo_name" ]; then identity_args+=(--repo-name "$repo_name"); fi

live_args=(bash scripts/gen-identity-agda.sh --mode live --root "$root"
  --out "${root}/generated/agda/LiveIdentity.agda")
if [ -n "$repo_name" ]; then live_args+=(--repo-name "$repo_name"); fi

run_section toolchain \
  "a prover exists (a missing Agda fails the gate; it never skips)" \
  toolchain_check

run_section identity \
  "the tree agrees with itself and with the repository it lives in" \
  "${identity_args[@]}"

run_section live-identity \
  "transcribe live repository state into Agda obligations" \
  "${live_args[@]}"

run_section committed-generator-drift \
  "committed generated Agda modules match their generators" \
  bash scripts/gen-identity-agda.sh --mode check-committed --root "$root"

run_section proofs \
  "every proof obligation typechecks (positive controls)" \
  bash tests/check-proofs.sh

run_section rejections \
  "every false claim is rejected (negative controls)" \
  bash tests/check-rejections.sh

run_section trusted-base \
  "zero axioms, zero holes, zero disabled checks" \
  bash scripts/check-agda-trusted-base.sh

run_section trusted-base-self-test \
  "the axiom scanner is verified in both directions" \
  bash tests/check-trusted-base-fixtures.sh

run_section identity-self-test \
  "the identity checker is verified against broken trees" \
  bash tests/check-identity-fixtures.sh

# ── summary ─────────────────────────────────────────────────────────────────

printf '\n════════════════════════════════════════════════════════════\n'
printf 'gate summary\n'
printf '════════════════════════════════════════════════════════════\n'

summary_md="### Package identity gate

| Section | Result | What it checked |
| --- | --- | --- |
"

failures=0
ran=0
for s in "${SECTIONS[@]}"; do
  if [ -z "${result[$s]:-}" ]; then
    printf '  %-26s SKIPPED (not selected)\n' "$s"
    continue
  fi
  ran=$((ran + 1))
  printf '  %-26s %s\n' "$s" "${result[$s]}"
  summary_md+="| \`${s}\` | ${result[$s]} | ${detail[$s]} |
"
  if [ "${result[$s]}" = "FAIL" ]; then failures=$((failures + 1)); fi
done

if [ "$ran" -eq 0 ]; then
  printf 'FAIL: no sections ran\n'
  exit 1
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    printf '%s\n' "$summary_md"
    printf '\nAgda: `%s`. Trusted base: zero axioms, zero holes.\n' \
      "$(command -v agda >/dev/null 2>&1 && agda --version || printf 'not installed')"
  } >>"$GITHUB_STEP_SUMMARY"
fi

printf '\n%d section(s) ran, %d failed\n' "$ran" "$failures"
if [ "$failures" -gt 0 ]; then
  printf 'FAIL: package identity gate\n'
  exit 1
fi
printf 'PASS: package identity gate\n'
