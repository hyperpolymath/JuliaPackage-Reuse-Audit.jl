#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# gen-identity-agda.sh — turn repository state into Agda obligations.
#
# This script is a TRANSCRIBER, not a decider. It reads names out of the
# repository and emits them as Agda character lists together with the
# obligations those names have to satisfy. Whether the obligations hold is
# decided by Agda's own evaluator when the module is typechecked with --safe
# --without-K --double-check -W error: an obligation discharged by `refl`
# typechecks only if both sides reduce to the same list of characters. A
# mismatch between the repository name and the package name is therefore a type
# error, not a script verdict, and no amount of scripting here can make it pass.
#
# Modes:
#   canonical      the DECIDED identity. Read from Project.toml only — never from
#                  the network, never from mutable CI state. The repository name
#                  is not read at all: it is built from the package name by the
#                  rule proved in PackageNaming. Committed and reviewed.
#   live           the OBSERVED identity. Package name from Project.toml,
#                  repository name from --repo-name, or $GITHUB_REPOSITORY, or
#                  the origin remote. Emitted into generated/agda/ and never
#                  committed (MUST.contractile: generated code lives in
#                  generated/ only).
#   retired        the RETIRED identities from docs/naming/retired-names.txt,
#                  each with a proof that it could never have been a Julia
#                  package name. Committed and reviewed.
#   check-committed
#                  regenerate every committed output and fail if any differs
#                  from what is in the tree, so the data cannot be edited by
#                  hand behind the generator's back.
#
# Fail-closed: an unreadable Project.toml, an empty name, a character that cannot
# be emitted as an Agda character literal, a package name that is not a legal
# Julia identifier, a retired name with no refutable character, or an
# unresolvable repository name all exit non-zero. Nothing defaults to something
# plausible.
#
# Usage:
#   scripts/gen-identity-agda.sh --mode canonical [--root DIR] [--out PATH]
#   scripts/gen-identity-agda.sh --mode live --repo-name NAME [--root DIR] [--out PATH]
#   scripts/gen-identity-agda.sh --mode retired [--root DIR] [--out PATH]
#   scripts/gen-identity-agda.sh --mode check-committed [--root DIR]
set -euo pipefail

# C locale: the character classes below must mean ASCII and must mean the same
# thing on a laptop and on a runner.
export LC_ALL=C

root="."
mode=""
out=""
repo_name_arg=""

usage() { sed -n '4,38p' "$0" | sed 's/^# \{0,1\}//'; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode) mode="${2:?--mode needs canonical|live|retired|check-committed}"; shift 2 ;;
    --mode=*) mode="${1#--mode=}"; shift ;;
    --root) root="${2:?--root needs a directory}"; shift 2 ;;
    --root=*) root="${1#--root=}"; shift ;;
    --out) out="${2:?--out needs a path}"; shift 2 ;;
    --out=*) out="${1#--out=}"; shift ;;
    --repo-name) repo_name_arg="${2:?--repo-name needs a name}"; shift 2 ;;
    --repo-name=*) repo_name_arg="${1#--repo-name=}"; shift ;;
    -h | --help) usage; exit 0 ;;
    *) printf 'FAIL: gen-identity-agda: unknown argument %s\n' "$1" >&2; exit 2 ;;
  esac
done

fail() { printf 'FAIL: gen-identity-agda: %s\n' "$*" >&2; exit 1; }

case "$mode" in
  canonical | live | retired | check-committed) ;;
  "") fail "--mode is required (canonical|live|retired|check-committed)" ;;
  *) fail "--mode '%s' is not one of canonical|live|retired|check-committed" "$mode" ;;
esac

[ -d "$root" ] || fail "root '%s' is not a directory" "$root"

# ── emitters ────────────────────────────────────────────────────────────────

# A name as a list of character literals. Agda reduces this list; the comment
# printed above it is only for the reader.
agda_chars() {
  local s="$1" i c out=""
  [ -n "$s" ] || fail "refusing to emit an empty name as an Agda character list"
  for ((i = 0; i < ${#s}; i++)); do
    c="${s:i:1}"
    case "$c" in
      [A-Za-z0-9_.!-]) ;;
      *) fail "character '%s' at position %d of '%s' cannot be emitted as an Agda character literal" "$c" "$i" "$s" ;;
    esac
    out="${out}'${c}' ∷ "
  done
  printf '%s[]' "$out"
}

# A possibly empty name as a character list ("[]" when empty).
agda_chars_or_nil() {
  local s="$1"
  if [ -z "$s" ]; then printf '[]'; else agda_chars "$s"; fi
}

identchar_ctor() {
  case "$1" in
    [A-Z]) printf 'c%s' "$1" ;;
    [a-z]) printf 'c%s' "$1" ;;
    [0-9]) printf 'cDigit%s' "$1" ;;
    _) printf 'cUnderscore' ;;
    '!') printf 'cBang' ;;
    *) return 1 ;;
  esac
}

identstart_ctor() {
  case "$1" in
    [A-Za-z]) printf 's%s' "$1" ;;
    _) printf 'sUnderscore' ;;
    *) return 1 ;;
  esac
}

# Witness that every character of a (possibly empty) name is legal.
all_ident_chars_witness() {
  local s="$1" i c ctor out="aic-nil"
  for ((i = ${#s} - 1; i >= 0; i--)); do
    c="${s:i:1}"
    ctor="$(identchar_ctor "$c")" ||
      fail "'%s' is not a legal Julia identifier character (position %d of '%s')" "$c" "$i" "$s"
    out="aic-cons ${ctor} (${out})"
  done
  printf '%s' "$out"
}

# Witness that a given character occurs in a name, pointing at its first
# occurrence. Used to refute a retired name.
any_char_witness() {
  local s="$1" target="$2" i found=-1 out="any-here refl"
  for ((i = 0; i < ${#s}; i++)); do
    if [ "${s:i:1}" = "$target" ]; then found="$i"; break; fi
  done
  [ "$found" -ge 0 ] || return 1
  for ((i = 0; i < found; i++)); do out="any-there (${out})"; done
  printf '%s' "$out"
}

# ── readers ─────────────────────────────────────────────────────────────────

package_name_from_project_toml() {
  local toml="$1" name
  [ -f "$toml" ] || fail "%s does not exist" "$toml"
  name="$(awk '
    /^[[:space:]]*\[/ { exit }
    /^[[:space:]]*name[[:space:]]*=/ {
      if (match($0, /"[^"]*"/)) { print substr($0, RSTART + 1, RLENGTH - 2); exit }
    }
  ' "$toml")"
  [ -n "$name" ] || fail "no top-level name = \"...\" found in %s" "$toml"
  printf '%s' "$name"
}

require_legal_identifier() {
  local name="$1" what="$2"
  case "$name" in
    [A-Za-z_]*) ;;
    *) fail "%s '%s' does not start with a letter or underscore, so it is not a legal Julia identifier" "$what" "$name" ;;
  esac
  printf '%s' "$name" | grep -qE '^[A-Za-z_][A-Za-z0-9_!]*$' ||
    fail "%s '%s' contains a character that is not legal in a Julia identifier (allowed: letters, digits, underscore, '!')" "$what" "$name"
}

require_repo_charset() {
  local name="$1" what="$2"
  printf '%s' "$name" | grep -qE '^[A-Za-z0-9._-]+$' ||
    fail "%s '%s' contains a character GitHub does not allow in a repository name" "$what" "$name"
}

resolve_repo_name() {
  local url base
  if [ -n "$repo_name_arg" ]; then printf '%s' "$repo_name_arg"; return 0; fi
  if [ -n "${GITHUB_REPOSITORY:-}" ]; then printf '%s' "${GITHUB_REPOSITORY##*/}"; return 0; fi
  if command -v git >/dev/null 2>&1 &&
    git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    url="$(git -C "$root" remote get-url origin 2>/dev/null || true)"
    if [ -n "$url" ]; then
      base="${url##*/}"
      printf '%s' "${base%.git}"
      return 0
    fi
  fi
  fail "cannot determine the repository name: pass --repo-name, or set GITHUB_REPOSITORY, or run inside a clone with an origin remote"
}

# ── output blocks ───────────────────────────────────────────────────────────

emit_header() {
  local module_name="$1" generated_note="$2"
  cat <<EOF
-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- GENERATED FILE. DO NOT EDIT BY HAND.
${generated_note}
--
-- The names in this module are transcribed by the generator; every obligation
-- below is decided by Agda when the module is typechecked. A wrong name is a
-- type error, not a warning.

{-# OPTIONS --safe --without-K --double-check #-}

module ${module_name} where

open import Agda.Builtin.Char     using (Char)
open import Agda.Builtin.List     using (List; []; _∷_)
open import Agda.Builtin.Equality using (_≡_; refl)
open import PackageNaming
open import IdentifierCharset
EOF
}

# The obligations that any concrete package name has to discharge. The witnesses
# name real constructors, so Agda checks them against the real characters.
emit_name_obligations() {
  local prefix="$1" pkg="$2" first rest start_ctor first_ctor chars tail_chars tail_witness
  first="${pkg:0:1}"
  rest="${pkg:1}"
  start_ctor="$(identstart_ctor "$first")" || fail "'%s' cannot begin a Julia identifier" "$first"
  first_ctor="$(identchar_ctor "$first")" || fail "'%s' is not a legal identifier character" "$first"
  chars="$(agda_chars "$pkg")"
  tail_chars="$(agda_chars_or_nil "$rest")"
  tail_witness="$(all_ident_chars_witness "$rest")"

  cat <<EOF

-- Package name as characters: "${pkg}"
${prefix}Package : List Char
${prefix}Package = ${chars}

${prefix}PackageTail : List Char
${prefix}PackageTail = ${tail_chars}

-- Non-emptiness. The witness names the actual head and tail, so a name that
-- reduced to the empty list would not typecheck here.
${prefix}-package-nonempty : NonEmpty ${prefix}Package
${prefix}-package-nonempty = nonempty '${first}' ${prefix}PackageTail

-- The first character satisfies the leading-character rule. The constructor
-- below is checked against the real first character: naming the wrong one is a
-- type error, which is what makes this a check and not a decoration.
${prefix}-package-start : IdentStart (head ${prefix}-package-nonempty)
${prefix}-package-start = ${start_ctor}

-- Every character of the tail is legal, and therefore so is every character of
-- the name.
${prefix}-package-tail-charset : AllIdentChars ${prefix}PackageTail
${prefix}-package-tail-charset = ${tail_witness}

${prefix}-package-charset : AllIdentChars ${prefix}Package
${prefix}-package-charset = aic-cons ${first_ctor} ${prefix}-package-tail-charset

-- Therefore the package name is a legal Julia identifier. The implicit arguments
-- are given explicitly so that nothing here depends on Agda inferring the head
-- character from the witness type.
${prefix}-package-legal : LegalIdent ${prefix}Package
${prefix}-package-legal =
  legal-stop {x = '${first}'} {xs = ${prefix}PackageTail}
    ${prefix}-package-start ${prefix}-package-tail-charset
EOF
}

emit_canonical() {
  local pkg="$1"
  emit_header "CanonicalIdentity" \
    "-- Regenerate with: bash scripts/gen-identity-agda.sh --mode canonical
-- Source of the data: Project.toml in this repository (name = \"...\"). The
-- repository name is not read from anywhere: it is built from the package name
-- by repoNameOf, the rule proved in PackageNaming. This module is the DECIDED
-- identity; generated/agda/LiveIdentity.agda is the OBSERVED one, and the gate
-- stays red while they differ."

  emit_name_obligations "canonical" "$pkg"

  cat <<EOF

-- Repository name: "${pkg}.jl", by the rule rather than by observation.
canonicalRepo : List Char
canonicalRepo = repoNameOf canonicalPackage

canonicalIdentity : Identity
canonicalIdentity = identity canonicalRepo canonicalPackage

-- The decided identity satisfies the reconciliation invariant.
canonical-reconciled : Reconciled canonicalIdentity
canonical-reconciled = refl

-- The decided repository name is NOT a legal Julia identifier: it carries the
-- ".jl" suffix, and '.' is not an identifier character. That is the structural
-- reason a repository name can never be the name of the package it holds, and it
-- is proved here rather than asserted in a document.
canonical-repo-not-legal-ident : ¬ (LegalIdent canonicalRepo)
canonical-repo-not-legal-ident = repo-form-not-legal-ident canonicalPackage
EOF
}

emit_live() {
  local pkg="$1" repo="$2" repo_chars
  repo_chars="$(agda_chars "$repo")"
  emit_header "LiveIdentity" \
    "-- Regenerated at check time; never committed:
--     bash scripts/gen-identity-agda.sh --mode live --out generated/agda/LiveIdentity.agda
-- Provenance, echoed by the generating step into the CI log:
--   package name     <- Project.toml  (\"${pkg}\")
--   repository name  <- ${repo}
-- The two values are read from different places on purpose: if only one of them
-- changes, the obligations below stop typechecking."

  cat <<EOF

open import CanonicalIdentity using (canonicalPackage; canonicalRepo)

-- Repository name as observed: "${repo}"
liveRepo : List Char
liveRepo = ${repo_chars}
EOF

  emit_name_obligations "live" "$pkg"

  cat <<EOF

liveIdentity : Identity
liveIdentity = identity liveRepo livePackage

-- THE GATE. This typechecks only if the observed repository name reduces to
-- exactly the observed package name with ".jl" appended. The generating script
-- does not decide this and could not: Agda decides it by evaluating both sides.
live-reconciled : Reconciled liveIdentity
live-reconciled = refl

-- Drift guards. The observed identity must equal the decided one, so neither
-- side can move without the other, and a half-applied rename fails here instead
-- of surviving as a review comment somebody did not read.
live-package-is-canonical-package : livePackage ≡ canonicalPackage
live-package-is-canonical-package = refl

live-repo-is-canonical-repo : liveRepo ≡ canonicalRepo
live-repo-is-canonical-repo = refl
EOF
}

emit_retired() {
  local register="$1" n=0 name target witness word found_any=0
  [ -f "$register" ] || fail "%s does not exist" "$register"
  emit_header "RetiredNames" \
    "-- Regenerate with: bash scripts/gen-identity-agda.sh --mode retired
-- Source of the data: docs/naming/retired-names.txt (one retired name per line;
-- blank lines and lines beginning '#' are ignored). Each retired name is proved
-- here to be something a Julia package could never have been called, which is
-- why it had to be retired rather than adopted."

  while IFS= read -r name || [ -n "$name" ]; do
    case "$name" in '' | '#'*) continue ;; esac
    # Trim trailing whitespace/carriage returns.
    name="${name%"${name##*[![:space:]]}"}"
    [ -n "$name" ] || continue
    require_repo_charset "$name" "retired name"
    n=$((n + 1))
    found_any=1
    target=""
    witness=""
    for candidate in '-' '.'; do
      if witness="$(any_char_witness "$name" "$candidate")"; then
        target="$candidate"
        break
      fi
    done
    [ -n "$target" ] ||
      fail "retired name '%s' contains no character that is illegal in a Julia identifier, so no refutation can be generated; extend the generator rather than weakening the claim" "$name"
    case "$target" in
      '-') word="hyphen" ;;
      '.') word="dot" ;;
      *) fail "no lemma name for illegal character '%s'" "$target" ;;
    esac
    cat <<EOF

-- Retired name ${n}: "${name}" (docs/naming/retired-names.txt)
retiredName${n} : List Char
retiredName${n} = $(agda_chars "$name")

-- The offending character, pointed at rather than searched for at runtime.
retired-name${n}-illegal-char : Any (IsChar '${target}') retiredName${n}
retired-name${n}-illegal-char = ${witness}

-- Therefore this name is not a legal Julia identifier, and no package could ever
-- have carried it.
retired-name${n}-not-legal-ident : ¬ (LegalIdent retiredName${n})
retired-name${n}-not-legal-ident (legal-stop start-witness charset-witness) =
  legal-ident-excludes ${word}-not-ident-char ${word}-not-ident-start
    start-witness charset-witness retired-name${n}-illegal-char
EOF
  done <"$register"

  [ "$found_any" -eq 1 ] || fail "%s declares no retired names" "$register"
  printf '\n-- %d retired name(s) refuted.\n' "$n"
}

write_out() {
  local dest="$1"
  if [ -n "$out" ]; then dest="$out"; fi
  mkdir -p "$(dirname -- "$dest")"
  cat >"${dest}.tmp"
  mv -- "${dest}.tmp" "$dest"
  printf 'generated %s\n' "$dest" >&2
}

# ── main ────────────────────────────────────────────────────────────────────

project_toml="${root}/Project.toml"
pkg="$(package_name_from_project_toml "$project_toml")"
require_legal_identifier "$pkg" "package name from ${project_toml}"

case "$mode" in
  canonical)
    emit_canonical "$pkg" | write_out "${root}/proofs/agda/CanonicalIdentity.agda"
    ;;
  live)
    repo="$(resolve_repo_name)"
    require_repo_charset "$repo" "repository name"
    emit_live "$pkg" "$repo" | write_out "generated/agda/LiveIdentity.agda"
    ;;
  retired)
    emit_retired "${root}/docs/naming/retired-names.txt" |
      write_out "${root}/proofs/agda/RetiredNames.agda"
    ;;
  check-committed)
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    status=0

    bash "${root}/scripts/gen-identifier-charset.sh" --out "${tmp}/IdentifierCharset.agda" >/dev/null
    emit_canonical "$pkg" >"${tmp}/CanonicalIdentity.agda"

    compare() { # committed, regenerated, regenerate-hint
      if [ ! -f "$1" ]; then
        printf 'FAIL: %s is missing from the tree\n' "$1" >&2
        status=1
      elif ! diff -u --label "committed:$1" --label "regenerated" "$1" "$2"; then
        printf 'FAIL: %s does not match its generator — %s\n' "$1" "$3" >&2
        status=1
      fi
    }

    compare "${root}/proofs/agda/IdentifierCharset.agda" "${tmp}/IdentifierCharset.agda" \
      "regenerate with scripts/gen-identifier-charset.sh"
    compare "${root}/proofs/agda/CanonicalIdentity.agda" "${tmp}/CanonicalIdentity.agda" \
      "regenerate with scripts/gen-identity-agda.sh --mode canonical"

    if [ -f "${root}/docs/naming/retired-names.txt" ]; then
      emit_retired "${root}/docs/naming/retired-names.txt" >"${tmp}/RetiredNames.agda"
      compare "${root}/proofs/agda/RetiredNames.agda" "${tmp}/RetiredNames.agda" \
        "regenerate with scripts/gen-identity-agda.sh --mode retired"
    elif [ -f "${root}/proofs/agda/RetiredNames.agda" ]; then
      printf 'FAIL: proofs/agda/RetiredNames.agda is committed but docs/naming/retired-names.txt is gone\n' >&2
      status=1
    fi

    if [ "$status" -eq 0 ]; then
      printf 'PASS: committed generated Agda modules match their generators\n'
    fi
    exit "$status"
    ;;
esac
