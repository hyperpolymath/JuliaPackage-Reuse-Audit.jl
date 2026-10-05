-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-- Fixture: a pragma that switches off a check. This file MUST be flagged by the
-- trusted-base scan. It is never typechecked.
{-# OPTIONS --safe --without-K #-}

module UnsafePragma where

open import Agda.Builtin.Bool using (Bool; true)

{-# TERMINATING #-}
loop : Bool
loop = loop
