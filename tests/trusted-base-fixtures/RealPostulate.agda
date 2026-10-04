-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-- Fixture: a real axiom. This file MUST be flagged by the trusted-base scan.
-- It is never typechecked; it exists so the scanner can be shown to have teeth.
{-# OPTIONS --safe --without-K #-}

module RealPostulate where

open import Agda.Builtin.Bool using (Bool)

postulate
  assumed : Bool
