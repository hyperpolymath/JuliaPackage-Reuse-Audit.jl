-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
{-# OPTIONS --safe --without-K #-}
module RetiredNameIsLegal where

open import Agda.Builtin.List using (List; [])
open import IdentifierCharset
open import RetiredNames using (retiredName1)

-- Deliberately false: the charset witness a retired, hyphenated name would need,
-- offered with the witness for the empty list. RetiredNames proves the opposite,
-- so this has to be rejected. The verifier requires a type mismatch here.
falseClaim : AllIdentChars retiredName1
falseClaim = aic-nil
