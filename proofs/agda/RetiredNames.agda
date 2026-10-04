-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- GENERATED FILE. DO NOT EDIT BY HAND.
-- Regenerate with: bash scripts/gen-identity-agda.sh --mode retired
-- Source of the data: docs/naming/retired-names.txt (one retired name per line;
-- blank lines and lines beginning '#' are ignored). Each retired name is proved
-- here to be something a Julia package could never have been called, which is
-- why it had to be retired rather than adopted.
--
-- The names in this module are transcribed by the generator; every obligation
-- below is decided by Agda when the module is typechecked. A wrong name is a
-- type error, not a warning.

{-# OPTIONS --safe --without-K --double-check #-}

module RetiredNames where

open import Agda.Builtin.Char     using (Char)
open import Agda.Builtin.List     using (List; []; _∷_)
open import Agda.Builtin.Equality using (_≡_; refl)
open import PackageNaming
open import IdentifierCharset

-- Retired name 1: "JuliaPackage-Reuse-Audit.jl" (docs/naming/retired-names.txt)
retiredName1 : List Char
retiredName1 = 'J' ∷ 'u' ∷ 'l' ∷ 'i' ∷ 'a' ∷ 'P' ∷ 'a' ∷ 'c' ∷ 'k' ∷ 'a' ∷ 'g' ∷ 'e' ∷ '-' ∷ 'R' ∷ 'e' ∷ 'u' ∷ 's' ∷ 'e' ∷ '-' ∷ 'A' ∷ 'u' ∷ 'd' ∷ 'i' ∷ 't' ∷ '.' ∷ 'j' ∷ 'l' ∷ []

-- The offending character, pointed at rather than searched for at runtime.
retired-name1-illegal-char : Any (IsChar '-') retiredName1
retired-name1-illegal-char = any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-here refl))))))))))))

-- Therefore this name is not a legal Julia identifier, and no package could ever
-- have carried it.
retired-name1-not-legal-ident : ¬ (LegalIdent retiredName1)
retired-name1-not-legal-ident legal =
  legal-ident-excludes hyphen-not-ident-char hyphen-not-ident-start
    retiredName1 legal retired-name1-illegal-char

-- Retired name 2: "JuliaPackage-Reuse-Audit" (docs/naming/retired-names.txt)
retiredName2 : List Char
retiredName2 = 'J' ∷ 'u' ∷ 'l' ∷ 'i' ∷ 'a' ∷ 'P' ∷ 'a' ∷ 'c' ∷ 'k' ∷ 'a' ∷ 'g' ∷ 'e' ∷ '-' ∷ 'R' ∷ 'e' ∷ 'u' ∷ 's' ∷ 'e' ∷ '-' ∷ 'A' ∷ 'u' ∷ 'd' ∷ 'i' ∷ 't' ∷ []

-- The offending character, pointed at rather than searched for at runtime.
retired-name2-illegal-char : Any (IsChar '-') retiredName2
retired-name2-illegal-char = any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-here refl))))))))))))

-- Therefore this name is not a legal Julia identifier, and no package could ever
-- have carried it.
retired-name2-not-legal-ident : ¬ (LegalIdent retiredName2)
retired-name2-not-legal-ident legal =
  legal-ident-excludes hyphen-not-ident-char hyphen-not-ident-start
    retiredName2 legal retired-name2-illegal-char

-- Retired name 3: "juliapackage-reuse-audit" (docs/naming/retired-names.txt)
retiredName3 : List Char
retiredName3 = 'j' ∷ 'u' ∷ 'l' ∷ 'i' ∷ 'a' ∷ 'p' ∷ 'a' ∷ 'c' ∷ 'k' ∷ 'a' ∷ 'g' ∷ 'e' ∷ '-' ∷ 'r' ∷ 'e' ∷ 'u' ∷ 's' ∷ 'e' ∷ '-' ∷ 'a' ∷ 'u' ∷ 'd' ∷ 'i' ∷ 't' ∷ []

-- The offending character, pointed at rather than searched for at runtime.
retired-name3-illegal-char : Any (IsChar '-') retiredName3
retired-name3-illegal-char = any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-here refl))))))))))))

-- Therefore this name is not a legal Julia identifier, and no package could ever
-- have carried it.
retired-name3-not-legal-ident : ¬ (LegalIdent retiredName3)
retired-name3-not-legal-ident legal =
  legal-ident-excludes hyphen-not-ident-char hyphen-not-ident-start
    retiredName3 legal retired-name3-illegal-char

-- 3 retired name(s) refuted.
