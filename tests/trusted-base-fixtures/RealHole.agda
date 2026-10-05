-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-- Fixture: an unfinished proof. This file MUST be flagged by the trusted-base
-- scan. It is never typechecked.
{-# OPTIONS --safe --without-K #-}

module RealHole where

open import Agda.Builtin.Bool using (Bool; true)

unfinished : Bool -> Bool
unfinished b = {! b !}
