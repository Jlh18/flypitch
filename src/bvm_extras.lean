/-
Copyright (c) 2019 The Flypitch Project. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Authors: Jesse Han, Floris van Doorn
-/
import .bvm .pSet_ordinal

open lattice

universe u

local infix ` ⟹ `:65 := lattice.imp

local infix ` ⇔ `:50 := lattice.biimp

local prefix `p𝒫`:65 := pSet.powerset

namespace bSet
variables {𝔹 : Type u} [nontrivial_complete_boolean_algebra 𝔹]
section extras

@[simp, cleanup]lemma insert1_bval_none {u v : bSet 𝔹} : (bSet.insert1 u ({v})).bval none  = ⊤ :=
by refl

@[simp, cleanup]lemma insert1_bval_some {u v : bSet 𝔹} {i} : (bSet.insert1 u {v}).bval (some i) = (bval {v}) i :=
by refl

@[simp, cleanup]lemma insert1_func_none {u v : bSet 𝔹} : (bSet.insert1 u ({v})).func none  = u :=
by refl

@[simp, cleanup]lemma insert1_func_some {u v : bSet 𝔹} {i} : (bSet.insert1 u ({v})).func (some i) = (func {v}) i :=
by refl

@[simp]lemma mem_singleton {x : bSet 𝔹} : ⊤ ≤ x ∈ᴮ {x} :=
by {rw[mem_unfold], apply bv_use none, unfold singleton, simp}

lemma eq_of_mem_singleton' {x y : bSet 𝔹} : y ∈ᴮ {x} ≤ x =ᴮ y :=
by {rw[mem_unfold], apply bv_Or_elim, intro i, cases i, simp[bv_eq_symm], repeat{cases i}}

lemma eq_of_mem_singleton {x y : bSet 𝔹} {c : 𝔹} {h : c ≤ y ∈ᴮ {x}} : c ≤ x =ᴮ y :=
le_trans h (by apply eq_of_mem_singleton')

lemma mem_singleton_of_eq {x y : bSet 𝔹} {c : 𝔹} {h : c ≤ x =ᴮ y} : c ≤ y ∈ᴮ {x} :=
begin
  unfold singleton, unfold has_insert.insert,
  rw[mem_insert], simp, apply le_sup_left_of_le, rwa[bv_eq_symm]
end

lemma eq_inserted_of_eq_singleton {x y z : bSet 𝔹} : {x} =ᴮ bSet.insert1 y {z} ≤ x =ᴮ y :=
begin
  rw[bv_eq_unfold], apply bv_specialize_left none, apply bv_specialize_right none,
  unfold singleton, simp, rw[inf_sup_right], apply bv_or_elim,
  apply inf_le_left, apply inf_le_right_of_le, simp[eq_of_mem_singleton']
end

lemma insert1_symm (y z : bSet 𝔹) : ⊤ ≤ bSet.insert1 y {z} =ᴮ bSet.insert1 z {y} :=
begin
  rw[bv_eq_unfold], apply le_inf; bv_intro i; simp; cases i; simp[-top_le_iff],
  {simp[bv_or_right]},
  {cases i; [simp, repeat{cases i}]},
  {simp[bv_or_right]},
  {cases i; [simp, repeat{cases i}]}
end

lemma eq_inserted_of_eq_singleton' {x y z : bSet 𝔹} : {x} =ᴮ bSet.insert1 y {z} ≤ x =ᴮ z :=
by {apply bv_have_true (insert1_symm y z), apply le_trans, apply bv_eq_trans, apply eq_inserted_of_eq_singleton}

def binary_union (x y : bSet 𝔹) : bSet 𝔹 := bv_union {x,y}

lemma unordered_pair_symm (x y : bSet 𝔹) {Γ : 𝔹} : Γ ≤ {x,y} =ᴮ {y,x} :=
begin
  apply mem_ext; unfold has_insert.insert bSet.insert1; bv_intro; bv_imp_intro;
  {simp at *, bv_or_elim_at H, apply le_sup_right_of_le, apply mem_singleton_of_eq,
  from bv_symm H_left, apply le_sup_left_of_le, rw[bv_eq_symm], apply eq_of_mem_singleton,
  from ‹_›}
end

lemma binary_union_symm {x y : bSet 𝔹} {Γ} : Γ ≤ binary_union x y =ᴮ binary_union y x :=
begin
  simp[binary_union], apply mem_ext; bv_intro z; bv_imp_intro,
  have := (bv_union_spec_split {x, y}z).mp ‹_›, rw[bv_union_spec_split],
  bv_cases_at this w, bv_split_at this_1, apply bv_use w,
  refine le_inf _ ‹_›, apply bv_rw' (unordered_pair_symm _ _), simp, from ‹_›,
  have := unordered_pair_symm x y, show 𝔹, from Γ_1,
  have := @bv_rw' 𝔹 _ {x,y} {y,x} Γ_1 this (λ w, z ∈ᴮ bv_union w) (by {simp[B_ext],
  intros x y, tidy_context, have := bv_union_congr a_left,
  change Γ_2 ≤ (λ w, z ∈ᴮ w) (bv_union y),
  convert bv_rw' (bv_symm this) using 1, simp, from ‹_›}),
  apply this, from ‹_›
end

/-- The successor operation on sets (in particular von Neumman ordinals) -/
@[reducible]def succ (x : bSet 𝔹) := bSet.insert1 x x

lemma succ_eq_binary_union {x : bSet 𝔹} {Γ} : Γ ≤ succ x =ᴮ binary_union {x} x :=
begin
  simp[succ, binary_union], apply mem_ext,
  {bv_intro z, simp, bv_imp_intro, bv_or_elim_at H, apply bv_rw' H_left, simp,
   apply (bv_union_spec_split _ x).mpr, apply bv_use ({x} : bSet 𝔹), 
   refine le_inf _ (le_trans (le_top) mem_singleton), change _ ≤ _ ∈ᴮ insert _ _,
   simp, apply le_sup_right_of_le, from le_trans (le_top) mem_singleton,
   apply (bv_union_spec_split _ z).mpr, apply bv_use x, refine le_inf _ ‹_›,
   change _ ≤ _ ∈ᴮ insert _ _, simp},
  {bv_intro z, simp, bv_imp_intro, rw[bv_union_spec_split] at H, bv_cases_at H y,
   bv_split, change Γ_2 ≤ _ ∈ᴮ insert _ _ at H_1_left,
   simp at H_1_left, bv_or_elim_at H_1_left, apply le_sup_right_of_le,
   apply bv_rw' (bv_symm H_left), simp, from ‹_›,
   apply le_sup_left_of_le,
   have : Γ_3 ≤ {x} =ᴮ y, apply eq_of_mem_singleton, from ‹_›,
   suffices : Γ_3 ≤ z ∈ᴮ {x}, rw[bv_eq_symm], apply eq_of_mem_singleton,
   from ‹_›, apply bv_rw' this, simp, from ‹_›}
end

lemma succ_eq_binary_union' {x : bSet 𝔹} {Γ} : Γ ≤ succ x =ᴮ binary_union x {x} :=
by {apply bv_rw' (@binary_union_symm 𝔹 _ x {x} Γ), simp, from succ_eq_binary_union}

@[reducible]def pair (x y : bSet 𝔹) : bSet 𝔹 := {{x}, {x,y}}

-- lemma pair_type (x y : bSet 𝔹) : (pair x y).type = begin end := sorry

--TODO(jesse) write a tactic to automate this type of argument
@[simp]lemma subst_congr_pair_left {x z y : bSet 𝔹} : x =ᴮ z ≤ pair x y =ᴮ pair z y :=
begin
  unfold pair, have this₁ : x =ᴮ z ≤ {{x},{x,y}} =ᴮ {{z},{x,y}} := by simp*,
  have this₂ : x =ᴮ z ≤ {{z},{x,y}} =ᴮ {{z},{z,y}} := by simp*,
  apply bv_context_trans; from ‹_›
end

@[simp]lemma subst_congr_pair_left' {x z y : bSet 𝔹} {Γ : 𝔹} :
  Γ ≤ x=ᴮ z → Γ ≤ pair x y =ᴮ pair z y := poset_yoneda_inv Γ (@subst_congr_pair_left _ _ x z y)

lemma subst_congr_pair_right {x y z : bSet 𝔹} : y =ᴮ z ≤ pair x y =ᴮ pair x z :=
by unfold pair; simp*

lemma subst_congr_pair_right' {Γ} {x y z : bSet 𝔹} (H : Γ ≤ y =ᴮ z) : Γ ≤ pair x y =ᴮ pair x z :=
poset_yoneda_inv Γ (@subst_congr_pair_right _ _ x y z) ‹_›

lemma pair_congr {x₁ x₂ y₁ y₂ : bSet 𝔹} {Γ : 𝔹} {H₁ : Γ ≤ x₁ =ᴮ y₁} {H₂ : Γ ≤ x₂ =ᴮ y₂} : Γ ≤ pair x₁ x₂ =ᴮ pair y₁ y₂ :=
begin
  apply bv_rw' H₁,
    {intros v₁ v₂, tidy_context,
      have : Γ_1 ≤ pair v₂ x₂ =ᴮ pair v₁ x₂,
        by {apply subst_congr_pair_left', rwa[bv_eq_symm]},
      from bv_context_trans this a_right,},
  apply bv_rw' H₂,
    {intros v₁ v₂, tidy_context,
       have : Γ_1 ≤ pair y₁ v₂ =ᴮ pair y₁ v₁,
         by {apply subst_congr_pair_right', rwa[bv_eq_symm]},
       from bv_context_trans this a_right},
  from bv_eq_refl'
end

@[reducible]def B_congr (t : bSet 𝔹 → bSet 𝔹) : Prop := ∀ x₁ x₂, x₁ =ᴮ x₂ ≤ t x₁ =ᴮ t x₂

@[simp]lemma B_ext_term {ϕ : bSet 𝔹 → 𝔹} (H : B_ext ϕ) {t : bSet 𝔹 → bSet 𝔹} (H' : B_congr t) : B_ext (λ z, ϕ ((λ w, t w) z) ) :=
begin
  intros x y, tidy_context,
  suffices : Γ ≤ t x =ᴮ t y,
    by {apply bv_rw' (bv_symm this), from ‹_›, from ‹_›},
  from le_trans ‹_› (H' x y)
end

@[simp]lemma B_congr_pair_left {y : bSet 𝔹} : B_congr (λ x, pair x y) :=
  by {intros x₁ x₂, from @subst_congr_pair_left _ _ _ _ _}

@[simp]lemma B_congr_pair_right {y : bSet 𝔹} : B_congr (λ x, pair y x) :=
  by {intros x₁ x₂, from @subst_congr_pair_right _ _ _ _ _}

@[simp]lemma B_ext_pair_left {ϕ : bSet 𝔹 → 𝔹} {H : B_ext ϕ} {x} : B_ext (λ z, ϕ ((λ w, pair w x) z)) :=
by simp[H]

@[simp]lemma B_ext_pair_right {ϕ : bSet 𝔹 → 𝔹} {H : B_ext ϕ} {x} : B_ext (λ z, ϕ ((λ w, pair x w) z)) := by simp[H]

example {y z : bSet 𝔹} : ⊤ ≤ ({y,z} : bSet 𝔹) =ᴮ ({z,y}) := insert1_symm _ _

lemma eq_of_eq_pair'_left {x z y : bSet 𝔹} : pair x y =ᴮ pair z y ≤ x =ᴮ z :=
begin
  unfold pair, unfold has_insert.insert, rw[bv_eq_unfold], fapply bv_specialize_left,
  exact some none, fapply bv_specialize_right, exact some none, simp,
  rw[inf_sup_right_left_eq], repeat{apply bv_or_elim},
  {apply le_trans, apply inf_le_inf; apply eq_inserted_of_eq_singleton, {[smt] eblast_using[bv_eq_symm, bv_eq_trans]}},
  {apply inf_le_right_of_le, apply le_trans, apply eq_of_mem_singleton', apply eq_of_eq_singleton, refl},
  {apply inf_le_left_of_le, apply le_trans, apply eq_of_mem_singleton', apply eq_of_eq_singleton, rw[bv_eq_symm]},
  {apply inf_le_left_of_le, apply le_trans, apply eq_of_mem_singleton', apply eq_of_eq_singleton, rw[bv_eq_symm]}
end

lemma inserted_eq_of_insert_eq {y v w : bSet 𝔹} : {v,y} =ᴮ {v,w} ≤ y =ᴮ w :=
begin
  unfold has_insert.insert, rw[bv_eq_unfold], apply bv_specialize_left none,
  apply bv_specialize_right none, change (⊤ ⟹ _) ⊓ (⊤ ⟹ _ : 𝔹) ≤ _, simp,
  rw[inf_sup_right_left_eq], repeat{apply bv_or_elim},
  apply inf_le_left, apply inf_le_left, apply inf_le_right_of_le, rw[bv_eq_symm],
  apply le_trans, apply inf_le_inf; apply eq_of_mem_singleton',
  {[smt] eblast_using[bv_eq_symm, bv_eq_trans]}
end

lemma eq_of_eq_pair'_right {x z y : bSet 𝔹} : pair y x =ᴮ pair y z ≤ x =ᴮ z :=
begin
  unfold pair has_insert.insert, rw[bv_eq_unfold], apply bv_specialize_left none,
  apply bv_specialize_right none, unfold singleton, simp, rw[inf_sup_right_left_eq],
  repeat{apply bv_or_elim},
    {apply inf_le_left_of_le, apply inserted_eq_of_insert_eq},
    {apply inf_le_left_of_le, apply inserted_eq_of_insert_eq},
    {apply inf_le_right_of_le, rw[bv_eq_symm], apply inserted_eq_of_insert_eq},
    {apply le_trans, apply inf_le_inf; apply eq_of_mem_singleton',
     apply le_trans, apply inf_le_inf; apply eq_inserted_of_eq_singleton, rw[bv_eq_symm], apply bv_eq_trans}
end


run_cmd do mk_simp_attr `dnf, mk_simp_attr `cnf

attribute [dnf] inf_sup_left inf_sup_right

attribute [cnf] sup_inf_left sup_inf_right

/- Taken together, eq_of_eq_pair_left and eq_of_eq_pair_right say that x = v and y = w if and only if pair x y = pair v w -/
theorem eq_of_eq_pair_left {x y v w: bSet 𝔹} : pair x y =ᴮ pair v w ≤ x =ᴮ v :=
begin
  unfold pair has_insert.insert, rw[bv_eq_unfold], apply bv_specialize_left none, apply bv_specialize_right (some none),
  unfold singleton, simp, simp only with dnf, repeat{apply bv_or_elim},
  {apply inf_le_right_of_le, apply le_trans, apply eq_inserted_of_eq_singleton', rw[bv_eq_symm]},
  {apply inf_le_left_of_le, rw[mem_unfold], apply bv_Or_elim, intro i, cases i,
   apply inf_le_right_of_le, simp, rw[bv_eq_symm], apply le_trans, apply eq_inserted_of_eq_singleton', rw[bv_eq_symm],
   repeat{cases i}},
  {apply inf_le_right_of_le, apply le_trans, fapply eq_of_mem_singleton, from {x}, from {v},
   refl, apply eq_of_eq_singleton, refl},
  {apply inf_le_right_of_le, apply le_trans, fapply eq_of_mem_singleton, from {x}, from {v},
   refl, apply eq_of_eq_singleton, refl}
end

lemma eq_of_eq_pair_left' {x y v w : bSet 𝔹} {Γ} : Γ ≤ pair x y =ᴮ pair v w → Γ ≤ x =ᴮ v :=
poset_yoneda_inv Γ eq_of_eq_pair_left

theorem eq_of_eq_pair_right {x y v w: bSet 𝔹} : pair x y =ᴮ pair v w ≤ y =ᴮ w :=
begin
  apply bv_have, apply eq_of_eq_pair_left,
  apply le_trans, show 𝔹, from pair v y =ᴮ pair v w,
  rw[inf_comm], apply le_trans, apply inf_le_inf, swap, refl,
  apply subst_congr_pair_left, exact y, rw[bv_eq_symm],
  apply bv_eq_trans, apply eq_of_eq_pair'_right
end

lemma eq_of_eq_pair_right' {x y v w : bSet 𝔹} {Γ} : Γ ≤ pair x y =ᴮ pair v w → Γ ≤ y =ᴮ w :=
poset_yoneda_inv Γ eq_of_eq_pair_right

@[reducible]def prod (v w : bSet 𝔹) : bSet 𝔹 := ⟨v.type × w.type, λ a, pair (v.func a.1) (w.func a.2), λ a, (v.bval a.1) ⊓ (w.bval a.2)⟩

@[simp, cleanup]lemma prod_type {v w : bSet 𝔹} : (prod v w).type = (v.type × w.type) := by refl

@[simp, cleanup]lemma prod_bval {v w : bSet 𝔹} {a b} : (prod v w).bval (a,b) = v.bval a ⊓ w.bval b := by refl

@[simp, cleanup]lemma prod_type_forall {v w : bSet 𝔹} {ϕ : (prod v w).type → 𝔹} :
  (⨅(z:(prod v w).type), ϕ z) = ⨅(z : v.type × w.type), ϕ z :=
by refl

lemma prod_mem_old {v w x y : bSet 𝔹} : x ∈ᴮ v ⊓ y ∈ᴮ w ≤ pair x y ∈ᴮ prod v w :=
begin
  simp[pair, prod], simp only[mem_unfold], apply bv_cases_left, intro i,
  apply bv_cases_right, intro j, apply bv_use (i,j), tidy,
    {rw[inf_assoc], apply inf_le_left},
    {rw[inf_comm], simp [inf_assoc]},
    {let a := _, let b := _, change (bval v i ⊓ a) ⊓ (bval w j ⊓ b) ≤ _,
     have : a ⊓ b ≤ {{x}, {x, y}} =ᴮ {{func v i}, {x,y}}, by simp*,
     have : a ⊓ b ≤ {{func v i}, {x,y}} =ᴮ {{func v i}, {func v i, func w j}},
       by {apply subst_congr_insert1_left'', have this₁ : a ⊓ b ≤ {x,y} =ᴮ {func v i, y}, by simp*,
       have this₂ : a ⊓ b ≤ {func v i, y} =ᴮ {func v i, func w j}, by simp*,
       from bv_context_trans ‹_› ‹_›},

     apply le_trans, show 𝔹, from a ⊓ b,
       by {ac_change' (bval v i ⊓ bval w j) ⊓ (a ⊓ b) ≤ a ⊓ b, from inf_le_right},
     from bv_context_trans ‹_› ‹_›}
end

lemma prod_mem {v w x y : bSet 𝔹} {Γ} : Γ ≤ x ∈ᴮ v → Γ ≤ y ∈ᴮ w → Γ ≤ pair x y ∈ᴮ prod v w :=
λ H₁ H₂, by {transitivity x ∈ᴮ v ⊓ y ∈ᴮ w, bv_split_goal, from prod_mem_old}

lemma mem_left_of_prod_mem {v w x y : bSet 𝔹} {Γ : 𝔹} : Γ ≤ pair x y ∈ᴮ prod v w → Γ ≤ x ∈ᴮ v :=
begin
  intro H_pair_mem, rw[mem_unfold] at H_pair_mem, bv_cases_at H_pair_mem p, cases p with i j,
  dsimp at *, bv_split, rw[mem_unfold], apply bv_use i,
  replace H_pair_mem_1_right := eq_of_eq_pair_left' H_pair_mem_1_right,
  simp only [le_inf_iff] at *, simp*
end

lemma mem_right_of_prod_mem {v w x y : bSet 𝔹} {Γ : 𝔹} : Γ ≤ pair x y ∈ᴮ prod v w → Γ ≤ y ∈ᴮ w :=
begin
  intro H_pair_mem, rw[mem_unfold] at H_pair_mem, bv_cases_at H_pair_mem p, cases p with i j,
  dsimp at *, bv_split, rw[mem_unfold], apply bv_use j,
  replace H_pair_mem_1_right := eq_of_eq_pair_right' H_pair_mem_1_right,
  simp only [le_inf_iff] at *, simp*
end

lemma mem_prod_iff {v w x y : bSet 𝔹} {Γ} : Γ ≤ pair x y ∈ᴮ prod v w ↔ (Γ ≤ x ∈ᴮ v ∧ Γ ≤ y ∈ᴮ w) :=
⟨λ _, ⟨mem_left_of_prod_mem ‹_›, mem_right_of_prod_mem ‹_›⟩, λ ⟨_,_⟩, prod_mem ‹_› ‹_›⟩



-- /-- f is =ᴮ-extensional on x if for every w₁ and w₂ ∈ x, if w₁ =ᴮ w₂, then for every v₁ and v₂, if (w₁,v₁) ∈ f and (w₂,v₂) ∈ f, then v₁ =ᴮ v₂ -/
-- @[reducible]def is_extensional (x f : bSet 𝔹) : 𝔹 :=
-- ⨅w₁, w₁ ∈ᴮ x ⟹ (⨅w₂, w₂ ∈ᴮ x ⟹ (w₁ =ᴮ w₂ ⟹ ⨅v₁ v₂, (pair w₁ v₁ ∈ᴮ f ⊓ pair w₂ v₂ ∈ᴮ f) ⟹ v₁ =ᴮ v₂))

/-- f is =ᴮ-extensional if for every w₁ w₂ v₁ v₂, if pair (w₁ v₁) and pair (w₂ v₂) ∈ f and
    w₁ =ᴮ w₂, then v₁ =ᴮ v₂ -/
@[reducible]def is_func (f : bSet 𝔹) : 𝔹 :=
  ⨅ w₁, ⨅w₂, ⨅v₁, ⨅ v₂, pair w₁ v₁ ∈ᴮ f ⊓ pair w₂ v₂ ∈ᴮ f ⟹ (w₁ =ᴮ w₂ ⟹ v₁ =ᴮ v₂)

/-- f is a functional relation if for every z ∈ x, if there exists a w ∈ y such that (z,w) ∈ f, then for every w' ∈ y such that (z,w') ∈ f, w' =ᴮ w -/
-- @[reducible] def is_functional (x y f : bSet 𝔹) : 𝔹 :=
-- ⨅z, (z∈ᴮ x ⟹ (⨆w, w ∈ᴮ y ⊓ pair z w ∈ᴮ f ⊓ (⨅w', w' ∈ᴮ y ⟹ (pair z w' ∈ᴮ f ⟹ w =ᴮ w'))))

@[reducible]def is_functional (f : bSet 𝔹) : 𝔹 :=
⨅z, (⨆w, pair z w ∈ᴮ f) ⟹ (⨆w', ⨅w'', pair z w'' ∈ᴮ f ⟹ w' =ᴮ w'')

lemma is_functional_of_is_func (f : bSet 𝔹) {Γ} (H : Γ ≤ is_func f) : Γ ≤ is_functional f :=
begin
  unfold is_functional, unfold is_func at H,
  bv_intro z, bv_imp_intro w_spec,
  bv_cases_at w_spec w, clear w_spec,
  replace H := H z z, apply bv_use w,
  bv_intro w', bv_imp_intro Hw',
  from H w w' (le_inf ‹_› ‹_›) (bv_eq_refl')
end

/-- f is a function from x to y if for every element of x, there exists an element of y such that the pair is in f, and f is a function -/
@[reducible]def is_func' (x y f : bSet 𝔹) : 𝔹 :=
  is_func f ⊓ (⨅w₁, w₁ ∈ᴮ x ⟹ ⨆w₂, w₂ ∈ᴮ y ⊓ pair w₁ w₂ ∈ᴮ f)

/-- f is an injective function on x if it is a function and for every w₁ and w₂ ∈ x, if there exist v₁ and v₂ such that (w₁, v₁) ∈ f and (w₂, v₂) ∈ f,
  then v₁ = v₂ implies  w₁ = w₂ -/
-- def is_inj_func (x y) (f : bSet 𝔹) : 𝔹 :=
--   is_func x y f ⊓ (⨅w₁ w₂, w₁ ∈ᴮ x ⊓ w₂ ∈ᴮ x ⟹
--     (⨆v₁ v₂, (pair w₁ v₁ ∈ᴮ f ⊓ pair w₂ v₂ ∈ᴮ f ⊓ v₁ =ᴮ v₂ ⟹ w₁ =ᴮ w₂)))

@[reducible]def is_inj (f : bSet 𝔹) : 𝔹 :=
  ⨅w₁, ⨅ w₂, ⨅v₁, ⨅ v₂, (pair w₁ v₁ ∈ᴮ f ⊓ pair w₂ v₂ ∈ᴮ f ⊓ v₁ =ᴮ v₂) ⟹ w₁ =ᴮ w₂

lemma funext (f x y z : bSet 𝔹) {Γ : 𝔹} (H_func : Γ ≤ is_func f) (H : Γ ≤ (pair x y) ∈ᴮ f)
  (H' : Γ ≤ (pair x z) ∈ᴮ f) : Γ ≤ y =ᴮ z :=
H_func x x y z (le_inf ‹_› ‹_›) (bv_eq_refl')

def function.mk {u : bSet 𝔹} (F : u.type → bSet 𝔹) (h_congr : ∀ i j, u.func i =ᴮ u.func j ≤ F i =ᴮ F j) : bSet 𝔹 :=
⟨u.type, λ a, pair (u.func a) (F a), u.bval⟩

@[simp, cleanup]lemma function.mk_type {u : bSet 𝔹} {F : u.type → bSet 𝔹} {h_congr : ∀ i j, u.func i =ᴮ u.func j ≤ F i =ᴮ F j} : (function.mk F h_congr).type = u.type := by refl

@[simp, cleanup]lemma function.mk_func {u : bSet 𝔹} {F : u.type → bSet 𝔹} {h_congr : ∀ i j, u.func i =ᴮ u.func j ≤ F i =ᴮ F j} {i} : (function.mk F h_congr).func i = pair(u.func i) (F i) := by refl

@[simp, cleanup]lemma function.mk_bval {u : bSet 𝔹} {F : u.type → bSet 𝔹} {h_congr : ∀ i j, u.func i =ᴮ u.func j ≤ F i =ᴮ F j} {i} : (function.mk F h_congr).bval i = u.bval i := by refl

@[simp]lemma function.mk_self {u : bSet 𝔹} {F : u.type → bSet 𝔹} {h_congr : ∀ i j, u.func i =ᴮ u.func j ≤ F i =ᴮ F j} {i : u.type} : u.bval i ≤ pair (u.func i) (F i) ∈ᴮ function.mk F h_congr :=
by {rw[mem_unfold], apply bv_use i, simp}

@[simp]lemma function.mk_self' {u : bSet 𝔹} {F : u.type → bSet 𝔹} {h_congr : ∀ i j, u.func i =ᴮ u.func j ≤ F i =ᴮ F j}  {i : u.type} : ⊤ ≤ u.bval i ⟹ pair (u.func i) (F i) ∈ᴮ function.mk F h_congr :=
by simp

/-- This is analogous to the check operation: we collect a type-indexed collection of bSets into a definite bSet -/
def check' {α : Type u} (A : α → bSet 𝔹) : bSet 𝔹 := ⟨α, A, λ x, ⊤⟩

@[simp, cleanup]def check'_type {α : Type u} {A : α → bSet 𝔹} : (check' A).type = α := by refl
@[simp, cleanup]def check'_bval {α : Type u} {A : α → bSet 𝔹} {i} : (check' A).bval i = ⊤ := by refl
@[simp, cleanup]def check'_func {α : Type u} {A : α → bSet 𝔹} {i} : (check' A).func i = A i := by refl

lemma mk_is_func {u : bSet 𝔹} (F : u.type → bSet 𝔹) (h_congr : ∀ i j, u.func i =ᴮ u.func j ≤ F i =ᴮ F j) : ⊤ ≤ is_func (function.mk F h_congr) :=
begin
  bv_intro w₁, bv_intro w₂, bv_intro v₁, bv_intro v₂,
  apply bv_imp_intro, apply bv_imp_intro, tidy_context,
  bv_cases_at a_left_right_left i,
  bv_cases_at a_left_right_right j,
  clear a_left_right_left a_left_right_right a_left_left,
  bv_split_at a_left_right_left_1, bv_split_at a_left_right_right_1,
  bv_mp a_left_right_left_1_1_1 eq_of_eq_pair_left,
  bv_mp a_left_right_left_1_1_1 eq_of_eq_pair_right,
  bv_mp a_left_right_right_1_1_1 eq_of_eq_pair_left,
  bv_mp a_left_right_right_1_1_1 eq_of_eq_pair_right,
  change Γ_2 ≤ (λ z, z =ᴮ v₂) _, apply bv_rw' a_left_right_left_1_1_1_2,
  simp, change _ ≤ (λ z, (F i) =ᴮ z) _, apply bv_rw' a_left_right_right_1_1_1_2,
  simp, apply le_trans, swap, apply h_congr,
  apply bv_context_trans, rw[bv_eq_symm], from ‹_›,
  apply bv_context_trans, from ‹_›, from ‹_›
end

-- lemma mk_is_func {u : bSet 𝔹} (F : u.type → bSet 𝔹) (h_congr : ∀ i j, u.func i =ᴮ u.func j ≤ F i =ᴮ F j) : ⊤ ≤ is_func u (check' F) (function.mk F h_congr) :=
-- begin
-- repeat{apply le_inf},
--   {bv_intro i, apply bv_imp_intro, have := @prod_mem 𝔹 _ u (check' F) (func u i) (F i),
--   apply le_trans _ this, apply le_inf, simp[mem.mk'], apply bv_use i, simp},

--   {bv_intro x, apply bv_imp_intro, bv_intro y, repeat{apply bv_imp_intro},
--    bv_intro v₁, bv_intro v₂, apply bv_imp_intro,
--    /- `tidy_context` says -/ apply poset_yoneda, intros Γ a, simp only [le_inf_iff] at a, cases a, cases a_right, cases a_left, cases a_left_left, cases a_left_left_left,
--    rw[mem_unfold] at a_right_left a_right_right,
--    bv_cases_at a_right_right i, specialize_context Γ,
--    bv_cases_at a_right_left j, specialize_context Γ_1,
--    clear a_right_right a_right_left,
--    bv_split_at a_right_left_1, bv_split_at a_right_right_1,
--    simp only with cleanup at a_right_left_1_1_1 a_right_right_1_1_1,
--    bv_mp a_right_right_1_1_1 (eq_of_eq_pair_left),
--    bv_mp a_right_right_1_1_1 (eq_of_eq_pair_right), -- TODO(jesse) generate sane variable names
--    bv_mp a_right_left_1_1_1 (eq_of_eq_pair_left),
--    bv_mp a_right_left_1_1_1 (eq_of_eq_pair_right),
--    have : Γ_2 ≤ func u i =ᴮ func u j, apply bv_context_trans, rw[bv_eq_symm],
--    assumption, rw[bv_eq_symm], apply bv_context_trans, rw[bv_eq_symm],
--    assumption, assumption, -- TODO(jesse) write a cc-like tactic to automate this
--    suffices : Γ_2 ≤ F i =ᴮ F j,
--     by {apply bv_context_trans, assumption, rw[bv_eq_symm], apply bv_context_trans,
--        assumption, from this},
--    apply le_trans this, apply h_congr}, -- the tactics are a success!
--   {bv_intro z, rw[<-deduction], rw[top_inf_eq], rw[mem_unfold], apply bv_Or_elim,
--    intro i_z, apply bv_use (F i_z), repeat{apply le_inf},
--      {tidy_context, rw[mem_unfold], apply bv_use i_z, apply le_inf, apply le_top, simp},
--      tidy_context, bv_mp a_right (subst_congr_pair_left), show bSet 𝔹, from (F i_z),
--      change Γ ≤ (λ w, w ∈ᴮ function.mk F h_congr) (pair z (F i_z)),
--      apply bv_rw' a_right_1, apply B_ext_mem_left, apply bv_use i_z, apply le_inf ‹_›,
--      simp[bv_eq_refl],
--      bv_intro w', repeat{apply bv_imp_intro}, tidy_context,
--      rw[mem_unfold] at a_left_right, bv_cases_at a_left_right i_w',
--      specialize_context Γ, bv_split_at a_left_right_1,
--      change _ ≤ (λv, (F i_z) =ᴮ v) w', apply bv_rw' a_left_right_1_1_1,
--      {simp[B_ext], intros x y, rw[inf_comm], apply bv_eq_trans},
--      change Γ_1 ≤ F i_z =ᴮ F i_w', simp only with cleanup at *,
--      bv_cases_at a_right i_pair, specialize_context Γ_1, bv_split_at a_right_1,
--      bv_mp a_right_1_1_1 (eq_of_eq_pair_left), bv_mp a_right_1_1_1 (eq_of_eq_pair_right),
--      bv_split_at a_left_right_1, clear a_right_1_1 a_right_1 a_left_right_1_1 a_left_right_1_2 a_right_1_1_1,
--      clear a_left_right_1 a_left_right a_left_left_left a_right,
--      have : Γ_2 ≤ F i_z =ᴮ F i_pair,
--        by {apply le_trans _ (h_congr _ _), apply bv_context_trans, rw[bv_eq_symm], from ‹_›, from ‹_›},
--      apply bv_context_trans, exact this, apply bv_context_trans, rw[bv_eq_symm], from ‹_›, from ‹_›}
-- end

lemma mk_inj_of_inj {u : bSet 𝔹} {F : u.type → bSet 𝔹} (h_inj : ∀ i j, i ≠ j → F i =ᴮ F j ≤ ⊥) (h_congr : ∀ i j, u.func i =ᴮ u.func j ≤ F i =ᴮ F j) :
  ⊤ ≤ is_inj (function.mk F h_congr) :=
begin
  bv_intro w₁, bv_intro w₂, bv_intro v₁, bv_intro v₂, apply bv_imp_intro,
  rw[top_inf_eq], rw[mem_unfold, mem_unfold], rw[deduction],
  apply bv_cases_left, intro i, apply bv_cases_right, intro j, apply bv_imp_intro,
  simp,
  tidy_context,
    haveI : decidable (i = j) := classical.prop_decidable _,
    by_cases i = j,
      {subst h, have : Γ ≤ pair w₁ v₁ =ᴮ pair w₂ v₂, by apply bv_context_trans; {tidy},
       bv_mp this eq_of_eq_pair_left, from ‹_›},
    have := h_inj i j h, by_cases Γ = ⊥, rw[h], apply bot_le,
    suffices : Γ = ⊥, by contradiction,
    apply bot_unique,
    suffices : Γ ≤ F i =ᴮ F j, by {apply le_trans this ‹_›},
    bv_mp a_left_left_right eq_of_eq_pair_right,
    bv_mp a_left_right_right eq_of_eq_pair_right,
    from bv_context_trans (bv_context_symm ‹_›) (bv_context_trans a_right ‹_›)
end

-- lemma mk_inj_of_inj {u : bSet 𝔹} {F : u.type → bSet 𝔹} (h_inj : ∀ i j, i ≠ j → F i =ᴮ F j ≤ ⊥) (h_congr : ∀ i j, u.func i =ᴮ u.func j ≤ F i =ᴮ F j) :
--   ⊤ ≤ is_inj_func u (check' F) (function.mk F h_congr) :=
-- begin
--   apply le_inf, apply mk_is_func,
--   bv_intro w₁, bv_intro w₂, apply bv_imp_intro, rw[top_inf_eq],
--   rw[mem_unfold, mem_unfold], apply bv_cases_left, intro i,
--   apply bv_cases_right, intro j, apply le_supr_of_le (F i),
--   apply le_supr_of_le (F j), apply bv_imp_intro,
--   tidy_context,
--     haveI : decidable (i = j) := by apply classical.prop_decidable,
--     by_cases i = j,
--       { subst h, apply bv_context_trans, tidy},
--     have := h_inj i j h,
--     by_cases Γ = ⊥, rw[h], apply bot_le,
--     suffices : Γ = ⊥, by contradiction,
--     apply bot_unique, from le_trans ‹_› this
-- end

lemma bot_of_mem_self {x : bSet 𝔹} : ⊤ ≤ (x ∈ᴮ x ⟹ ⊥) :=
begin
  induction x, simp[-imp_bot], intro i, specialize x_ih i,
  apply bot_unique, apply bv_have_true x_ih, tidy_context,
  bv_mp a_left_left (show x_B i ≤ x_A i ∈ᴮ mk x_α x_A x_B, by apply mem.mk),
  change Γ ≤ (x_A i ∈ᴮ mk x_α x_A x_B) at a_left_left_1,
  have : Γ ≤ x_A i ∈ᴮ x_A i, rw[show Γ = Γ ⊓ Γ, by simp],
  apply le_trans, apply inf_le_inf, exact a_left_right, exact a_left_left_1,
  apply subst_congr_mem_right,
  have x_ih2 : Γ ≤ _ := le_trans (le_top) x_ih,
  exact context_imp_elim x_ih2 ‹_›
end

lemma bot_of_mem_self' {x : bSet 𝔹} {Γ} (H : Γ ≤ (x ∈ᴮ x)) : Γ ≤ ⊥ :=
begin
  have := @bot_of_mem_self 𝔹 _ x, rw[<-deduction, top_inf_eq] at this,
  from le_trans H this
end

-- lemma bot_of_mem_mem_aux {x : bSet 𝔹} {i : x.type} : ⊤ ≤ ( x ∈ᴮ x.func i ⟹ ⊥) :=
-- begin
--   induction x, apply bv_imp_intro, rw[top_inf_eq], rw[mem_unfold],
--   apply bv_Or_elim, intro j,
--   specialize x_ih i, swap, exact j, tidy_context,
--   bv_mp a_left (show bval (func (mk x_α x_A x_B) i) j ≤ (func (func (mk _ _ _) i) j) ∈ᴮ func (mk _ _ _) i, by apply mem.mk'),
-- end

lemma bot_of_mem_mem (x y : bSet 𝔹) : ⊤ ≤ ((x ∈ᴮ y ⊓ y ∈ᴮ x) ⟹ ⊥) :=
begin
  induction x generalizing y, induction y,
  simp[-imp_bot, -top_le_iff], apply bv_imp_intro, rw[top_inf_eq],
  apply bv_cases_right, intro a', apply bv_cases_left, intro a'',
  specialize x_ih a', tidy_context,
  specialize y_ih a'',
  bv_mp a_right_left (show x_B a' ≤ _ ∈ᴮ (mk x_α x_A x_B), by apply mem.mk),
  change Γ ≤ _ ∈ᴮ (mk x_α x_A x_B) at a_right_left_1,
  bv_mp a_left_left (show y_B a'' ≤ _ ∈ᴮ (mk y_α y_A y_B), by apply mem.mk),
  change Γ ≤ _ ∈ᴮ (mk y_α y_A y_B) at a_left_left_1,
  have this₁ : Γ ≤ x_A a' ∈ᴮ y_A a'', apply le_trans' a_right_left_1,
  apply le_trans, apply inf_le_inf, from a_left_right, refl,
  apply subst_congr_mem_right,
  have this₂ : Γ ≤ y_A a'' ∈ᴮ x_A a', apply le_trans' a_left_left_1,
  apply le_trans, apply inf_le_inf, from a_right_right, refl,
  apply subst_congr_mem_right,
  specialize x_ih (y_A a''), specialize_context_at x_ih Γ,
  bv_to_pi x_ih, apply x_ih, bv_split_goal
end

end extras

section check

lemma check_mem {x y : pSet} {Γ} (h_mem : x ∈ y) : (Γ : 𝔹) ≤ x̌ ∈ᴮ y̌ :=
begin
  rw[mem_unfold], cases y, unfold has_mem.mem pSet.mem at h_mem,
  cases h_mem with w_y H_w_y, apply bv_use w_y,
  apply le_inf, simp, from check_bv_eq ‹_›
end

lemma check_subset_of_subset {x y : pSet} (h_subset : x ⊆ y) : (⊤ : 𝔹) ≤ x̌ ⊆ᴮ y̌ :=
begin
  rw[subset_unfold], cases x, cases y, unfold has_subset.subset pSet.subset at h_subset,
  bv_intro x_j, apply bv_imp_intro, rw[top_inf_eq], apply le_trans, apply mem.mk',
  simp[-top_le_iff], specialize h_subset x_j, cases h_subset with b H_b,
  apply bv_use b, from check_bv_eq ‹_›
end

lemma check_subset {x y : pSet} {Γ : 𝔹} (h_subset : x ⊆ y) : Γ ≤ x̌ ⊆ᴮ y̌ :=
  le_trans le_top (check_subset_of_subset ‹_›)

lemma check_powerset_subset_powerset (x : pSet) {Γ : 𝔹} : Γ ≤ (pSet.powerset x)̌  ⊆ᴮ (bv_powerset (x̌))
:=
begin
  rw[subset_unfold], bv_intro s, simp only [mem, bval, top_imp, func, check, check_bval_top],
  suffices : ∃ χ : (x̌).type → 𝔹, Γ ≤ ((pSet.powerset x)̌ .func s) =ᴮ (set_of_indicator χ),
    by {cases this with χ Hχ, rw[mem_unfold], apply bv_use χ, refine le_inf _ ‹_›,
        { change _ ≤ _ ⊆ᴮ _, have := bv_rw' (bv_context_symm Hχ), show bSet 𝔹 → 𝔹,
          from λ z, z ⊆ᴮ x̌, from this, by simp,
          have eq_check_type : type ((p𝒫 x)̌ ) = pSet.type (p𝒫 x) :=
            by {simp, recover, all_goals{from ‹_›} },
          suffices this : (p𝒫 x).func (cast eq_check_type s) ⊆ x,
            by {convert check_subset this, cases x, refl},
          from pSet.mem_powerset.mp (by convert pSet.mem.mk (p𝒫 x).func _; from pSet.mk_eq)}},
   cases x with α A,
     use (λ i, Prop_to_bot_top (s i)), 
   refine subset_ext _ _,
     { rw[subset_unfold], bv_intro j, bv_imp_intro Hj, simp,
       apply bv_use j.val,
       refine le_inf _ _,
         { sorry }, -- show in this case it's always ⊤
         { sorry }}, -- this should be easy
     { rw[subset_unfold], bv_intro j, bv_imp_intro Hj, simp,
       sorry  } -- for this, case on whether or not the bval is ⊥ 
end

@[simp]lemma check_mem' {y : pSet} {i : y.type} : ((y.func i)̌ ) ∈ᴮ y̌ = (⊤ : 𝔹) :=
by {apply top_unique, apply check_mem, cases y, apply pSet.mem.mk}

lemma of_nat_inj {n k : ℕ} (H_neq : n ≠ k) : ((of_nat n : bSet 𝔹) =ᴮ of_nat k) = ⊥ :=
check_bv_eq_bot_of_not_equiv (pSet.of_nat_inj ‹_›)

end check

section ordinals
def epsilon_well_orders (x : bSet 𝔹) : 𝔹 :=
(⨅y, y∈ᴮ x ⟹ (⨅z, z ∈ᴮ x ⟹ (y =ᴮ z ⊔ y ∈ᴮ z ⊔ z ∈ᴮ y))) ⊓
  (⨅u, u ⊆ᴮ x ⟹ (- (u =ᴮ ∅) ⟹ ⨆y, y∈ᴮ u ⊓ (⨅z', z' ∈ᴮ u ⟹ (- (z' ∈ᴮ y)))))

lemma epsilon_dichotomy (x y z : bSet 𝔹) : epsilon_well_orders x ≤ y ∈ᴮ x ⟹ (z ∈ᴮ x ⟹ (y =ᴮ z ⊔ y ∈ᴮ z ⊔ z ∈ᴮ y)) :=
begin
  unfold epsilon_well_orders, apply bv_imp_intro, tidy_context,
  bv_to_pi', specialize a_left_left y, dsimp at a_left_left,
  bv_to_pi', specialize a_left_left ‹_›, bv_to_pi', exact a_left_left z
end

def is_transitive (x : bSet 𝔹) : 𝔹 := ⨅y, y∈ᴮ x ⟹ y ⊆ᴮ x

lemma subset_of_mem_transitive {x w : bSet 𝔹} {Γ : 𝔹} (H₁ : Γ ≤ is_transitive x) (H₂ : Γ ≤ w ∈ᴮ x) : Γ ≤ w ⊆ᴮ x :=
by {bv_specialize_at H₁ w, bv_to_pi H₁_1, solve_by_elim}

@[simp] lemma B_ext_is_transitive : B_ext (is_transitive : bSet 𝔹 → 𝔹) :=
by {intros x y, unfold is_transitive, revert x y, change B_ext _, simp}

def Ord (x : bSet 𝔹) : 𝔹 := epsilon_well_orders x ⊓ is_transitive x

@[reducible]def is_surj (x y : bSet 𝔹) (f : bSet 𝔹) : 𝔹 :=
⨅v, v ∈ᴮ y ⟹ (⨆w, w ∈ᴮ x ⊓ pair w v ∈ᴮ f)

/-- x is larger than y if there exists a function f such that for every v ∈ y, there exists a w ∈ x such that (w,v) ∈ f -/
def larger_than (x y : bSet 𝔹) : 𝔹 := ⨆f, (is_func f) ⊓ (is_surj x y f)

def injects_into (x y : bSet 𝔹) : 𝔹 := ⨆f, (is_func' x y f) ⊓ is_inj f

@[simp]lemma B_ext_larger_than_right {y : bSet 𝔹} : B_ext (λ z, larger_than y z) :=
by simp[larger_than]

@[simp]lemma B_ext_larger_than_left {y : bSet 𝔹} : B_ext (λ z, larger_than z y) :=
by simp[larger_than]

@[simp]lemma B_ext_injects_into_left {y : bSet 𝔹} : B_ext (λ z, injects_into z y) :=
by simp[injects_into]

@[simp]lemma B_ext_injects_into_right {y : bSet 𝔹} : B_ext (λ z, injects_into y z) :=
by simp[injects_into]

local infix `≺`:70 := (λ x y, -(larger_than x y))

local infix `≼`:70 := (λ x y, injects_into x y)

def CH {𝔹} [nontrivial_complete_boolean_algebra 𝔹] : 𝔹 := - ⨆ x, ⨆y, (omega ≺ x) ⊓ (x ≺ y) ⊓ (y ≼ 𝒫(omega))

lemma bSet_lt_of_lt_of_le (x y z : bSet 𝔹) {Γ} (H₁ : Γ ≤ x ≺ y) (H₂ : Γ ≤ y ≼ z) : Γ ≤ x ≺ z :=
begin
  dsimp only [larger_than, injects_into] at ⊢ H₁ H₂,
  rw[<-imp_bot] at ⊢ H₁,
  bv_imp_intro, sorry
end

lemma bSet_lt_of_le_of_lt (x y z : bSet 𝔹) {Γ} (H₁ : Γ ≤ x ≼ y) (H₂ : Γ ≤ y ≺ z) : Γ ≤ x ≺ z :=
begin
  sorry
end

lemma bSet_le_of_subset {x y : bSet 𝔹} {Γ} (H : Γ ≤ x ⊆ᴮ y) : Γ ≤ x ≼ y :=
begin
  sorry
end

def Card (y : bSet 𝔹) : 𝔹 := Ord(y) ⊓ ⨅x, x ∈ᴮ y ⟹ (- larger_than y x)

lemma is_transitive_of_mem_Ord (y x : bSet 𝔹) : Ord x ⊓ y ∈ᴮ x ≤ (is_transitive y) :=
begin
  apply bSet.rec_on' y, clear y, intros y y_ih,

  bv_intro w, apply bv_imp_intro, rw[subset_unfold'], bv_intro z, apply bv_imp_intro, unfold Ord, tidy_context,
  bv_specialize_at a_left_left_left_right y, bv_imp_elim_at a_left_left_left_right_1 ‹_›,
  rw[subset_unfold'] at H, bv_specialize_at H w, bv_imp_elim_at H_1 ‹_›, bv_specialize_at a_left_left_left_right w,
  bv_imp_elim_at a_left_left_left_right_2 ‹_›, rw[subset_unfold'] at H_3,
  bv_specialize_at H_3 z, bv_imp_elim_at H_3_1 ‹_›, bv_mp a_left_left_left_left (epsilon_dichotomy x y z),
  bv_imp_elim_at a_left_left_left_left_1 ‹_›, bv_imp_elim_at H_5 ‹_›, bv_or_elim_at H_6, swap, assumption,
  bv_or_elim_at H_left,
  bv_exfalso, suffices : Γ_2 ≤ y ∈ᴮ w ⊓ w ∈ᴮ y,
    have : Γ_2 ≤ _ := le_trans (le_top) (bot_of_mem_mem y w),
    bv_imp_elim_at this ‹_›, assumption,
  apply le_inf, swap, assumption, apply bv_rw' H_left_1, simp,
  assumption,

  bv_exfalso,
  have a_left_right_old := a_left_right,
  rw[mem_unfold] at a_left_right, bv_cases_at a_left_right i_w, bv_split_at a_left_right_1,
  specialize y_ih i_w, rw[deduction] at y_ih,
  have := le_trans (le_inf ‹_› ‹_› : Γ_3 ≤ Ord x) ‹_›,
  have this' : Γ_3 ≤ func y i_w ∈ᴮ x,  rw[bv_eq_symm] at a_left_right_1_1_1,
  change Γ_3 ≤ (λ z, z ∈ᴮ x) (func y i_w), apply bv_rw' a_left_right_1_1_1,
  simp, from H_2, bv_imp_elim_at this ‹_›,
  have : Γ_3 ≤ is_transitive w, apply bv_rw' ‹_›, simp, from ‹_›,
  unfold is_transitive at this, have H_8 := this z ‹_›,
  rw[subset_unfold'] at H_8, bv_specialize_at H_8 y,
  bv_imp_elim_at H_8_1 ‹_›,
  suffices : Γ_3 ≤ y ∈ᴮ w ⊓ w ∈ᴮ y,
    have this3 := le_trans (@le_top _ _ Γ_3) (bot_of_mem_mem y w),
  bv_to_pi this3, apply this3, bv_split_goal
end

lemma is_ewo_of_mem_Ord (y x : bSet 𝔹) : Ord x ⊓ y ∈ᴮ x ≤ (epsilon_well_orders y) :=
begin
  bv_split_goal, rename i z, apply bv_imp_intro, bv_split_goal; rename i w, apply bv_imp_intro,

  all_goals{unfold Ord},
  {unfold epsilon_well_orders, tidy_context,
  bv_to_pi', specialize a_left_left_left_left_left w, dsimp at a_left_left_left_left_left,
  specialize a_left_left_left_right y,
    bv_to_pi a_left_left_left_right, specialize a_left_left_left_right ‹_›,
    rw[subset_unfold'] at a_left_left_left_right, bv_to_pi a_left_left_left_right,
    have H₁ := a_left_left_left_right w, bv_to_pi',
  have H₂ : Γ ≤ w ∈ᴮ x, from H₁ ‹_›,
  have H₃ : Γ ≤ z ∈ᴮ x,
    by {specialize a_left_left_left_right z, bv_to_pi', from a_left_left_left_right ‹_›},
  rename a_left_left_left_left_left H,
  replace H := H ‹_› z ‹_›,
  bv_or_elim_at H, bv_or_elim_at H_left,
  apply le_sup_left_of_le, apply le_sup_left_of_le, bv_split_goal,
  apply le_sup_right_of_le, assumption,
  apply le_sup_left_of_le, apply le_sup_right_of_le, assumption},

  {repeat{apply bv_imp_intro}, tidy_context,
  rename a_left_left_left_left H, rename i w,
  bv_split,
 have : Γ ≤ w ⊆ᴮ x,
   by {rw[subset_unfold'], bv_intro w', bv_imp_intro,
       have := mem_of_mem_subset a_left_right H,
       from mem_of_mem_subset (subset_of_mem_transitive ‹_› ‹_›) ‹_›},
 from H_right w ‹_› ‹_›}
end

theorem Ord_of_mem_Ord (y x : bSet 𝔹) : Ord x ⊓ y ∈ᴮ x ≤ Ord y :=
  le_inf (is_ewo_of_mem_Ord _ _) (is_transitive_of_mem_Ord _ _)

open ordinal
open cardinal

noncomputable def ordinal.mk : ordinal.{u} → bSet 𝔹 := λ η,
limit_rec_on η ∅ (λ ξ mk_ξ, succ mk_ξ)
begin
  intros ξ is_limit_ξ ih,
  have this' : ξ = @ordinal.type (ξ.out).α (ξ.out).r (ξ.out).wo,
    by {rw[<-quotient.out_eq ξ], convert type_def _,
        rw[quotient.out_eq], cases quotient.out ξ, refl},
    refine ⟨ξ.out.α, _, λ x, ⊤⟩,
    intro x, apply ih, rw this', apply typein_lt_type _ x
end

@[simp]lemma ordinal.mk_zero : ordinal.mk 0 = (∅ : bSet 𝔹) := by simp[ordinal.mk]

@[simp]lemma ordinal.mk_succ (ξ ξ_pred : ordinal) (h : ξ = ordinal.succ ξ_pred) : (ordinal.mk ξ : bSet 𝔹) = succ (ordinal.mk ξ_pred) :=
by {simp[h, ordinal.mk]}

@[simp]lemma ordinal.mk_limit (ξ : ordinal) (h : is_limit ξ) : (ordinal.mk ξ : bSet 𝔹) =
⟨ξ.out.α, λ x, ordinal.mk (@typein _ (ξ.out.r) (ξ.out.wo) x), (λ x, ⊤)⟩ :=
by simp[*, ordinal.mk]

def lift_nat_Well_order : Well_order.{u} :=
{ α := ulift ℕ,
  r := (λ x y, x.down < y.down),
  wo :=
by {haveI this : (is_well_order ℕ (λ x y, x < y)) := by apply_instance, from { trichotomous := by {change ∀ a b : ulift ℕ, a.down < b.down ∨ a = b ∨ b.down < a.down, intros a b, have := this.trichotomous, specialize this a.down b.down, tidy, left, from ‹_›,
      right, right, from ‹_›},
    irrefl := by {intro a, apply this.irrefl},
    trans := by {intros a b c, apply this.trans},
    wf := by {have := this.wf, split, cases this with H, intro a, specialize H a.down,
              induction a, induction a, split, intros y H', cases H', cases H,
              specialize H_h a_n (by {change a_n < a_n + 1, simp, exact dec_trivial}),
              specialize a_ih H_h,
              split, intros y H', by_cases y.down = a_n,
              subst h, split, intros y' H'', cases a_ih, exact a_ih_h y' H'',

              have h' : y.down < a_n,
                by {have := this.trichotomous, specialize this y.down a_n, simp[*, -this] at this, suffices this' : ¬ a_n < y.down, by {simp[*,-this] at this; assumption}, intro H,
             from nat.lt_irrefl _ (lt_of_lt_of_le H (nat.le_of_lt_succ H'))},

              cases a_ih, from a_ih_h y h'}}}}

lemma lift_nat_Well_order_iso_nat : lift_nat_Well_order.r ≃o (λ x y : ℕ, x < y) :=
{to_fun := ulift.down,
  inv_fun := ulift.up,
  left_inv := by tidy,
  right_inv := by tidy,
  ord := by tidy}

noncomputable lemma order_isomorphism_of_equiv {X Y : Well_order.{u}} (H : X ≈ Y) : X.r ≃o Y.r :=
begin
  apply classical.choice, cases X, cases Y, apply type_eq.mp, from (quotient.sound H)
end

lemma order_iso_trans {α β γ} {X : α → α → Prop} {Y : β → β → Prop} {Z : γ → γ → Prop} (H₁ : X ≃o Y) (H₂ : Y ≃o Z) : X ≃o Z :=
H₁.trans H₂

lemma order_iso_symm {α β} {X : α → α → Prop} {Y : β → β → Prop} (H : X ≃o Y) : Y ≃o X :=
H.symm

-- noncomputable lemma omega_out_iso_nat : ordinal.omega.out.r ≃o ((λ x y : ℕ, x < y)) :=
-- begin
--   have this₁ := order_isomorphism_of_equiv (@quotient.mk_out (Well_order) _ lift_nat_Well_order),
--   have this₂ := (lift_nat_Well_order_iso_nat),
--   apply order_iso_trans _ this₂, apply order_iso_trans _ this₁,

--   sorry
-- end

-- lemma mk_omega_eq_omega : ⊤ ≤ ordinal.mk ordinal.omega =ᴮ (bSet.omega : bSet 𝔹) :=
-- begin
--   rw[ordinal.mk_limit ordinal.omega omega_is_limit], apply le_inf, swap,

--   {simp[-top_le_iff], intro k, induction k, induction k, simp,
--    repeat{sorry}},
--   {sorry}
-- end

lemma check_is_transitive {x : pSet} (H : pSet.is_transitive x) {Γ} : Γ ≤ is_transitive (x̌ : bSet 𝔹) :=
begin
  bv_intro y, bv_imp_intro,
  unfold pSet.is_transitive at H, rw[mem_unfold] at H_1,
  cases x, dsimp at H_1, bv_cases_at H_1 i_y, bv_split,
  apply bv_rw' H_1_1_right, simp, specialize H (x_A i_y) (by apply pSet.mem.mk),
  apply check_subset ‹_›
end

lemma check_ewo_left {x : pSet} (H : pSet.epsilon_well_orders x) {Γ : 𝔹} : Γ ≤ (⨅y, y∈ᴮ x̌ ⟹
  (⨅z, z ∈ᴮ x̌ ⟹ (y =ᴮ z ⊔ y ∈ᴮ z ⊔ z ∈ᴮ y))) :=
begin
  bv_intro y, bv_imp_intro, bv_intro z, bv_imp_intro,
  rw[mem_unfold] at H_1 H_2, cases x, dsimp at H_1 H_2,
  bv_cases_at H_2 i_z, bv_cases_at H_1 i_y, bv_split,
  specialize H_left (x_A i_y) (by apply pSet.mem.mk) (x_A i_z) (by apply pSet.mem.mk),
  rename H_left this, repeat{cases this},
  apply le_sup_left_of_le, apply le_sup_left_of_le,
  apply bv_rw' H_2_1_right, simp, apply bv_rw' H_1_1_right, simp, from check_bv_eq ‹_›,

  apply le_sup_left_of_le, apply le_sup_right_of_le, apply bv_rw' H_2_1_right,
  simp, apply bv_rw' H_1_1_right, simp, from check_mem ‹_›,

  apply le_sup_right_of_le, apply bv_rw' H_2_1_right, simp, apply bv_rw' H_1_1_right, simp,
  from check_mem ‹_›
end

lemma check_ewo_right {x : pSet} (H : pSet.epsilon_well_orders x) {Γ : 𝔹} : Γ ≤ (⨅u, u ⊆ᴮ x̌ ⟹ (- (u =ᴮ ∅) ⟹ ⨆y, y∈ᴮ u ⊓ (⨅z', z' ∈ᴮ u ⟹ (- (z' ∈ᴮ y))))) :=
begin
  bv_intro u, bv_imp_intro, bv_imp_intro, cases H,
  rw[subset_unfold'] at H_1, apply bSet_axiom_of_regularity, from ‹_›
end

lemma check_ewo {x : pSet} (H : pSet.epsilon_well_orders x) {Γ} : Γ ≤ epsilon_well_orders (x̌ : bSet 𝔹) :=
le_inf (check_ewo_left ‹_›) (check_ewo_right ‹_›)

@[simp]lemma check_Ord {x : pSet} (H : pSet.Ord x) {Γ} : Γ ≤ Ord (x̌ : bSet 𝔹) :=
le_inf (check_ewo H.left) (check_is_transitive H.right)

@[simp]lemma Ord_card_ex (κ : cardinal) {Γ : 𝔹} : Γ ≤ Ord ((pSet.card_ex κ)̌ ) :=
by simp[pSet.card_ex]

def closed_under_successor (Γ) (x : bSet 𝔹) := Γ ≤ ⨅y, y ∈ᴮ x ⟹ succ y ∈ᴮ x

def omega_spec (ω : bSet 𝔹) := ∀ (x : bSet 𝔹) {Γ} (H₁ : Γ ≤ ∅ ∈ᴮ x) (H₂ : closed_under_successor Γ x), Γ ≤ bSet.omega ⊆ᴮ x

lemma check_succ_eq_succ_check {n : ℕ} : (of_nat (n.succ) : bSet 𝔹) = bSet.succ (of_nat n) :=
by simp[of_nat, succ, pSet.of_nat]

lemma omega_is_omega : omega_spec (bSet.omega : bSet 𝔹) :=
begin
  intros x Γ H₁ H₂, unfold closed_under_successor at H₂, rw[subset_unfold],
  simp, intro k, cases k, induction k, convert H₁,
  {change (∅̌) = _, simp},
  {let A := _, change Γ ≤ A ∈ᴮ x at k_ih,
   convert H₂ A ‹_›, from check_succ_eq_succ_check}
end

lemma of_nat_mem_of_lt {k₁ k₂ : ℕ} (H_lt : k₁ < k₂) {Γ} : Γ ≤ (bSet.of_nat k₁ : bSet 𝔹) ∈ᴮ (bSet.of_nat k₂) :=
check_mem $ pSet.of_nat_mem_of_lt H_lt

lemma Ord_omega {Γ : 𝔹} : Γ ≤ Ord(omega) :=
le_inf (check_ewo pSet.is_ewo_omega) (check_is_transitive pSet.is_transitive_omega)

/-- ℵ₁ is defined as: the least ordinal which is larger than ω -/
@[reducible]def aleph_one_Ord_spec (x : bSet 𝔹) : 𝔹 :=
  (Ord x) ⊓
  (larger_than x bSet.omega) ⊓
  (⨅y, (Ord(y) ⟹ (-larger_than bSet.omega y ⟹ x ⊆ᴮ y)))

/--
The universal property of ℵ₁ is that it injects into any set which is larger than ω
-/
@[reducible]def aleph_one_universal_property (x : bSet 𝔹) : 𝔹 := ⨅ z, (bSet.omega ≺ z) ⟹ (x ≼ z)

@[simp]lemma B_ext_aleph_one_universal_property : B_ext (aleph_one_universal_property : bSet 𝔹 → 𝔹) :=
begin
  intros x y, unfold aleph_one_universal_property, revert x y, change B_ext _, simp
end

lemma aleph_one_exists {Γ : 𝔹} : Γ ≤ ⨆x, aleph_one_Ord_spec x := sorry

def aleph_one : bSet 𝔹 := sorry

lemma aleph_one_check_sub_aleph_one {Γ : 𝔹} : Γ ≤ (pSet.card_ex (aleph 1))̌  ⊆ᴮ aleph_one := sorry

lemma aleph_one_satisfies_universal_property {Γ : 𝔹} : Γ ≤ aleph_one_universal_property (aleph_one) := sorry

lemma aleph_one_satisfies_Ord_spec {Γ : 𝔹} : Γ ≤ aleph_one_Ord_spec (aleph_one) := sorry


-- TODO(jesse) prove this using regularity
-- lemma aleph_one_exists {Γ} : Γ ≤ ⨆(x : bSet 𝔹), aleph_one_spec_internal x := sorry

-- maybe it would be better to define ℵ₁ as the union of all the ordinals which ω surjects onto?

-- TODO(jesse) prove this
-- lemma check_aleph_one_le_aleph_one {Γ : 𝔹} : Γ ≤ ⨅(x : bSet 𝔹), (aleph_one_spec_internal x ⟹ ((pSet.ordinal.mk (aleph 1).ord)̌  ⊆ᴮ  x)) := sorry

end ordinals

theorem bSet_zorns_lemma' {Γ : 𝔹} : Γ  ≤ ⨅(X : bSet 𝔹), -(X =ᴮ ∅) ⟹ ((⨅y, (y ⊆ᴮ X ⊓ (⨅(w₁ : bSet 𝔹), ⨅(w₂ : bSet 𝔹),
  w₁ ∈ᴮ y ⊓ w₂ ∈ᴮ y ⟹ (w₁ ⊆ᴮ w₂ ⊔ w₂ ⊆ᴮ w₁))) ⟹ (bv_union y ∈ᴮ X)) ⟹ (⨆c, c ∈ᴮ X ⊓ (⨅z, z ∈ᴮ X ⟹ (c ⊆ᴮ z ⟹ c =ᴮ z)))) :=
begin
  bv_intro X, rw[<-curry_uncurry],
  have := core_aux_lemma2 (λ x, (-(x =ᴮ ∅) ⊓
         ⨅ (y : bSet 𝔹),
           (y ⊆ᴮ x ⊓
                ⨅ (w₁ w₂ : bSet 𝔹),
                  w₁ ∈ᴮ y ⊓ w₂ ∈ᴮ y ⟹ (w₁ ⊆ᴮ w₂ ⊔ w₂ ⊆ᴮ w₁)) ⟹
             bv_union y ∈ᴮ x)) (λ x, ⨆ (c : bSet 𝔹), c ∈ᴮ x ⊓ ⨅ (z : bSet 𝔹), z ∈ᴮ x ⟹ (c ⊆ᴮ z ⟹ c =ᴮ z))
             (by change B_ext _; simp) (by change B_ext _; simp) _ _,

  rw[eq_top_iff] at this, replace this := (le_trans le_top this : Γ ≤ _),
    from this X,
    dsimp, intros u Hu, rw[eq_top_iff] at Hu ⊢, bv_split,
    apply bSet_zorns_lemma, from (top_unique ‹_›),
    from ‹_›, apply top_unique, dsimp, apply bv_use ({∅} : bSet 𝔹),
    simp, split,
      {apply top_unique, rw[<-imp_bot], bv_imp_intro,
        rw[bv_eq_unfold] at H, bv_split,
        replace H_left := H_left none,
        dsimp at H_left, replace H_left := H_left (le_top),
        from bot_of_mem_self' ‹_›},
    intros x, refine poset_yoneda _, intros Γ a,
    simp only [le_inf_iff] at *, cases a,
    apply mem_singleton_of_eq,
    refine subset_ext (by simp) _,
    rw[subset_unfold'], bv_intro w, bv_imp_intro,
    have := bv_union_spec' x, show 𝔹, from Γ_1,
    replace this := this w, bv_split,
    replace this_left := this_left ‹_›,
    bv_cases_at this_left w',
    rw[subset_unfold'] at a_left,
    bv_split, replace a_left := a_left w' ‹_›,
    have : Γ_2 ≤ ∅ =ᴮ w', by {apply eq_of_mem_singleton, from ‹_›},
    apply bv_exfalso, apply bot_of_mem_empty, show bSet 𝔹, from w,
    apply bv_rw' this, simpa
end

end bSet
