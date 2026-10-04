-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
{-# OPTIONS --safe --without-K #-}
module WrongStartWitness where

open import Agda.Builtin.Char using (Char)
open import IdentifierCharset

-- Deliberately false: a witness that a digit may begin a Julia identifier,
-- offered as the constructor for 'A'. The verifier requires a type mismatch here.
falseClaim : IdentStart '1'
falseClaim = sA
