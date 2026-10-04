#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# check-agda-trusted-base.sh — the axiom budget, and it is zero.
#
# A proof that leans on an escape hatch proves less than it appears to, and the
# appearance is the whole value. This scanner enforces a budget of zero for every
# way Agda offers to stop checking: axioms, holes, disabled termination or
# positivity checks, universe collapses, rewriting, erased equality, foreign or
# compiled code, and the options that would permit any of them.
#
# Semantics, chosen after reading the defect cicd-suite recorded against its own
# code-hygiene-check (README, "Known defects" 1): a scan for a WORD that also
# matched ordinary prose is worse than no scan, because it teaches people to
# ignore the result. So:
#
#   * code lines only — a line whose first non-space characters are `--` is a
#     comment and is dropped before matching. Documentation that explains what a
#     postulate is does not fail the gate;
#   * case-sensitive whole-word matches, so `postulated` or a lemma called
#     `no-postulates-here`... would match. It does not exist here, and if it ever
#     does, the honest fix is to rename the lemma rather than widen the scanner;
#   * the scan covers the proof tree AND the rejection fixtures, and never the
#     scanner's own fixtures (tests/trusted-base-fixtures), which contain real
#     violations on purpose.
#
# It also enforces a positive requirement: every module must declare
# --safe --without-K in its own OPTIONS pragma, so the discipline does not depend
# on remembering the command line.
#
# Usage: scripts/check-agda-trusted-base.sh [PATH ...]
#        default PATHs: proofs/agda tests/reject
set -uo pipefail

export LC_ALL=C

budget=0
paths=("$@")
if [ "${#paths[@]}" -eq 0 ]; then
  paths=(proofs/agda tests/reject)
fi

# Escape hatches: things that would let a file claim more than Agda checked.
hatches=(
  'postulate'
  '{!'
  '!}'
  'TERMINATING'
  'NO_POSITIVITY_CHECK'
  'NO_TERMINATION_CHECK'
  'NO_UNIVERSE_CHECK'
  '--type-in-type'
  '--no-termination-check'
  '--no-positivity-check'
  '--no-universe-check'
  '--rewriting'
  '--allow-unsolved-metas'
  '--allow-exec'
  '--omega-in-omega'
  '--with-K'
  'primEraseEquality'
  'trustMe'
  '{-# BUILTIN'
  '{-# FOREIGN'
  '{-# COMPILE'
)

files=()
for p in "${paths[@]}"; do
  if [ -d "$p" ]; then
    while IFS= read -r f; do files+=("$f"); done < <(find "$p" -name '*.agda' | sort)
  elif [ -f "$p" ]; then
    files+=("$p")
  else
    printf 'FAIL: trusted-base: %s is neither a file nor a directory\n' "$p" >&2
    exit 2
  fi
done

if [ "${#files[@]}" -eq 0 ]; then
  printf 'FAIL: trusted-base: no .agda files found under %s — nothing was scanned, and an unscanned tree is not a clean tree\n' "${paths[*]}"
  exit 1
fi

violations=0
for f in "${files[@]}"; do
  # Drop comment lines, then look for hatches in what is left.
  code="$(grep -vE '^[[:space:]]*--' "$f" || true)"

  # A bare `?` is a hole. Requiring a non-identifier character on both sides
  # keeps this from matching a name that legitimately ends in `?`.
  if printf '%s\n' "$code" | grep -nE '(^|[^A-Za-z0-9_])\?([^A-Za-z0-9_]|$)' >/dev/null; then
    printf 'FAIL: trusted-base: %s contains a hole (a bare ?)\n' "$f"
    printf '%s\n' "$code" | grep -nE '(^|[^A-Za-z0-9_])\?([^A-Za-z0-9_]|$)' | sed 's/^/    /' | head -5
    violations=$((violations + 1))
  fi

  for h in "${hatches[@]}"; do
    hits="$(printf '%s\n' "$code" | grep -nF -- "$h" || true)"
    if [ -n "$hits" ]; then
      printf 'FAIL: trusted-base: %s contains %s\n' "$f" "$h"
      printf '%s\n' "$hits" | sed 's/^/    /' | head -5
      violations=$((violations + 1))
    fi
  done

  options="$(grep -E '^\{-# OPTIONS' "$f" || true)"
  if [ -z "$options" ]; then
    printf 'FAIL: trusted-base: %s has no {-# OPTIONS ... #-} pragma; the discipline must be in the file, not only on the command line\n' "$f"
    violations=$((violations + 1))
  else
    for required in --safe --without-K; do
      if ! printf '%s\n' "$options" | grep -qF -- "$required"; then
        printf 'FAIL: trusted-base: %s does not declare %s in its OPTIONS pragma\n' "$f" "$required"
        violations=$((violations + 1))
      fi
    done
  fi
done

printf 'trusted-base: scanned %d module(s) under: %s\n' "${#files[@]}" "${paths[*]}"
if [ "$violations" -gt "$budget" ]; then
  printf 'FAIL: trusted-base: %d violation(s), budget is %d\n' "$violations" "$budget"
  exit 1
fi
printf 'PASS: trusted-base: %d violation(s) against a budget of %d — no axioms, no holes, no disabled checks\n' "$violations" "$budget"
