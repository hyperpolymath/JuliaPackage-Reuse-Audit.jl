-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- All — the whole development in one import.
--
-- Checked by tests/check-proofs.sh, which does not rely on this file: it walks
-- proofs/agda recursively, so a module added later is gated even if nobody
-- remembers to list it here. This module exists so a human (or `agda All.agda`)
-- can check everything in one go.
--
-- generated/agda/LiveIdentity.agda is deliberately NOT imported here. It does
-- not exist in a fresh clone: it is produced at check time from live repository
-- state by scripts/gen-identity-agda.sh, and tests/check-proofs.sh fails if it
-- is missing rather than quietly checking less.

{-# OPTIONS --safe --without-K --double-check #-}

module All where

open import PackageNaming public
open import IdentifierCharset public
open import CanonicalIdentity public
open import RetiredNames public
