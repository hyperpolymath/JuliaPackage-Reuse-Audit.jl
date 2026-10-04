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
-- character — see charset-excludes, and the note below explaining why there is
-- deliberately no general legal-identifier version of it.
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
open import PackageNaming using (⊥; ¬_; subst; _++_; jlSuffix; repoNameOf)

-- Characters that may appear anywhere in a Julia identifier.
data IdentChar : Char -> Set where
HEADER

  # Constructor names are spelled char-X, not cX: cX collides with ordinary
  # variable names. Agda parses a pattern position greedily, so a clause variable
  # called `st` was read as the IdentStart constructor for 't' and the clause was
  # rejected as impossible ("'t' ≟ '.'"). A prefix that no variable would use
  # removes the trap instead of documenting it.
  for c in $upper; do printf "  char-%s : IdentChar '%s'\n" "$c" "$c"; done
  for c in $lower; do printf "  char-%s : IdentChar '%s'\n" "$c" "$c"; done
  for c in $digits; do printf "  char-%s : IdentChar '%s'\n" "$c" "$c"; done
  printf "  char-underscore : IdentChar '_'\n"
  printf "  char-bang : IdentChar '!'\n"

  cat <<'BODY'

-- Characters that may begin a Julia identifier. Digits and '!' may not.
data IdentStart : Char -> Set where
BODY

  for c in $upper; do printf "  start-%s : IdentStart '%s'\n" "$c" "$c"; done
  for c in $lower; do printf "  start-%s : IdentStart '%s'\n" "$c" "$c"; done
  printf "  start-underscore : IdentStart '_'\n"

  cat <<'BODY'

-- Every character of a list is legal. This constrains the whole list; LegalIdent
-- below pairs it with the leading-character rule.
data AllIdentChars : List Char -> Set where
  aic-nil  : AllIdentChars []
  aic-cons : {x : Char} {xs : List Char}
           -> IdentChar x -> AllIdentChars xs -> AllIdentChars (x ∷ xs)

-- A legal Julia package name: non-empty, legal first character, legal characters
-- throughout the tail.
data LegalIdent : List Char -> Set where
  legal-stop : {x : Char} {xs : List Char}
             -> IdentStart x -> AllIdentChars xs -> LegalIdent (x ∷ xs)

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
charset-excludes bad (x ∷ xs) (aic-cons hereChar restChars) (any-here h) =
  bad (subst IdentChar h hereChar)
charset-excludes bad (x ∷ xs) (aic-cons hereChar restChars) (any-there a) =
  charset-excludes bad xs restChars a

-- There is deliberately no general lemma of the shape
--
--     {c x xs} -> IdentStart x -> AllIdentChars xs -> Any (IsChar c) (x ∷ xs) -> ⊥
--
-- here. Three formulations of it were tried and Agda's coverage checker rejected
-- all three, each time demanding one missing case per IdentStart constructor:
--
--   legal-ident-excludes x x₁ (legal-stop sA x₂) (any-here x₃)   -- data type
--   legal-ident-excludes x x₁ (.'A' ∷ s) (legal-stop sA x₂) ...  -- list split first
--   legal-ident-excludes x x₁ sA x₂ x₃                           -- components
--
-- The common factor is a function that must consume a witness indexed by a
-- VARIABLE character and also split another indexed argument: Agda splits the
-- witness to pin the character down, and then wants a case per constructor.
-- charset-excludes above does not hit this, because its list is an explicit
-- argument that is split first and pins the index before any witness is matched.
-- Refutations of concrete names therefore go through charset-excludes with the
-- list named — which is what RetiredNames.agda, generated from the naming
-- register, does — and the one general result below splits the package name
-- itself before it touches a witness.

-- Refuting an AllIdentChars witness over an append whose RIGHT side already holds
-- an illegal character.
--
-- Induction is on the left list, and that is the whole trick: `xs ++ ys` is stuck
-- while xs is a variable, so a witness indexed by it cannot be matched. In each
-- clause below xs is [] or x ∷ xs', the append reduces, and the witness becomes
-- matchable. This is also why the general result about repository-form names is
-- proved through here rather than by pointing at a position: the position of the
-- '.' moves with the package name, but which side of the append it is on does not.
append-illegal-refute : {c : Char} -> ¬ (IdentChar c)
                      -> (xs ys : List Char) -> Any (IsChar c) ys
                      -> AllIdentChars (xs ++ ys) -> ⊥
append-illegal-refute bad [] ys a w = charset-excludes bad ys w a
append-illegal-refute bad (x ∷ xs) ys a (aic-cons hereChar restChars) =
  append-illegal-refute bad xs ys a restChars

-- Therefore no repository-form name is a legal Julia identifier, for any package
-- name whatsoever. A repository name cannot be the name of the package it holds,
-- and the pair of names has to be reconciled by rule rather than by being made
-- identical.
--
-- The package name is an explicit argument and is split first, so by the time
-- legal-stop is matched the index has reduced to a cons cell and the witness types
-- come out concrete. The empty name is refuted by the leading-character rule,
-- since ".jl" would have to begin with '.'; a non-empty one by the '.' its suffix
-- carries, through the lemma above.
repo-form-not-legal-ident : (pkg : List Char) -> ¬ (LegalIdent (repoNameOf pkg))
repo-form-not-legal-ident [] (legal-stop startWitness charsetWitness) =
  dot-not-ident-start startWitness
repo-form-not-legal-ident (x ∷ xs) (legal-stop startWitness charsetWitness) =
  append-illegal-refute dot-not-ident-char xs jlSuffix (any-here refl) charsetWitness
BODY
} >"$out.tmp"

mv -- "$out.tmp" "$out"
printf 'generated %s\n' "$out"
