-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- GENERATED FILE. DO NOT EDIT BY HAND.
-- Regenerate with: bash scripts/gen-identity-agda.sh --mode canonical
-- Source of the data: Project.toml in this repository (name = "..."). The
-- repository name is not read from anywhere: it is built from the package name
-- by repoNameOf, the rule proved in PackageNaming. This module is the DECIDED
-- identity; generated/agda/LiveIdentity.agda is the OBSERVED one, and the gate
-- stays red while they differ.
--
-- The names in this module are transcribed by the generator; every obligation
-- below is decided by Agda when the module is typechecked. A wrong name is a
-- type error, not a warning.

{-# OPTIONS --safe --without-K --double-check #-}

module CanonicalIdentity where

open import Agda.Builtin.Char     using (Char)
open import Agda.Builtin.List     using (List; []; _∷_)
open import Agda.Builtin.Equality using (_≡_; refl)
open import PackageNaming
open import IdentifierCharset

-- Package name as characters: "JuliaPackageSpitter"
canonicalPackage : List Char
canonicalPackage = 'J' ∷ 'u' ∷ 'l' ∷ 'i' ∷ 'a' ∷ 'P' ∷ 'a' ∷ 'c' ∷ 'k' ∷ 'a' ∷ 'g' ∷ 'e' ∷ 'S' ∷ 'p' ∷ 'i' ∷ 't' ∷ 't' ∷ 'e' ∷ 'r' ∷ []

canonicalPackageTail : List Char
canonicalPackageTail = 'u' ∷ 'l' ∷ 'i' ∷ 'a' ∷ 'P' ∷ 'a' ∷ 'c' ∷ 'k' ∷ 'a' ∷ 'g' ∷ 'e' ∷ 'S' ∷ 'p' ∷ 'i' ∷ 't' ∷ 't' ∷ 'e' ∷ 'r' ∷ []

-- Non-emptiness. The witness names the actual head and tail, so a name that
-- reduced to the empty list would not typecheck here.
canonical-package-nonempty : NonEmpty canonicalPackage
canonical-package-nonempty = nonempty 'J' canonicalPackageTail

-- The first character satisfies the leading-character rule. The constructor
-- below is checked against the real first character: naming the wrong one is a
-- type error, which is what makes this a check and not a decoration.
canonical-package-start : IdentStart (head canonical-package-nonempty)
canonical-package-start = sJ

-- Every character of the tail is legal, and therefore so is every character of
-- the name.
canonical-package-tail-charset : AllIdentChars canonicalPackageTail
canonical-package-tail-charset = aic-cons cu (aic-cons cl (aic-cons ci (aic-cons ca (aic-cons cP (aic-cons ca (aic-cons cc (aic-cons ck (aic-cons ca (aic-cons cg (aic-cons ce (aic-cons cS (aic-cons cp (aic-cons ci (aic-cons ct (aic-cons ct (aic-cons ce (aic-cons cr (aic-nil))))))))))))))))))

canonical-package-charset : AllIdentChars canonicalPackage
canonical-package-charset = aic-cons cJ canonical-package-tail-charset

-- Therefore the package name is a legal Julia identifier.
canonical-package-legal : LegalIdent canonicalPackage
canonical-package-legal = legal-stop canonical-package-start canonical-package-tail-charset

-- Repository name: "JuliaPackageSpitter.jl", by the rule rather than by observation.
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
