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
  cA : IdentChar 'A'
  cB : IdentChar 'B'
  cC : IdentChar 'C'
  cD : IdentChar 'D'
  cE : IdentChar 'E'
  cF : IdentChar 'F'
  cG : IdentChar 'G'
  cH : IdentChar 'H'
  cI : IdentChar 'I'
  cJ : IdentChar 'J'
  cK : IdentChar 'K'
  cL : IdentChar 'L'
  cM : IdentChar 'M'
  cN : IdentChar 'N'
  cO : IdentChar 'O'
  cP : IdentChar 'P'
  cQ : IdentChar 'Q'
  cR : IdentChar 'R'
  cS : IdentChar 'S'
  cT : IdentChar 'T'
  cU : IdentChar 'U'
  cV : IdentChar 'V'
  cW : IdentChar 'W'
  cX : IdentChar 'X'
  cY : IdentChar 'Y'
  cZ : IdentChar 'Z'
  ca : IdentChar 'a'
  cb : IdentChar 'b'
  cc : IdentChar 'c'
  cd : IdentChar 'd'
  ce : IdentChar 'e'
  cf : IdentChar 'f'
  cg : IdentChar 'g'
  ch : IdentChar 'h'
  ci : IdentChar 'i'
  cj : IdentChar 'j'
  ck : IdentChar 'k'
  cl : IdentChar 'l'
  cm : IdentChar 'm'
  cn : IdentChar 'n'
  co : IdentChar 'o'
  cp : IdentChar 'p'
  cq : IdentChar 'q'
  cr : IdentChar 'r'
  cs : IdentChar 's'
  ct : IdentChar 't'
  cu : IdentChar 'u'
  cv : IdentChar 'v'
  cw : IdentChar 'w'
  cx : IdentChar 'x'
  cy : IdentChar 'y'
  cz : IdentChar 'z'
  cDigit0 : IdentChar '0'
  cDigit1 : IdentChar '1'
  cDigit2 : IdentChar '2'
  cDigit3 : IdentChar '3'
  cDigit4 : IdentChar '4'
  cDigit5 : IdentChar '5'
  cDigit6 : IdentChar '6'
  cDigit7 : IdentChar '7'
  cDigit8 : IdentChar '8'
  cDigit9 : IdentChar '9'
  cUnderscore : IdentChar '_'
  cBang : IdentChar '!'

-- Characters that may begin a Julia identifier. Digits and '!' may not.
data IdentStart : Char -> Set where
  sA : IdentStart 'A'
  sB : IdentStart 'B'
  sC : IdentStart 'C'
  sD : IdentStart 'D'
  sE : IdentStart 'E'
  sF : IdentStart 'F'
  sG : IdentStart 'G'
  sH : IdentStart 'H'
  sI : IdentStart 'I'
  sJ : IdentStart 'J'
  sK : IdentStart 'K'
  sL : IdentStart 'L'
  sM : IdentStart 'M'
  sN : IdentStart 'N'
  sO : IdentStart 'O'
  sP : IdentStart 'P'
  sQ : IdentStart 'Q'
  sR : IdentStart 'R'
  sS : IdentStart 'S'
  sT : IdentStart 'T'
  sU : IdentStart 'U'
  sV : IdentStart 'V'
  sW : IdentStart 'W'
  sX : IdentStart 'X'
  sY : IdentStart 'Y'
  sZ : IdentStart 'Z'
  sa : IdentStart 'a'
  sb : IdentStart 'b'
  sc : IdentStart 'c'
  sd : IdentStart 'd'
  se : IdentStart 'e'
  sf : IdentStart 'f'
  sg : IdentStart 'g'
  sh : IdentStart 'h'
  si : IdentStart 'i'
  sj : IdentStart 'j'
  sk : IdentStart 'k'
  sl : IdentStart 'l'
  sm : IdentStart 'm'
  sn : IdentStart 'n'
  so : IdentStart 'o'
  sp : IdentStart 'p'
  sq : IdentStart 'q'
  sr : IdentStart 'r'
  ss : IdentStart 's'
  st : IdentStart 't'
  su : IdentStart 'u'
  sv : IdentStart 'v'
  sw : IdentStart 'w'
  sx : IdentStart 'x'
  sy : IdentStart 'y'
  sz : IdentStart 'z'
  sUnderscore : IdentStart '_'

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
charset-excludes bad (x ∷ xs) (aic-cons ic ics) (any-here h) =
  bad (subst IdentChar h ic)
charset-excludes bad (x ∷ xs) (aic-cons ic ics) (any-there a) =
  charset-excludes bad xs ics a

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

-- The '.' of the ".jl" suffix occurs in any name of the form cs ++ ".jl".
suffix-has-dot : (cs : List Char) -> Any (IsChar '.') (cs ++ jlSuffix)
suffix-has-dot [] = any-here refl
suffix-has-dot (c ∷ cs) = any-there (suffix-has-dot cs)

-- Therefore no repository-form name is a legal Julia identifier, for any package
-- name whatsoever. A repository name cannot be the name of the package it holds,
-- and the pair of names has to be reconciled by rule rather than by being made
-- identical.
--
-- The package name is an explicit argument and is split first, so by the time
-- legal-stop is matched the index is concrete and no witness carries a variable
-- index. That is the shape charset-excludes uses, and the one Agda accepts.
repo-form-not-legal-ident : (pkg : List Char) -> ¬ (LegalIdent (repoNameOf pkg))
repo-form-not-legal-ident pkg legal =
  legal-ident-excludes dot-not-ident-char dot-not-ident-start
    (LegalIdent.start legal) (LegalIdent.charset legal)
    (subst (Any (IsChar '.')) (sym (LegalIdent.shape legal)) (suffix-has-dot pkg))
