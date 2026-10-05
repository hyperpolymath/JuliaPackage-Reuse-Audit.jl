-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- Fixture: the words below appear ONLY in comments. This file must pass the
-- trusted-base scan. A scanner that matches prose is the defect cicd-suite
-- recorded against its own code-hygiene-check: it flagged 112 files in one
-- repository and 313 in another, almost all of them documents that discussed a
-- marker rather than used one.
--
-- This development uses no postulate, leaves no hole, and carries no
-- TERMINATING or NO_POSITIVITY_CHECK pragma. It never writes {? or !}.
{-# OPTIONS --safe --without-K --double-check #-}

module MentionsInComments where

open import Agda.Builtin.Bool using (Bool; true; false)

-- A real, checked definition.
isTrue : Bool -> Bool
isTrue true = true
isTrue false = false
