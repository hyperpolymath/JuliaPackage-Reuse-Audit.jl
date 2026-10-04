#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# gen-identifier-charset.sh — regenerate proofs/agda/IdentifierCharset.agda.
#
# The character rule for a Julia package name is written down in exactly one
# place: this script. The generated Agda module is committed and reviewed, and
# the proof gate regenerates it and fails if the committed copy differs. That is
# what stops the rule being widened by hand: every constructor added to the
# committed file would legalise one more character in every name the gate
# checks, and a diff catches it.
#
# Output is deterministic — no timestamps, no versions, no environment — so two
# runs on two machines produce byte-identical files, which is what makes the
# diff check meaningful.
#
# Usage:
#   scripts/gen-identifier-charset.sh [--out PATH]
#     default output: proofs/agda/IdentifierCharset.agda
set -euo pipefail

export LC_ALL=C

out="proofs/agda/IdentifierCharset.agda"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --out) out="${2:?--out needs a path}"; shift 2 ;;
    --out=*) out="${1#--out=}"; shift ;;
    -h | --help) sed -n '4,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'FAIL: gen-identifier-charset: unknown argument %s\n' "$1" >&2; exit 2 ;;
  esac
done

mkdir -p "$(dirname -- "$out")"

upper="A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
lower="a b c d e f g h i j k l m n o p q r s t u v w x y z"
digits="0 1 2 3 4 5 6 7 8 9"

{
  cat <<'HEADER'
-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- IdentifierCharset — the legal-character rule for a Julia package name.
--
-- GENERATED FILE. DO NOT EDIT BY HAND.
-- Regenerate with:  bash scripts/gen-identifier-charset.sh
-- The proof gate regenerates this module and fails if the committed copy
-- differs, so the rule cannot be quietly widened: every constructor added here
-- legalises one more character in every name the gate checks.
--
-- The rule encoded below is the one Julia applies to a module name: a leading
-- letter or underscore, then letters, digits, underscore or '!'. It is encoded
-- as indexed datatypes rather than as a boolean test, so "this character is
-- legal" is a TYPE whose only inhabitants are one constructor per legal
-- character. A name containing an illegal character therefore has no witness at
-- all, and refuting such a name is a matter of pointing at the offending
-- character — see charset-excludes and legal-ident-excludes.
--
-- The two refutation pairs at the bottom are for '-' and '.' because those are
-- the only two characters a GitHub repository name may contain that a Julia
-- identifier may not (repository names are restricted to alphanumerics, '.',
-- '-' and '_'). That is the whole of the gap between the two naming schemes,
-- and it is what makes a hyphenated repository name un-importable and a
-- ".jl"-suffixed one un-importable too.
--
-- Trusted base: Agda builtins plus PackageNaming. No axioms, no holes, no
-- termination or positivity overrides.

{-# OPTIONS --safe --without-K --double-check #-}

module IdentifierCharset where

open import Agda.Builtin.Char     using (Char)
open import Agda.Builtin.List     using (List; []; _∷_)
open import Agda.Builtin.Equality using (_≡_; refl)
open import PackageNaming using (⊥; ¬_; sym; subst; _++_; jlSuffix; repoNameOf)

-- Characters that may appear anywhere in a Julia identifier.
data IdentChar : Char -> Set where
HEADER

  for c in $upper; do printf "  c%s : IdentChar '%s'\n" "$c" "$c"; done
  for c in $lower; do printf "  c%s : IdentChar '%s'\n" "$c" "$c"; done
  for c in $digits; do printf "  cDigit%s : IdentChar '%s'\n" "$c" "$c"; done
  printf "  cUnderscore : IdentChar '_'\n"
  printf "  cBang : IdentChar '!'\n"

  cat <<'BODY'

-- Characters that may begin a Julia identifier. Digits and '!' may not.
data IdentStart : Char -> Set where
BODY

  for c in $upper; do printf "  s%s : IdentStart '%s'\n" "$c" "$c"; done
  for c in $lower; do printf "  s%s : IdentStart '%s'\n" "$c" "$c"; done
  printf "  sUnderscore : IdentStart '_'\n"

  cat <<'BODY'

-- Every character of a list is legal. This constrains the whole list; LegalIdent
-- below pairs it with the leading-character rule.
data AllIdentChars : List Char -> Set where
  aic-nil  : AllIdentChars []
  aic-cons : {x : Char} {xs : List Char}
           -> IdentChar x -> AllIdentChars xs -> AllIdentChars (x ∷ xs)

-- A legal Julia package name: non-empty, legal first character, legal characters
-- throughout the tail, and an equation tying the two to the name itself.
--
-- A RECORD, not a data type, and Agda's coverage checker is the reason. Any
-- function that consumes a LegalIdent and also has to split an Any ends up with
-- an IdentStart field whose index is still a variable, and Agda then splits that
-- field into all 53 of its constructors and reports the clause set as incomplete
-- — one missing case per possible leading character. Two successive data-type
-- formulations hit exactly this, and CI named both:
--
--   Incomplete pattern matching for legal-ident-excludes. Missing cases:
--     legal-ident-excludes x x₁ (legal-stop sA x₂) (any-here x₃)
--     legal-ident-excludes x x₁ sA x₂ (any-here x₃)
--
-- Splitting the list argument first did not help. Projections do not case-split,
-- so with a record the same reasoning goes through with no patterns at all.
record LegalIdent (s : List Char) : Set where
  constructor legal-stop
  field
    {headChar}  : Char
    {tailChars} : List Char
    start   : IdentStart headChar
    charset : AllIdentChars tailChars
    shape   : headChar ∷ tailChars ≡ s

-- Existential over a list, used to point at an offending character.
data Any {A : Set} (P : A -> Set) : List A -> Set where
  any-here  : {x : A} {xs : List A} -> P x -> Any P (x ∷ xs)
  any-there : {x : A} {xs : List A} -> Any P xs -> Any P (x ∷ xs)

IsChar : Char -> Char -> Set
IsChar c x = x ≡ c

-- The two characters a repository name may contain that an identifier may not.
-- Each refutation is an absurd pattern: Agda checks that no constructor of the
-- indexed datatype has that character as its index, so these are decided by the
-- datatypes above and not asserted.
hyphen-not-ident-char : ¬ (IdentChar '-')
hyphen-not-ident-char ()

hyphen-not-ident-start : ¬ (IdentStart '-')
hyphen-not-ident-start ()

dot-not-ident-char : ¬ (IdentChar '.')
dot-not-ident-char ()

dot-not-ident-start : ¬ (IdentStart '.')
dot-not-ident-start ()

-- If a character is not legal, no list of legal characters contains it.
charset-excludes : {c : Char} -> ¬ (IdentChar c)
                 -> (cs : List Char) -> AllIdentChars cs -> ¬ (Any (IsChar c) cs)
charset-excludes bad [] aic-nil ()
charset-excludes bad (x ∷ xs) (aic-cons ic ics) (any-here h) =
  bad (subst IdentChar h ic)
charset-excludes bad (x ∷ xs) (aic-cons ic ics) (any-there a) =
  charset-excludes bad xs ics a

-- Refuting an occurrence in a cons: refute the head and refute the tail. This is
-- the only place an Any is matched, and it is matched alone — no indexed witness
-- sits beside it in the telescope for Agda to split first.
any-cons-elim : {c : Char} {x : Char} {xs : List Char}
              -> ¬ (IsChar c x) -> ¬ (Any (IsChar c) xs)
              -> ¬ (Any (IsChar c) (x ∷ xs))
any-cons-elim notHere _ (any-here h) = notHere h
any-cons-elim _ notThere (any-there a) = notThere a

-- Consequently no legal identifier contains an illegal character, wherever it
-- sits: a leading occurrence is refuted by the leading-character rule, a later
-- one by the charset rule. This is what turns "the retired name could never have
-- been a package name" into a proof instead of an assertion. Defined by
-- composition, with no pattern matching and therefore no case tree to get wrong.
-- The implicit arguments are bound in the clause because xs is used in the body:
-- an omitted implicit is not merely unnamed, it is out of scope.
legal-ident-excludes : {c : Char} -> ¬ (IdentChar c) -> ¬ (IdentStart c)
                     -> {x : Char} {xs : List Char}
                     -> IdentStart x -> AllIdentChars xs
                     -> ¬ (Any (IsChar c) (x ∷ xs))
legal-ident-excludes {c} badChar badStart {x} {xs} st w =
  any-cons-elim (λ h -> badStart (subst IdentStart h st))
                (charset-excludes badChar xs w)

-- The '.' of the ".jl" suffix occurs in any name of the form cs ++ ".jl".
suffix-has-dot : (cs : List Char) -> Any (IsChar '.') (cs ++ jlSuffix)
suffix-has-dot [] = any-here refl
suffix-has-dot (c ∷ cs) = any-there (suffix-has-dot cs)

-- Therefore no repository-form name is a legal Julia identifier, for any package
-- name whatsoever. A repository name cannot be the name of the package it holds,
-- and the pair of names has to be reconciled by rule rather than by being made
-- identical. Again by projection and composition, with no patterns.
repo-form-not-legal-ident : (pkg : List Char) -> ¬ (LegalIdent (repoNameOf pkg))
repo-form-not-legal-ident pkg legal =
  legal-ident-excludes dot-not-ident-char dot-not-ident-start
    (LegalIdent.start legal) (LegalIdent.charset legal)
    (subst (Any (IsChar '.')) (sym (LegalIdent.shape legal)) (suffix-has-dot pkg))
BODY
} >"$out.tmp"

mv -- "$out.tmp" "$out"
printf 'generated %s\n' "$out"
