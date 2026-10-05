-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
{-# OPTIONS --safe --without-K #-}
module MismatchedRepoName where

open import Agda.Builtin.Equality using (refl)
open import PackageNaming
open import CanonicalIdentity using (canonicalPackage)
open import RetiredNames using (retiredName1)

-- Deliberately false. This is the state this repository was actually in before
-- the rename: a repository called "JuliaPackage-Reuse-Audit.jl" holding a
-- package called "JuliaPackageSpitter". Both names are taken from the committed
-- modules rather than retyped here, so the fixture keeps reproducing the real
-- defect instead of a strawman. The verifier requires a type mismatch at the
-- claim below.
falseClaim : Reconciled (identity retiredName1 canonicalPackage)
falseClaim = refl
