#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# check-rejections.sh — negative controls: every false claim must be rejected.
#
# A gate that has never rejected anything has never been shown to be a gate. Each
# fixture under tests/reject/ states something false about the naming rule, and
# this harness requires three things of each:
#
#   1. agda exits non-zero;
#   2. the exit status is Agda's type-error status (42) — a fixture that fails
#      because a tool is missing, a file does not parse, or an import moved is
#      not evidence of anything and is reported as a harness failure;
#   3. the diagnostic contains the mismatch Agda reports ('!=') and the
#      'when checking' context line, so the rejection happened at the intended
#      claim.
#
# The fixture list below is a manifest: it must equal the set of files present.
# That way neither a fixture nor a check can be added or removed silently.
set -uo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

AGDA_FLAGS=(--no-libraries --safe --without-K --double-check --ignore-interfaces -W error)
AGDA_TYPE_ERROR_STATUS=42

fixtures=(
  DriftedCanonical
  MismatchedRepoName
  MissingJlSuffix
  RepoFormIsIdentity
  RetiredNameIsLegal
  WrongCharsetWitness
  WrongStartWitness
)

if ! command -v agda >/dev/null 2>&1; then
  printf 'FAIL: no agda on PATH; the rejection controls cannot be exercised. This gate does not skip.\n' >&2
  exit 1
fi

expected_files="$(printf 'tests/reject/%s.agda\n' "${fixtures[@]}" | sort)"
actual_files="$(find tests/reject -name '*.agda' | sort)"
if [ "$actual_files" != "$expected_files" ]; then
  printf 'FAIL: rejection manifest differs from the files present\n--- declared ---\n%s\n--- present ---\n%s\n' \
    "$expected_files" "$actual_files"
  exit 1
fi

fail=0
for fixture in "${fixtures[@]}"; do
  status=0
  diagnostic="$(agda "${AGDA_FLAGS[@]}" -i proofs/agda -i tests/reject "tests/reject/${fixture}.agda" 2>&1)" || status=$?
  if [ "$status" -eq 0 ]; then
    printf 'FAIL: %s unexpectedly type-checked. Its claim is false, so a green here means the proofs are not really being checked.\n' "$fixture"
    fail=1
    continue
  fi
  if [ "$status" -ne "$AGDA_TYPE_ERROR_STATUS" ]; then
    printf 'FAIL: %s failed with status %d, not Agda type-error status %d — rejected for some reason other than the intended type mismatch.\n' \
      "$fixture" "$status" "$AGDA_TYPE_ERROR_STATUS"
    printf '%s\n' "$diagnostic"
    fail=1
    continue
  fi
  if ! printf '%s' "$diagnostic" | grep -q '!=' || ! printf '%s' "$diagnostic" | grep -q 'when checking'; then
    printf 'FAIL: %s was rejected, but not with the expected type-mismatch diagnostic.\n' "$fixture"
    printf '%s\n' "$diagnostic"
    fail=1
    continue
  fi
  printf 'PASS: %s rejected for the expected type mismatch\n' "$fixture"
done

if [ "$fail" -ne 0 ]; then
  printf 'FAIL: rejection controls did not behave as declared\n'
  exit 1
fi
printf 'PASS: %d rejection control(s) each rejected for the intended reason\n' "${#fixtures[@]}"
