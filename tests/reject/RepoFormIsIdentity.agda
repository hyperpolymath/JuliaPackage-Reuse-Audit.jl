-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
{-# OPTIONS --safe --without-K #-}
module RepoFormIsIdentity where

open import Agda.Builtin.Char using (Char)
open import Agda.Builtin.List using (List)
open import Agda.Builtin.Equality using (_≡_; refl)
open import PackageNaming

-- Deliberately false, and the interesting one: it claims the naming convention
-- is the identity, i.e. that a repository name and a package name could be the
-- same string. If this typechecked, repoNameOf-not-identity would be vacuous and
-- the whole reconciliation gate would be decorative. The verifier requires a
-- type mismatch here.
falseClaim : (pkg : List Char) -> repoNameOf pkg ≡ pkg
falseClaim pkg = refl
