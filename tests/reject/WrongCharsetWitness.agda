-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
{-# OPTIONS --safe --without-K #-}
module WrongCharsetWitness where

open import Agda.Builtin.Char using (Char)
open import IdentifierCharset

-- Deliberately false: a witness that a hyphen is a legal Julia identifier
-- character, offered as the constructor for 'J'. The charset datatype is indexed
-- by the character itself, so the wrong constructor is a type error rather than
-- a style problem. This is the check that stops a generator emitting witnesses
-- for names it should have refused. The verifier requires a type mismatch here.
falseClaim : IdentChar '-'
falseClaim = char-J
