-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
{-# OPTIONS --safe --without-K #-}
module DriftedCanonical where

open import Agda.Builtin.Equality using (_≡_; refl)
open import CanonicalIdentity using (canonicalRepo; canonicalPackage)

-- Deliberately false: it claims the decided repository name is the decided
-- package name, which is the drift the live module's guards exist to catch.
-- The verifier requires a type mismatch here.
falseClaim : canonicalRepo ≡ canonicalPackage
falseClaim = refl
