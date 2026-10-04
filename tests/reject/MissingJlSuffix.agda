-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
{-# OPTIONS --safe --without-K #-}
module MissingJlSuffix where

open import Agda.Builtin.Equality using (refl)
open import PackageNaming
open import CanonicalIdentity using (canonicalPackage)

-- Deliberately false: a repository whose name is exactly its package name, with
-- no ".jl" suffix. PackageNaming.repoNameOf-not-identity proves no such name can
-- satisfy the reconciliation invariant, so the claim below has to be rejected.
-- The verifier requires a type mismatch here.
falseClaim : Reconciled (identity canonicalPackage canonicalPackage)
falseClaim = refl
