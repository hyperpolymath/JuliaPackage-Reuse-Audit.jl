#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# check-proofs.sh — positive controls: every proof obligation must typecheck.
#
# Walks proofs/agda recursively, so a module added later is gated even if nobody
# remembers to list it in All.agda. Then checks generated/agda/LiveIdentity.agda,
# which does not exist in a fresh clone: it is produced from live repository state
# by scripts/gen-identity-agda.sh. Its absence is a FAILURE, not a skip — a gate
# that silently checks less than it claims is the fake-gate failure mode
# standards/docs/CICD-SIGNAL-DISCIPLINE.adoc describes.
#
# Flags: --no-libraries (the trusted base is Agda's builtins, nothing else),
# --safe (no postulates, no foreign code, no unsafe pragmas), --without-K,
# --double-check (re-verify the whole development after typechecking),
# --ignore-interfaces (no cached result can stand in for a check),
# -W error (a warning is a failure).
set -uo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

AGDA_FLAGS=(--no-libraries --safe --without-K --double-check --ignore-interfaces -W error)

if ! command -v agda >/dev/null 2>&1; then
  cat >&2 <<'MSG'
FAIL: no agda on PATH.

This gate does not skip when the prover is missing: an unchecked proof is not a
proof. Install Agda 2.6.4.3 (the version CI pins) and re-run, or run the
container CI uses:

    podman run --rm -v "$PWD":/w -w /w debian:13-slim sh -c \
      'apt-get update && apt-get install -y --no-install-recommends agda-bin && bash scripts/proof-gate.sh'
MSG
  exit 1
fi

printf 'agda: %s\n' "$(agda --version)"

fail=0
mapfile -t modules < <(find proofs/agda -name '*.agda' | sort)
if [ "${#modules[@]}" -eq 0 ]; then
  printf 'FAIL: no proof modules under proofs/agda — nothing to check\n'
  exit 1
fi

for module in "${modules[@]}"; do
  printf 'checking %s\n' "$module"
  status=0
  # Captured so that the diagnostic is printed immediately after the verdict
  # rather than before it: a reviewer (or an annotation) then sees which module
  # failed and why in one place.
  output="$(agda "${AGDA_FLAGS[@]}" -i proofs/agda "$module" 2>&1)" || status=$?
  if [ "$status" -ne 0 ]; then
    printf 'FAIL: %s did not typecheck (exit %d)\n%s\n' "$module" "$status" "$output"
    fail=1
  elif [ -n "$output" ]; then
    printf '%s\n' "$output"
  fi
done

live="generated/agda/LiveIdentity.agda"
if [ -f "$live" ]; then
  printf 'checking %s (generated from live repository state)\n' "$live"
  status=0
  output="$(agda "${AGDA_FLAGS[@]}" -i proofs/agda -i generated/agda "$live" 2>&1)" || status=$?
  if [ "$status" -ne 0 ]; then
    printf 'FAIL: %s did not typecheck (exit %d) — the live repository identity does not satisfy the reconciliation invariant\n%s\n' "$live" "$status" "$output"
    fail=1
  elif [ -n "$output" ]; then
    printf '%s\n' "$output"
  fi
else
  printf 'FAIL: %s is missing. Generate it with:\n  bash scripts/gen-identity-agda.sh --mode live --out %s\nRefusing to report the identity gate as passed without checking the live identity.\n' "$live" "$live"
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  printf 'FAIL: proof obligations not discharged (see above)\n'
  exit 1
fi
printf 'PASS: %d committed proof module(s) plus the generated live identity typecheck under the required proof discipline\n' "${#modules[@]}"
