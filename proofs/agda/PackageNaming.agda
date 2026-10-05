-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- PackageNaming — the algebra of repository-name / package-name reconciliation.
--
-- WHAT THIS FILE ESTABLISHES
--
-- A Julia repository that holds a Julia package carries two names: the
-- repository name and the package (module) name. The convention that makes the
-- pair unambiguous is
--
--     repository name  =  package name ++ ".jl"
--
-- This module states that convention once, as a total function `repoNameOf`,
-- and proves the properties that make it a convention rather than a habit:
--
--   round-trip                 recovering the package name from a repository
--                              name returns the package name it came from;
--   packageNameOf-well-defined the recovery does not depend on which witness of
--                              "is a repository name" is supplied;
--   repoNameOf-injective       two different package names never produce the
--                              same repository name (so a repository name
--                              identifies at most one package);
--   repoNameOf-not-identity    the two names are never the same string, which
--                              is precisely why they can drift apart and why
--                              the agreement has to be checked rather than
--                              assumed.
--
-- `Reconciled` is the invariant this repository is gated on. Its two fields are
-- filled in by *generated* modules (CanonicalIdentity, committed, and
-- generated/agda/LiveIdentity, produced at check time from live repository
-- state) and the obligation is discharged by `refl`. That works only because
-- `_++_` is a total function that Agda's evaluator reduces: the equality is
-- decided by the type checker, not by whatever script extracted the strings.
-- A mismatch is a type error, and a type error fails the gate.
--
-- TRUSTED BASE
--
-- Agda's builtin modules only: Char, List, Nat, Equality. No standard library,
-- no axioms, no assumed termination or positivity, no rewriting, no holes.
-- Everything below is either a definition by structural recursion or a proof by
-- induction on one. `scripts/check-agda-trusted-base.sh` enforces a budget of
-- zero for every escape hatch it knows about, and the file is typechecked with
-- --safe --without-K --double-check -W error.
--
-- The only counting argument in the file is `not-self-suffix`, which needs a
-- size measure; that is why Nat and `_+_` are imported at all.

{-# OPTIONS --safe --without-K --double-check #-}

module PackageNaming where

open import Agda.Builtin.Char     using (Char)
open import Agda.Builtin.List     using (List; []; _∷_)
open import Agda.Builtin.Nat      using (Nat; zero; suc; _+_)
open import Agda.Builtin.Equality using (_≡_; refl)

-- ── Falsity, negation, and the equality toolkit ─────────────────────────────
-- Defined here rather than imported: there is no builtin empty type, and taking
-- one from a library would put that library in the trusted base.

data ⊥ : Set where

¬_ : Set -> Set
¬ A = A -> ⊥

⊥-elim : {A : Set} -> ⊥ -> A
⊥-elim ()

sym : {A : Set} {x y : A} -> x ≡ y -> y ≡ x
sym refl = refl

trans : {A : Set} {x y z : A} -> x ≡ y -> y ≡ z -> x ≡ z
trans refl q = q

cong : {A B : Set} {x y : A} -> (f : A -> B) -> x ≡ y -> f x ≡ f y
cong f refl = refl

subst : {A : Set} (P : A -> Set) {x y : A} -> x ≡ y -> P x -> P y
subst P refl p = p

-- ── Lists ───────────────────────────────────────────────────────────────────

infixr 5 _++_

_++_ : {A : Set} -> List A -> List A -> List A
[]       ++ ys = ys
(x ∷ xs) ++ ys = x ∷ (xs ++ ys)

cons-cong : {A : Set} {x y : A} {xs ys : List A}
          -> x ≡ y -> xs ≡ ys -> x ∷ xs ≡ y ∷ ys
cons-cong refl refl = refl

consHeadEq : {A : Set} {x y : A} {xs ys : List A}
           -> x ∷ xs ≡ y ∷ ys -> x ≡ y
consHeadEq refl = refl

consTailEq : {A : Set} {x y : A} {xs ys : List A}
           -> x ∷ xs ≡ y ∷ ys -> xs ≡ ys
consTailEq refl = refl

length : {A : Set} -> List A -> Nat
length []       = zero
length (_ ∷ xs) = suc (length xs)

length-++ : {A : Set} (xs ys : List A)
          -> length (xs ++ ys) ≡ length xs + length ys
length-++ []       ys = refl
length-++ (x ∷ xs) ys = cong suc (length-++ xs ys)

data NonEmpty {A : Set} : List A -> Set where
  nonempty : (x : A) (xs : List A) -> NonEmpty (x ∷ xs)

head : {A : Set} {xs : List A} -> NonEmpty xs -> A
head (nonempty x _) = x

tail : {A : Set} {xs : List A} -> NonEmpty xs -> List A
tail (nonempty _ xs) = xs

-- ── Natural numbers: the size argument ──────────────────────────────────────

suc-injective : {m n : Nat} -> suc m ≡ suc n -> m ≡ n
suc-injective refl = refl

plus-suc : (m n : Nat) -> m + suc n ≡ suc (m + n)
plus-suc zero    n = refl
plus-suc (suc m) n = cong suc (plus-suc m n)

-- No natural number equals a successor of a sum that already contains it.
nat-not-suc-of-sum : (m n : Nat) -> ¬ (n ≡ suc (m + n))
nat-not-suc-of-sum m zero    ()
nat-not-suc-of-sum m (suc n) eq =
  nat-not-suc-of-sum m n
    (subst {A = Nat} (λ k -> n ≡ k) (plus-suc m n) (suc-injective eq))

-- A list is never equal to a cons cell whose tail contains that same list.
-- This is the only place the development needs to measure anything, and it is
-- what makes right-cancellation of append go through.
not-self-suffix : {A : Set} (zs : List A) (y : A) (ys : List A)
                -> ¬ (zs ≡ y ∷ (ys ++ zs))
not-self-suffix zs y ys eq =
  nat-not-suc-of-sum (length ys) (length zs)
    (trans (cong length eq) (cong suc (length-++ ys zs)))

-- Right cancellation for append: equal tails may be dropped from an equality.
append-cancel-right : {A : Set} (xs ys zs : List A)
                    -> xs ++ zs ≡ ys ++ zs -> xs ≡ ys
append-cancel-right []       []       zs eq = refl
append-cancel-right []       (y ∷ ys) zs eq = ⊥-elim (not-self-suffix zs y ys eq)
append-cancel-right (x ∷ xs) []       zs eq = ⊥-elim (not-self-suffix zs x xs (sym eq))
append-cancel-right (x ∷ xs) (y ∷ ys) zs eq =
  cons-cong (consHeadEq eq) (append-cancel-right xs ys zs (consTailEq eq))

-- ── The naming convention ───────────────────────────────────────────────────

-- The ".jl" suffix, as characters. Written out rather than converted from a
-- String literal: conversion of string literals is a primitive whose reduction
-- behaviour is not part of the theory, and this way nothing depends on it.
jlSuffix : List Char
jlSuffix = '.' ∷ 'j' ∷ 'l' ∷ []

-- The convention itself: a repository name is its package name plus ".jl".
repoNameOf : List Char -> List Char
repoNameOf pkg = pkg ++ jlSuffix

-- Evidence that a name is in repository form, carrying the package name it was
-- built from. A record with an explicit prefix field rather than an indexed
-- data type: two witnesses at the same name can then be compared by
-- cancelling the common suffix, which an index refinement cannot express.
record RepoForm (s : List Char) : Set where
  constructor repo-form
  field
    prefix : List Char
    eq     : prefix ++ jlSuffix ≡ s

packageNameOf : (s : List Char) -> RepoForm s -> List Char
packageNameOf s w = RepoForm.prefix w

repo-form-of : (pkg : List Char) -> RepoForm (repoNameOf pkg)
repo-form-of pkg = repo-form pkg refl

-- Going out and coming back is the identity.
round-trip : (pkg : List Char)
           -> packageNameOf (repoNameOf pkg) (repo-form-of pkg) ≡ pkg
round-trip pkg = refl

-- The recovered package name does not depend on the witness chosen, i.e.
-- `packageNameOf` is a function of the repository name alone.
packageNameOf-well-defined : {s : List Char} (w₁ w₂ : RepoForm s)
                           -> packageNameOf s w₁ ≡ packageNameOf s w₂
packageNameOf-well-defined w₁ w₂ =
  append-cancel-right (RepoForm.prefix w₁) (RepoForm.prefix w₂) jlSuffix
    (trans (RepoForm.eq w₁) (sym (RepoForm.eq w₂)))

-- Distinct package names give distinct repository names.
repoNameOf-injective : (p q : List Char) -> repoNameOf p ≡ repoNameOf q -> p ≡ q
repoNameOf-injective p q eq = append-cancel-right p q jlSuffix eq

-- The two names are different roles, never the same string. Proved by
-- induction on the package name: the empty name would have to equal ".jl", and
-- a non-empty one would have to equal its own proper tail.
repoNameOf-not-identity : (pkg : List Char) -> ¬ (repoNameOf pkg ≡ pkg)
repoNameOf-not-identity []       ()
repoNameOf-not-identity (c ∷ cs) eq =
  repoNameOf-not-identity cs (consTailEq eq)

-- ── The gated invariant ─────────────────────────────────────────────────────

record Identity : Set where
  constructor identity
  field
    repo    : List Char
    package : List Char

-- Reconciled: the repository name is exactly the package name with ".jl"
-- appended. Discharging this by `refl` is the check — Agda has to reduce both
-- sides to the same list of characters before it will accept the proof.
Reconciled : Identity -> Set
Reconciled id = Identity.repo id ≡ repoNameOf (Identity.package id)

-- The reconciliation invariant implies the repository name is in repository
-- form, and names the package it recovers. So a repository that satisfies the
-- gate can always be mapped back to the package it holds.
reconciled-gives-repo-form : (id : Identity) -> Reconciled id -> RepoForm (Identity.repo id)
reconciled-gives-repo-form id r = repo-form (Identity.package id) (sym r)

-- ... and the package recovered from a reconciled repository name is the one
-- the identity recorded. Nothing else could have produced it.
reconciled-recovers-package : (id : Identity) (r : Reconciled id)
                            -> packageNameOf (Identity.repo id) (reconciled-gives-repo-form id r)
                               ≡ Identity.package id
reconciled-recovers-package id r = refl
