-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-- Fixture: no OPTIONS pragma at all, so nothing in the file commits to the
-- discipline. This file MUST be flagged even though it contains no hatch: the
-- requirement is positive, not only a ban list.
module MissingSafeOption where

open import Agda.Builtin.Bool using (Bool; true)

trivial : Bool
trivial = true
