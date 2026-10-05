#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# check-trusted-base-fixtures.sh — self-test for the trusted-base scanner.
#
# The scanner is the thing that says "no axioms". If it is wrong in either
# direction the claim is worthless: too loose and a hole sails through, too tight
# and it fails documents that merely discuss markers (the defect cicd-suite
# measured at 112 and 313 false positives in two repositories). So it is tested
# against both: one fixture that mentions every banned word in comments and must
# pass, and four that really violate the discipline and must be flagged.
#
# The fixture list is a manifest and must equal the files present, so neither a
# fixture nor a check can be added or removed silently.
set -uo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

# name:expected  (clean = scanner exits 0, flagged = scanner exits non-zero)
fixtures=(
  "MentionsInComments:clean"
  "MissingSafeOption:flagged"
  "RealHole:flagged"
  "RealPostulate:flagged"
  "UnsafePragma:flagged"
)

expected_files="$(printf 'tests/trusted-base-fixtures/%s.agda\n' "${fixtures[@]%%:*}" | sort)"
actual_files="$(find tests/trusted-base-fixtures -name '*.agda' | sort)"
if [ "$actual_files" != "$expected_files" ]; then
  printf 'FAIL: trusted-base fixture manifest differs from the files present\n--- declared ---\n%s\n--- present ---\n%s\n' \
    "$expected_files" "$actual_files"
  exit 1
fi

fail=0
for entry in "${fixtures[@]}"; do
  fixture="${entry%%:*}"
  expected="${entry##*:}"
  status=0
  output="$(bash scripts/check-agda-trusted-base.sh "tests/trusted-base-fixtures/${fixture}.agda" 2>&1)" || status=$?
  case "$expected" in
    clean)
      if [ "$status" -ne 0 ]; then
        printf 'FAIL: %s should pass the scanner (it only mentions the markers, in comments) but exited %d\n' "$fixture" "$status"
        printf '%s\n' "$output" | sed 's/^/    /'
        fail=1
      else
        printf 'PASS: %s passes — the scanner does not match prose\n' "$fixture"
      fi
      ;;
    flagged)
      if [ "$status" -eq 0 ]; then
        printf 'FAIL: %s should be flagged but the scanner accepted it\n' "$fixture"
        printf '%s\n' "$output" | sed 's/^/    /'
        fail=1
      else
        printf 'PASS: %s flagged — %s\n' "$fixture" "$(printf '%s\n' "$output" | grep -m1 '^FAIL:' || printf 'exit %d' "$status")"
      fi
      ;;
    *)
      printf 'FAIL: unknown expectation %s for %s\n' "$expected" "$fixture"
      fail=1
      ;;
  esac
done

if [ "$fail" -ne 0 ]; then
  printf 'FAIL: trusted-base scanner self-test\n'
  exit 1
fi
printf 'PASS: trusted-base scanner verified in both directions against %d fixture(s)\n' "${#fixtures[@]}"
