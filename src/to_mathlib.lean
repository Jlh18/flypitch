/- theorems which we should (maybe) backport to mathlib -/

import data.finset algebra.ordered_group tactic.squeeze tactic.tidy order.bounded_lattice
       topology.basic data.set.disjointed data.set.countable set_theory.cofinality
       tactic.find

universe variables u v w

namespace tactic
namespace interactive
/- maybe we should use congr' 1 instead? -/
meta def congr1 : tactic unit :=
do focus1 (congr_core >> all_goals (try reflexivity >> try assumption))

open interactive interactive.types

/-- a variant of `exact` which elaborates its argument before unifying it with the target. This variant might succeed if `exact` fails because a lot of definitional reduction is needed to verify that the term has the correct type. Metavariables which are not synthesized become new subgoals -/
meta def rexact (q : parse texpr) : tactic unit :=
do n ← mk_fresh_name,
p ← i_to_expr q,
e ← note n none p,
tactic.exact e

end interactive
end tactic

/- logic -/
namespace classical
noncomputable def psigma_of_exists {α : Type u} {p : α → Prop} (h : ∃x, p x) : Σ' x, p x :=
begin
  haveI : nonempty α := nonempty_of_exists h,
  exact ⟨epsilon p, epsilon_spec h⟩
end

lemma some_eq {α : Type u} {p : α → Prop} {h : ∃ (a : α), p a} (x : α)
  (hx : ∀y, p y → y = x) : classical.some h = x :=
classical.some_spec2 _ hx

noncomputable def instantiate_existential {α : Type*} {P : α → Prop} (h : ∃ x, P x) : {x // P x} :=
begin
  haveI : nonempty α := nonempty_of_exists h,
  exact ⟨classical.epsilon P, classical.epsilon_spec h⟩
end

lemma or_not_iff_true (p : Prop) : (p ∨ ¬ p) ↔ true :=
⟨λ_, trivial, λ_, or_not⟩

lemma nonempty_of_not_empty {α : Type u} (s : set α) (h : ¬ s = ∅) : nonempty s :=
by {haveI : decidable (nonempty s) := prop_decidable _, by_contra, simp[not_exists_not] at a, apply h, ext, exact ⟨a x, false.elim⟩ }

lemma nonempty_of_not_empty_finset {α : Type u} (s : finset α) (h : ¬ s = ∅) : nonempty s.to_set :=
by {haveI : decidable (nonempty s.to_set) := prop_decidable _, by_contra, simp[not_exists_not] at a, apply h, ext, tidy}

end classical


namespace eq
protected lemma congr {α : Type u} {x₁ x₂ y₁ y₂ : α} (h₁ : x₁ = y₁) (h₂ : x₂ = y₂) :
  (x₁ = x₂) ↔ (y₁ = y₂) :=
by subst h₁; subst h₂
end eq

lemma congr_arg2 {α : Type u} {β : Type v} {γ : Type w} (f : α → β → γ)
  {x x' : α} {y y' : β} (hx : x = x') (hy : y = y') : f x y = f x' y' :=
by subst hx; subst hy

namespace list
@[simp] protected def to_set {α : Type u} (l : list α) : set α := { x | x ∈ l }

lemma to_set_map {α : Type u} {β : Type v} (f : α → β) (l : list α) :
  (l.map f).to_set = f '' l.to_set :=
by apply set.ext; intro b; simp [list.to_set]

lemma exists_of_to_set_subset_image {α : Type u} {β : Type v} {f : α → β} {l : list β}
  {t : set α} (h : l.to_set ⊆ f '' t) : ∃(l' : list α), l'.to_set ⊆ t ∧ map f l' = l :=
begin
  induction l,
  { exact ⟨[], set.empty_subset t, rfl⟩ },
  { rcases h (mem_cons_self _ _) with ⟨x, hx, rfl⟩,
    rcases l_ih (λx hx, h $ mem_cons_of_mem _ hx) with ⟨xs, hxs, hxs'⟩,
    exact ⟨x::xs, set.union_subset (λy hy, by induction hy; exact hx) hxs, by simp*⟩ }
end

end list

inductive dvector (α : Type u) : ℕ → Type u
| nil {} : dvector 0
| cons : ∀{n} (x : α) (xs : dvector n), dvector (n+1)

inductive dfin : ℕ → Type
| fz {n} : dfin (n+1)
| fs {n} : dfin n → dfin (n+1)

instance has_zero_dfin {n} : has_zero $ dfin (n+1) := ⟨dfin.fz⟩

-- note from Mario --- use dfin to synergize with dvector
namespace dvector
section dvectors
local notation h :: t  := dvector.cons h t
local notation `[` l:(foldr `, ` (h t, dvector.cons h t) dvector.nil `]`) := l
variables {α : Type u} {β : Type v} {γ : Type w} {n : ℕ}

@[simp] protected def zero_eq : ∀(xs : dvector α 0), xs = []
| [] := rfl

@[simp] protected def concat : ∀{n : ℕ} (xs : dvector α n) (x : α), dvector α (n+1)
| _ []      x' := [x']
| _ (x::xs) x' := x::concat xs x'

@[simp] protected def nth : ∀{n : ℕ} (xs : dvector α n) (m : ℕ) (h : m < n), α
| _ []      m     h := by exfalso; exact nat.not_lt_zero m h
| _ (x::xs) 0     h := x
| _ (x::xs) (m+1) h := nth xs m (lt_of_add_lt_add_right h)

@[reducible, simp] protected def last {n : ℕ} (xs : dvector α (n+1)) : α :=
  xs.nth n (by {repeat{constructor}})

protected def nth' {n : ℕ} (xs : dvector α n) (m : fin n) : α :=
xs.nth m.1 m.2

protected def nth'' : ∀ {n : ℕ} (xs : dvector α n) (m : dfin n), α
| _ (x::xs) dfin.fz       := x
| _ (x::xs) (dfin.fs (m)) := nth'' xs m

protected def mem : ∀{n : ℕ} (x : α) (xs : dvector α n), Prop
| _ x []       := false
| _ x (x'::xs) := x = x' ∨ mem x xs
instance {n : ℕ} : has_mem α (dvector α n) := ⟨dvector.mem⟩

protected def pmem : ∀{n : ℕ} (x : α) (xs : dvector α n), Type
| _ x []       := empty
| _ x (x'::xs) := psum (x = x') (pmem x xs)

protected def mem_of_pmem : ∀{n : ℕ} {x : α} {xs : dvector α n} (hx : xs.pmem x), x ∈ xs
| _ x []       hx := by cases hx
| _ x (x'::xs) hx := by cases hx;[exact or.inl hx, exact or.inr (mem_of_pmem hx)]

@[simp] protected def map (f : α → β) : ∀{n : ℕ}, dvector α n → dvector β n
| _ []      := []
| _ (x::xs) := f x :: map xs

@[simp] protected def map2 (f : α → β → γ) : ∀{n : ℕ}, dvector α n → dvector β n → dvector γ n
| _ []      []      := []
| _ (x::xs) (y::ys) := f x y :: map2 xs ys

@[simp] protected lemma map_id : ∀{n : ℕ} (xs : dvector α n), xs.map (λx, x) = xs
| _ []      := rfl
| _ (x::xs) := by dsimp; simp*

@[simp] protected lemma map_congr_pmem {f g : α → β} :
  ∀{n : ℕ} {xs : dvector α n} (h : ∀x, xs.pmem x → f x = g x), xs.map f = xs.map g
| _ []      h := rfl
| _ (x::xs) h :=
  begin
    dsimp, congr1, exact h x (psum.inl rfl), apply map_congr_pmem,
    intros x hx, apply h, right, exact hx
  end

@[simp] protected lemma map_congr_mem {f g : α → β} {n : ℕ} {xs : dvector α n}
  (h : ∀x, x ∈ xs → f x = g x) : xs.map f = xs.map g :=
dvector.map_congr_pmem $ λx hx, h x $ dvector.mem_of_pmem hx

@[simp] protected lemma map_congr {f g : α → β} (h : ∀x, f x = g x) :
  ∀{n : ℕ} (xs : dvector α n), xs.map f = xs.map g
| _ []      := rfl
| _ (x::xs) := by dsimp; simp*

@[simp] protected lemma map_map (g : β → γ) (f : α → β): ∀{n : ℕ} (xs : dvector α n),
  (xs.map f).map g = xs.map (λx, g (f x))
  | _ []      := rfl
  | _ (x::xs) := by dsimp; simp*

protected lemma map_inj {f : α → β} (hf : ∀{{x x'}}, f x = f x' → x = x') {n : ℕ}
  {xs xs' : dvector α n} (h : xs.map f = xs'.map f) : xs = xs' :=
begin
  induction xs; cases xs', refl, simp at h, congr;[apply hf, apply xs_ih]; simp [h]
end

@[simp] protected lemma map_concat (f : α → β) : ∀{n : ℕ} (xs : dvector α n) (x : α),
  (xs.concat x).map f = (xs.map f).concat (f x)
| _ []      x' := by refl
| _ (x::xs) x' := by dsimp; congr1; exact map_concat xs x'

@[simp] protected lemma map_nth (f : α → β) : ∀{n : ℕ} (xs : dvector α n) (m : ℕ) (h : m < n),
  (xs.map f).nth m h = f (xs.nth m h)
| _ []      m     h := by exfalso; exact nat.not_lt_zero m h
| _ (x::xs) 0     h := by refl
| _ (x::xs) (m+1) h := by exact map_nth xs m _

protected lemma concat_nth : ∀{n : ℕ} (xs : dvector α n) (x : α) (m : ℕ) (h' : m < n+1)
  (h : m < n), (xs.concat x).nth m h' = xs.nth m h
| _ []      x' m     h' h := by exfalso; exact nat.not_lt_zero m h
| _ (x::xs) x' 0     h' h := by refl
| _ (x::xs) x' (m+1) h' h := by dsimp; exact concat_nth xs x' m _ _

@[simp] protected lemma concat_nth_last : ∀{n : ℕ} (xs : dvector α n) (x : α) (h : n < n+1),
  (xs.concat x).nth n h = x
| _ []      x' h := by refl
| _ (x::xs) x' h := by dsimp; exact concat_nth_last xs x' _

@[simp] protected lemma concat_nth_last' : ∀{n : ℕ} (xs : dvector α n) (x : α) (h : n < n+1),
  (xs.concat x).last = x
:= by apply dvector.concat_nth_last

@[simp] protected def append : ∀{n m : ℕ} (xs : dvector α n) (xs' : dvector α m), dvector α (m+n)
| _ _ []       xs := xs
| _ _ (x'::xs) xs' := x'::append xs xs'

@[simp]protected def insert : ∀{n : ℕ} (x : α) (k : ℕ) (xs : dvector α n), dvector α (n+1)
| n x 0 xs := (x::xs)
| 0 x k xs := (x::xs)
| (n+1) x (k+1) (y::ys) := (y::insert x k ys)

@[simp] protected lemma insert_at_zero : ∀{n : ℕ} (x : α) (xs : dvector α n), dvector.insert x 0 xs = (x::xs) := by {intros, induction n; refl} -- why doesn't {intros, refl} work?

@[simp] protected lemma insert_nth : ∀{n : ℕ} (x : α) (k : ℕ) (xs : dvector α n) (h : k < n+1), (dvector.insert x k xs).nth k h = x
| 0 x k xs h := by {cases h, refl, exfalso, apply nat.not_lt_zero, exact h_a}
| n x 0 xs h := by {induction n, refl, simp*}
| (n+1) x (k+1) (y::ys) h := by simp*

protected lemma insert_cons {n k} {x y : α} {v : dvector α n} : (x::(v.insert y k)) = (x::v).insert y (k+1) :=
by {induction v, refl, simp*}

/- Given a proof that n ≤ m, return the nth initial segment of -/
@[simp]protected def trunc : ∀ (n) {m : ℕ} (h : n ≤ m) (xs : dvector α m), dvector α n
| 0 0 _ xs := []
| 0 (m+1) _ xs := []
| (n+1) 0 _ xs := by {exfalso, cases _x}
| (n+1) (m+1) h (x::xs) := (x::@trunc n m (by simp at h; exact h) xs)

@[simp]protected lemma trunc_n_n {n : ℕ} {h : n ≤ n} {v : dvector α n} : dvector.trunc n h v = v :=
  by {induction v, refl, solve_by_elim}

@[simp]protected lemma trunc_0_n {n : ℕ} {h : 0 ≤ n} {v : dvector α n} : dvector.trunc 0 h v = [] :=
  by {induction v, refl, simp}

@[simp]protected lemma trunc_nth {n m l: ℕ} {h : n ≤ m} {h' : l < n} {v : dvector α m} : (v.trunc n h).nth l h' = v.nth l (lt_of_lt_of_le h' h) :=
begin
  induction m generalizing n l, have : n = 0, by cases h; simp, subst this, cases h',
  cases n; cases l, {cases h'}, {cases h'}, {cases v, refl},
  cases v, simp only [m_ih, dvector.nth, dvector.trunc]
end

protected lemma nth_irrel1 : ∀{n k : ℕ} {h : k < n + 1} {h' : k < n + 1 + 1} (v : dvector α (n+1)) (x : α),
  (x :: (v.trunc n (nat.le_succ n))).nth k h = (x::v).nth k h' :=
by {intros, apply @dvector.trunc_nth _ _ _ _ (by {simp, exact dec_trivial}) h (x::v)}

protected def cast {n m} (p : n = m) : dvector α n → dvector α m :=
  by subst p; exact id

@[simp] protected lemma cast_irrel {n m} {p p' : n = m} {v : dvector α n} : v.cast p = v.cast p' := by refl

@[simp] protected lemma cast_rfl {n m} {p : n = m} {q : m = n} {v : dvector α n} : (v.cast p).cast q = v := by {subst p, refl}

protected lemma cast_hrfl {n m} {p : n = m} {v : dvector α n} : v.cast p == v :=
  by subst p; refl

@[simp] protected lemma cast_trans {n m o} {p : n = m} {q : m = o} {v : dvector α n} : (v.cast p).cast q = v.cast (trans p q) := by subst p; subst q; refl

@[simp] protected def remove_mth : ∀ {n : ℕ} (m : ℕ) (xs : dvector α (n+1)) , dvector α (n)
  | 0 _ _  := dvector.nil
  | n 0 (dvector.cons y ys) := ys
  | (n+1) (k+1) (dvector.cons y ys) := dvector.cons y (remove_mth k ys)

@[simp] def foldr (f : α → β → β) (b : β) : ∀{n}, dvector α n → β
| _ []       := b
| _ (a :: l) := f a (foldr l)

@[simp] def zip : ∀{n}, dvector α n → dvector β n → dvector (α × β) n
| _ [] []               := []
| _ (x :: xs) (y :: ys) := ⟨x, y⟩ :: zip xs ys

open lattice
/-- The finitary infimum -/
def fInf [semilattice_inf_top α] (xs : dvector α n) : α :=
xs.foldr (λ(x b : α), x ⊓ b) ⊤

@[simp] lemma fInf_nil [semilattice_inf_top α] : fInf [] = (⊤ : α) := by refl
@[simp] lemma fInf_cons [semilattice_inf_top α] (x : α) (xs : dvector α n) :
  fInf (x::xs) = x ⊓ fInf xs := by refl

/-- The finitary supremum -/
def fSup [semilattice_sup_bot α] (xs : dvector α n) : α :=
xs.foldr (λ(x b : α), x ⊔ b) ⊥

@[simp] lemma fSup_nil [semilattice_sup_bot α] : fSup [] = (⊥ : α) := by refl
@[simp] lemma fSup_cons [semilattice_sup_bot α] (x : α) (xs : dvector α n) :
  fSup (x::xs) = x ⊔ fSup xs := by refl

/- how to make this protected? -/
inductive rel [setoid α] : ∀{n}, dvector α n → dvector α n → Prop
| rnil : rel [] []
| rcons {n} {x x' : α} {xs xs' : dvector α n} (hx : x ≈ x') (hxs : rel xs xs') :
    rel (x::xs) (x'::xs')

open rel

protected def rel_refl [setoid α] : ∀{n} (xs : dvector α n), xs.rel xs
| _ []      := rnil
| _ (x::xs) := rcons (setoid.refl _) (rel_refl xs)

protected def rel_symm [setoid α] {n} {{xs xs' : dvector α n}} (h : xs.rel xs') : xs'.rel xs :=
begin induction h; constructor, exact setoid.symm h_hx, exact h_ih end

protected def rel_trans [setoid α] {n} {{xs₁ xs₂ xs₃ : dvector α n}}
  (h₁ : xs₁.rel xs₂) (h₂ : xs₂.rel xs₃) : xs₁.rel xs₃ :=
begin
  induction h₁ generalizing h₂, exact h₂,
  cases h₂, constructor, exact setoid.trans h₁_hx h₂_hx, exact h₁_ih h₂_hxs
end

-- protected def rel [setoid α] : ∀{n}, dvector α n → dvector α n → Prop
-- | _ []      []        := true
-- | _ (x::xs) (x'::xs') := x ≈ x' ∧ rel xs xs'

-- protected def rel_refl [setoid α] : ∀{n} (xs : dvector α n), xs.rel xs
-- | _ []      := trivial
-- | _ (x::xs) := ⟨by refl, rel_refl xs⟩

-- protected def rel_symm [setoid α] : ∀{n} {{xs xs' : dvector α n}}, xs.rel xs' → xs'.rel xs
-- | _ []      []        h := trivial
-- | _ (x::xs) (x'::xs') h := ⟨setoid.symm h.1, rel_symm h.2⟩

-- protected def rel_trans [setoid α] : ∀{n} {{xs₁ xs₂ xs₃ : dvector α n}},
--   xs₁.rel xs₂ → xs₂.rel xs₃ → xs₁.rel xs₃
-- | _ []        []        []        h₁ h₂ := trivial
-- | _ (x₁::xs₁) (x₂::xs₂) (x₃::xs₃) h₁ h₂ := ⟨setoid.trans h₁.1 h₂.1, rel_trans h₁.2 h₂.2⟩

instance setoid [setoid α] : setoid (dvector α n) :=
⟨dvector.rel, dvector.rel_refl, dvector.rel_symm, dvector.rel_trans⟩

def quotient_lift {α : Type u} {β : Sort v} {R : setoid α} : ∀{n} (f : dvector α n → β)
  (h : ∀{{xs xs'}}, xs ≈ xs' → f xs = f xs') (xs : dvector (quotient R) n), β
| _     f h []      := f ([])
| (n+1) f h (x::xs) :=
  begin
    refine quotient.lift
      (λx, quotient_lift (λ xs, f $ x::xs) (λxs xs' hxs, h (rcons (setoid.refl x) hxs)) xs) _ x,
    intros x x' hx, dsimp, congr, apply funext, intro xs, apply h, exact rcons hx xs.rel_refl
  end

def quotient_beta {α : Type u} {β : Sort v} {R : setoid α} {n} (f : dvector α n → β)
  (h : ∀{{xs xs'}}, xs ≈ xs' → f xs = f xs') (xs : dvector α n) :
  (xs.map quotient.mk).quotient_lift f h = f xs :=
begin
  induction xs, refl, apply xs_ih
end
end dvectors
end dvector


namespace nat
lemma add_sub_swap {n k : ℕ} (h : k ≤ n) (m : ℕ) : n + m - k = n - k + m :=
by rw [add_comm, nat.add_sub_assoc h, add_comm]

lemma one_le_of_lt {n k : ℕ} (H : n < k) : 1 ≤ k :=
succ_le_of_lt (lt_of_le_of_lt n.zero_le H)

lemma add_sub_cancel_right (n m k : ℕ) : n + (m + k) - k = n + m :=
by rw [nat.add_sub_assoc, nat.add_sub_cancel]; apply k.le_add_left

protected lemma pred_lt_iff_lt_succ {m n : ℕ} (H : 1 ≤ m) : pred m < n ↔ m < succ n :=
nat.sub_lt_right_iff_lt_add H

end nat

def lt_by_cases {α : Type u} [decidable_linear_order α] (x y : α) {P : Sort v}
  (h₁ : x < y → P) (h₂ : x = y → P) (h₃ : y < x → P) : P :=
begin
  by_cases h : x < y, { exact h₁ h },
  by_cases h' : y < x, { exact h₃ h' },
  apply h₂, apply le_antisymm; apply le_of_not_gt; assumption
end

lemma imp_eq_congr {a b c d : Prop} (h₁ : a = b) (h₂ : c = d) : (a → c) = (b → d) :=
by subst h₁; subst h₂; refl

lemma forall_eq_congr {α : Sort u} {p q : α → Prop} (h : ∀ a, p a = q a) :
  (∀ a, p a) = ∀ a, q a :=
have h' : p = q, from funext h, by subst h'; refl

namespace set
/- Some of these lemmas might be duplicates of those in data.set.lattice -/

variables {α : Type u} {β : Type v} {γ : Type w}

lemma ne_empty_of_exists_mem {s : set α} : ∀(h : ∃x, x ∈ s), s ≠ ∅
| ⟨x, hx⟩ := ne_empty_of_mem hx

lemma subset_insert_diff (s t : set α) [decidable_pred (∈ t)] : s ⊆ (s \ t) ∪ t :=
begin
  intros x hxs, by_cases hxt : x ∈ t, { right, exact hxt }, {left, exact ⟨hxs, hxt⟩ }
end

lemma subset_insert_diff_singleton [h : decidable_eq α] (x : α) (s : set α) :
  s ⊆ insert x (s \ {x}) :=
begin
haveI : decidable_pred (∈ ({x} : set α)) := λy, by simp; apply_instance,
 rw [←union_singleton], apply subset_insert_diff
end

@[simp] lemma diff_singleton_subset_iff {x : α} {s t : set α} :
  s \ {x} ⊆ t ↔ s ⊆ insert x t :=
by rw [←union_singleton, union_comm]; apply diff_subset_iff

@[simp] lemma Union_of_singleton (α : Type u) :
  (⋃(x : α), {x}) = @set.univ α :=
ext $ λ x, ⟨λ h, ⟨⟩, λ h, ⟨{x}, ⟨⟨x, rfl⟩, mem_singleton x⟩⟩⟩

-- generalizes set.image_preimage_eq
-- todo: remove, and only use image_preimage_eq_of_subset
lemma image_preimage_eq_of_subset_image {f : α → β} {s : set β}
  {t : set α} (h : s ⊆ f '' t) : f '' (f ⁻¹' s) = s :=
subset.antisymm
  (image_preimage_subset f s)
  (λ x hx, begin rcases h hx with ⟨a, ha, rfl⟩, apply mem_image_of_mem f, exact hx end)

lemma subset_union_left_of_subset {s t : set α} (h : s ⊆ t) (u : set α) : s ⊆ t ∪ u :=
subset.trans h (subset_union_left t u)

lemma subset_union_right_of_subset {s u : set α} (h : s ⊆ u) (t : set α) : s ⊆ t ∪ u :=
subset.trans h (subset_union_right t u)

lemma subset_sUnion {s : set α} {t : set (set α)} (h : s ∈ t) : s ⊆ ⋃₀ t :=
λx hx, ⟨s, ⟨h, hx⟩⟩

lemma subset_sUnion_of_subset {s : set α} (t : set (set α)) (u : set α) (h₁ : s ⊆ u)
  (h₂ : u ∈ t) : s ⊆ ⋃₀ t :=
subset.trans h₁ (subset_sUnion h₂)

lemma image_congr' {f g : α → β} {s : set α} (h : ∀ (x : α), f x = g x) : f '' s = g '' s :=
image_congr (λx _, h x)

lemma image_image (g : β → γ) (f : α → β) (s : set α) : g '' (f '' s) = (λ x, g (f x)) '' s :=
(image_comp g f s).symm

@[simp] lemma image_id' (s : set α) : (λx, x) '' s = s := image_id s

lemma image_preimage_eq_of_subset {f : α → β} {s : set β} (h : s ⊆ range f) :
  f '' (f ⁻¹' s) = s :=
begin
  ext, refine ⟨λhx, image_preimage_subset f s hx, _⟩,
  intro hx, rcases h hx with ⟨x, rfl⟩, apply mem_image_of_mem, exact hx
end

lemma preimage_subset_preimage_iff {s t : set α} {f : β → α} (hs : s ⊆ range f) :
  f ⁻¹' s ⊆ f ⁻¹' t ↔ s ⊆ t :=
begin
  split,
  { intros h x hx, rcases hs hx with ⟨y, rfl⟩, exact h hx },
  intros h x, apply h
end

lemma preimage_eq_preimage' {s t : set α} {f : β → α} (hs : s ⊆ range f) (ht : t ⊆ range f) :
  f ⁻¹' s = f ⁻¹' t ↔ s = t :=
begin
  split,
  { intro h, apply subset.antisymm, rw [←preimage_subset_preimage_iff hs, h],
    rw [←preimage_subset_preimage_iff ht, h] },
  rintro rfl, refl
end

lemma subset_union2_left {s t u : set α} : s ⊆ s ∪ t ∪ u :=
subset.trans (subset_union_left _ _) (subset_union_left _ _)

lemma subset_union2_middle {s t u : set α} : t ⊆ s ∪ t ∪ u :=
subset.trans (subset_union_right _ _) (subset_union_left _ _)

open function
lemma Union_range_eq_sUnion {α β : Type*} (C : set (set α))
  {f : ∀(s : C), β → s} (hf : ∀(s : C), surjective (f s)) :
  (⋃(y : β), range (λ(s : C), (f s y).val)) = ⋃₀ C :=
begin
  ext x, split,
  { rintro ⟨s, ⟨y, rfl⟩, ⟨⟨s, hs⟩, rfl⟩⟩, refine ⟨_, hs, _⟩, exact (f ⟨s, hs⟩ y).2 },
  { rintro ⟨s, hs, hx⟩, cases hf ⟨s, hs⟩ ⟨x, hx⟩ with y hy, refine ⟨_, ⟨y, rfl⟩, ⟨⟨s, hs⟩, _⟩⟩,
    exact congr_arg subtype.val hy }
end

lemma Union_range_eq_Union {ι α β : Type*} (C : ι → set α)
  {f : ∀(x : ι), β → C x} (hf : ∀(x : ι), surjective (f x)) :
  (⋃(y : β), range (λ(x : ι), (f x y).val)) = ⋃x, C x :=
begin
  ext x, rw [mem_Union, mem_Union], split,
  { rintro ⟨y, ⟨i, rfl⟩⟩, exact ⟨i, (f i y).2⟩ },
  { rintro ⟨i, hx⟩, cases hf i ⟨x, hx⟩ with y hy, refine ⟨y, ⟨i, congr_arg subtype.val hy⟩⟩ }
end

lemma range_val (s : set α) : range (subtype.val : s → α) = s :=
begin
  ext, split, rintro ⟨⟨x, h⟩, rfl⟩, exact h,
  intro h, exact ⟨⟨x, h⟩, rfl⟩
end

lemma inj_on_comp_of_injective_left {g : β → γ} {f : α → β} {a : set α} (hg : injective g)
  (hf : inj_on f a) : inj_on (g ∘ f) a :=
inj_on_comp (maps_to_univ _ _) (injective_iff_inj_on_univ.mp hg) hf

lemma inj_on_preimage {f : α → β} {B : set (set β)} (hB : B ⊆ powerset (range f)) :
  inj_on (preimage f) B :=
begin
  intros s t hs ht hst,
  rw [←image_preimage_eq_of_subset (hB hs), ←image_preimage_eq_of_subset (hB ht), hst]
end

lemma exists_set_subtype {t : set α} (p : set α → Prop) :
(∃(s : set t), p (subtype.val '' s)) ↔ ∃(s : set α), s ⊆ t ∧ p s :=
begin
  split,
  { rintro ⟨s, hs⟩, refine ⟨subtype.val '' s, _, hs⟩,
    convert image_subset_range _ _, rw [range_val] },
  rintro ⟨s, hs₁, hs₂⟩, refine ⟨subtype.val ⁻¹' s, _⟩,
  rw [image_preimage_eq_of_subset], exact hs₂, rw [range_val], exact hs₁
end

lemma subset_image_iff {f : α → β} {s : set α} {t : set β} :
  t ⊆ f '' s ↔ ∃t', t' ⊆ s ∧ f '' t' = t :=
begin
  split,
  { intro h,
    have : ∀(y : t), ∃x ∈ s, f x = y,
    { rintros ⟨y, hy⟩, rcases h hy with ⟨x, hx, hx'⟩, exact ⟨x, hx, hx'⟩ },
    let g : t → α := λy, classical.some (this y),
    have : ∀(y : t), g y ∈ s ∧ f (g y) = y,
    { intro y, cases classical.some_spec (this y) with h h', exact ⟨h,h'⟩ },
    refine ⟨range g, _, _⟩,
    { rintro _ ⟨y, rfl⟩, exact (this y).1 },
    apply subset.antisymm,
    { rintro _ ⟨_, ⟨y, rfl⟩, rfl⟩, rw [(this y).2], exact y.2 },
    { rintro y hy, refine ⟨g ⟨y, hy⟩, mem_range_self _, _⟩, rw [(this ⟨y, hy⟩).2], refl }},
  { rintro ⟨t, ht, rfl⟩, apply image_subset f ht }
end

lemma subset_range_iff {f : α → β} {t : set β} : t ⊆ range f ↔ ∃t', f '' t' = t :=
by { rw [←image_univ, subset_image_iff], simp only [true_and, set.subset_univ] }

lemma image_eq_range (f : α → β) (s : set α) : f '' s = range (λ(x : s), f x.1) :=
by { ext, split, rintro ⟨x, h1, h2⟩, exact ⟨⟨x, h1⟩, h2⟩, rintro ⟨⟨x, h1⟩, h2⟩, exact ⟨x, h1, h2⟩ }

lemma ne_of_disjoint {s t : set α} (hs : nonempty s) (hst : s ∩ t = ∅) : s ≠ t :=
by { intro h, rw [←h, inter_self] at hst, rw [coe_nonempty_iff_ne_empty] at hs, exact hs hst }

lemma nonempty_image (f : α → β) {s : set α} : nonempty s → nonempty (f '' s)
| ⟨⟨x, hx⟩⟩ := ⟨⟨f x, mem_image_of_mem f hx⟩⟩

theorem finite_bUnion' {α} {ι : Type*} {s : set ι} (f : ι → set α) :
  finite s → (∀i ∈ s, finite (f i)) → finite (⋃ i∈s, f i)
| ⟨hs⟩ h := by rw [bUnion_eq_Union]; exactI finite_Union (λ i, h i.1 i.2)

def change {π : α → Type*} [decidable_eq α] (f : Πa, π a) {x : α} (z : π x) (y : α) : π y :=
if h : x = y then (@eq.rec _ _ π z _ h) else f y

lemma dif_mem_pi {π : α → Type*} (i : set α) (s : Πa, set (π a)) [decidable_eq α]
  (f : Πa, π a) (hf : f ∈ pi i s) {x : α} (z : π x) (h : x ∈ i → z ∈ s x) :
  change f z ∈ pi i s :=
begin
  intros y hy, dsimp only,
  by_cases hxy : x = y,
  { rw [change, dif_pos hxy], subst hxy, exact h hy },
  { rw [change, dif_neg hxy], apply hf y hy }
end

lemma image_pi_pos {π : α → Type*} (i : set α) (s : Πa, set (π a)) [decidable_eq α]
  (hp : nonempty (pi i s)) (x : α) (hx : x ∈ i) : (λ(f : Πa, π a), f x) '' pi i s = s x :=
begin
  apply subset.antisymm,
  { rintro _ ⟨f, hf, rfl⟩, exact hf x hx },
  intros z hz, have := hp, rcases this with ⟨f, hf⟩,
  refine ⟨_, dif_mem_pi i s f hf z (λ _, hz), _⟩,
  simp only [change, dif_pos rfl]
end

lemma image_pi_neg {π : α → Type*} (i : set α) (s : Πa, set (π a)) [decidable_eq α]
  (hp : nonempty (pi i s)) (x : α) (hx : x ∉ i) : (λ(f : Πa, π a), f x) '' pi i s = univ :=
begin
  rw [eq_univ_iff_forall], intro z, have := hp, rcases this with ⟨f, hf⟩,
  refine ⟨_, dif_mem_pi i s f hf z _, _⟩,
  intro hx', exfalso, exact hx hx',
  simp only [change, dif_pos rfl]
end

end set
open nat

namespace finset
open function
variables {α : Type u} {β : Type v} [decidable_eq α] [decidable_eq β]

def to_set_sdiff (s t : finset α) : (s \ t).to_set = s.to_set \ t.to_set :=
by apply finset.coe_sdiff

lemma exists_of_subset_image {f : α → β} {s : finset β} {t : set α} (h : ↑s ⊆ f '' t) :
  ∃s' : finset α, ↑s' ⊆ t ∧ s'.image f = s :=
begin
  induction s using finset.induction with a s has ih h,
  { exact ⟨∅, set.empty_subset _, finset.image_empty _⟩ },
  rw [finset.coe_insert, set.insert_subset] at h,
  rcases ih h.2 with ⟨s', hst, hsi⟩,
  rcases h.1 with ⟨x, hxt, rfl⟩,
  refine ⟨insert x s', _, _⟩,
  { rw [finset.coe_insert, set.insert_subset], exact ⟨hxt, hst⟩ },
  rw [finset.image_insert, hsi]
end

theorem filter_union_right (p q : α → Prop) [decidable_pred p] [decidable_pred q] (s : finset α) :
  s.filter p ∪ s.filter q = s.filter (λx, p x ∨ q x) :=
ext.2 $ λ x, by simp only [mem_filter, mem_union, and_or_distrib_left.symm]

lemma subset_union_elim {s : finset α} {t₁ t₂ : set α} [decidable_pred (∈ t₁)] (h : ↑s ⊆ t₁ ∪ t₂) :
  ∃s₁ s₂ : finset α, s₁ ∪ s₂ = s ∧ ↑s₁ ⊆ t₁ ∧ ↑s₂ ⊆ t₂ \ t₁ :=
begin
  refine ⟨s.filter (∈ t₁), s.filter (∉ t₁), _, _ , _⟩,
  { simp [filter_union_right, classical.or_not_iff_true] },
  { intro x, simp },
  { intro x, simp, intros hx hx₂, refine ⟨or.resolve_left (h hx) hx₂, hx₂⟩ }
end

lemma to_set_injective {α} : injective (finset.to_set : finset α → set α) :=
λ s t, coe_inj.1

end finset

namespace nonempty
variables {α : Type u} {β : Type v} {γ : Type w}

protected def map2 (f : α → β → γ) : nonempty α → nonempty β → nonempty γ
| ⟨x⟩ ⟨y⟩ := ⟨f x y⟩

protected def iff (mp : α → β) (mpr : β → α) : nonempty α ↔ nonempty β :=
⟨nonempty.map mp, nonempty.map mpr⟩

end nonempty

namespace fin

  def fin_zero_elim {α : fin 0 → Sort u} : ∀(x : fin 0), α x
  | ⟨n, hn⟩ := false.elim (nat.not_lt_zero n hn)

end fin

/-- The type α → (α → ... (α → β)...) with n α's. We require that α and β live in the same universe, otherwise we have to use ulift. -/
def arity' (α β : Type u) : ℕ → Type u
| 0     := β
| (n+1) := α → arity' n

namespace arity'
section arity'
local notation h :: t  := dvector.cons h t
local notation `[` l:(foldr `, ` (h t, dvector.cons h t) dvector.nil `]`) := l
def arity'_constant {α β : Type u} : ∀{n : ℕ}, β → arity' α β n
| 0     b := b
| (n+1) b := λ_, arity'_constant b

@[simp] def of_dvector_map {α β : Type u} : ∀{l} (f : dvector α l → β), arity' α β l
| 0     f := f ([])
| (l+1) f := λx, of_dvector_map $ λxs, f $ x::xs

@[simp] def arity'_app {α β : Type u} : ∀{l}, arity' α β l → dvector α l → β
| _ b []      := b
| _ f (x::xs) := arity'_app (f x) xs

@[simp] lemma arity'_app_zero {α β : Type u} (f : arity' α β 0) (xs : dvector α 0) :
  arity'_app f xs = f :=
by cases xs; refl

def arity'_postcompose {α β γ : Type u} (g : β → γ) : ∀{n} (f : arity' α β n), arity' α γ n
| 0     b := g b
| (n+1) f := λx, arity'_postcompose (f x)

def arity'_postcompose2 {α β γ δ : Type u} (h : β → γ → δ) :
  ∀{n} (f : arity' α β n) (g : arity' α γ n), arity' α δ n
| 0     b c := h b c
| (n+1) f g := λx, arity'_postcompose2 (f x) (g x)

def arity'_precompose {α β γ : Type u} : ∀{n} (g : arity' β γ n) (f : α → β), arity' α γ n
| 0     c f := c
| (n+1) g f := λx, arity'_precompose (g (f x)) f

inductive arity'_respect_setoid {α β : Type u} [R : setoid α] : ∀{n}, arity' α β n → Type u
| r_zero (b : β) : @arity'_respect_setoid 0 b
| r_succ (n : ℕ) (f : arity' α β (n+1)) (h₁ : ∀{{a a'}}, a ≈ a' → f a = f a')
  (h₂ : ∀a, arity'_respect_setoid (f a)) : arity'_respect_setoid f
open arity'_respect_setoid

instance subsingleton_arity'_respect_setoid {α β : Type u} [R : setoid α] {n} (f : arity' α β n) :
  subsingleton (arity'_respect_setoid f) :=
begin
  constructor, intros h h', induction h generalizing h'; cases h'; try {refl}; congr,
  apply funext, intro x, apply h_ih
end

-- def arity'_quotient_lift {α β : Type u} {R : setoid α} :
--   ∀{n}, (Σ(f : arity' α β n), arity'_respect_setoid f) → arity' (quotient R) β n
-- | _ ⟨_, r_zero b⟩         := b
-- | _ ⟨_, r_succ n f h₁ h₂⟩ :=
--   begin
--     apply quotient.lift (λx, arity'_quotient_lift ⟨f x, h₂ x⟩),
--     intros x x' r, dsimp,
--     apply congr_arg, exact sigma.eq (h₁ r) (subsingleton.elim _ _)
--   end

-- def arity'_quotient_beta {α β : Type u} {R : setoid α} {n} (f : arity' α β n)
--   (hf : arity'_respect_setoid f) (xs : dvector α n) :
--   arity'_app (arity'_quotient_lift ⟨f, hf⟩) (xs.map quotient.mk) = arity'_app f xs :=
-- begin
--   induction hf,
--   { simp [arity'_quotient_lift] },
--   dsimp [arity'_app], sorry
-- end

def for_all {α : Type u} (P : α → Prop) : Prop := ∀x, P x

@[simp] def arity'_map2 {α β : Type u} (q : (α → β) → β) (f : β → β → β) :
  ∀{n}, arity' α β n → arity' α β n → β
| 0     x y := f x y
| (n+1) x y := q (λz, arity'_map2 (x z) (y z))

@[simp] lemma arity'_map2_refl {α : Type} {f : Prop → Prop → Prop} (r : ∀A, f A A) :
  ∀{n} (x : arity' α Prop n), arity'_map2 for_all f x x
| 0     x := r x
| (n+1) x := λy, arity'_map2_refl (x y)

def arity'_imp {α : Type} {n : ℕ} (f₁ f₂ : arity' α Prop n) : Prop :=
arity'_map2 for_all (λP Q, P → Q) f₁ f₂

def arity'_iff {α : Type} {n : ℕ} (f₁ f₂ : arity' α Prop n) : Prop :=
arity'_map2 for_all iff f₁ f₂

lemma arity'_iff_refl {α : Type} {n : ℕ} (f : arity' α Prop n) : arity'_iff f f :=
arity'_map2_refl iff.refl f

lemma arity'_iff_rfl {α : Type} {n : ℕ} {f : arity' α Prop n} : arity'_iff f f :=
arity'_iff_refl f

end arity'
end arity'

namespace lattice
instance complete_degenerate_boolean_algebra : complete_boolean_algebra unit :=
{ sup := λ _ _, (),
  le := λ _ _, true,
  lt := λ _ _, false,
  le_refl := by tidy,
  le_trans := by tidy,
  lt_iff_le_not_le := by tidy,
  le_antisymm := by tidy,
  le_sup_left :=  by tidy,
  le_sup_right :=  by tidy,
  sup_le :=  by tidy,
  inf := λ _ _, (),
  inf_le_left :=  by tidy,
  inf_le_right :=  by tidy,
  le_inf :=  by tidy,
  le_sup_inf :=  by tidy,
  top := (),
  le_top :=  by tidy,
  bot := (),
  bot_le :=  by tidy,
  neg := λ _, (),
  sub := λ _ _, (),
  inf_neg_eq_bot :=  by tidy,
  sup_neg_eq_top :=  by tidy,
  sub_eq :=  by tidy,
  Sup := λ _, (),
  Inf := λ _, (),
  le_Sup := by tidy,
  Sup_le := by tidy,
  Inf_le := by tidy,
  le_Inf := by tidy,
  infi_sup_le_sup_Inf := by tidy,
  inf_Sup_le_supr_inf := by tidy}

class nontrivial_complete_boolean_algebra (α : Type*) extends complete_boolean_algebra α :=
  {bot_lt_top : (⊥ : α) < (⊤ : α)}

@[simp]lemma nontrivial.bot_lt_top {α : Type*} [H : nontrivial_complete_boolean_algebra α] : (⊥ : α) < ⊤ :=
H.bot_lt_top

def antichain {β : Type*} [bounded_lattice β] (s : set β) :=
  ∀ x ∈ s, ∀ y ∈ s, x ≠ y → x ⊓ y = (⊥ : β)

theorem inf_supr_eq {α ι : Type*} [complete_distrib_lattice α] {a : α} {s : ι → α} :
  a ⊓ (⨆(i:ι), s i) = ⨆(i:ι), a ⊓ s i :=
  eq.trans inf_Sup_eq $
    begin
      rw[<-inf_Sup_eq], suffices : (⨆(i:ι), a ⊓ s i) = ⨆(b∈(set.range s)), a ⊓ b,
      by {rw[this], apply inf_Sup_eq}, simp, apply le_antisymm,
      apply supr_le, intro i, apply le_supr_of_le (s i), apply le_supr_of_le i,
      apply le_supr_of_le rfl, refl,
      repeat{apply supr_le, intro}, rw[<-i_2], apply le_supr_of_le i_1, refl
    end

theorem supr_inf_eq {α ι : Type*} [complete_distrib_lattice α] {a : α} {s : ι → α} :
  (⨆(i:ι), s i) ⊓ a = ⨆(i:ι), s i ⊓ a :=
by simp[inf_comm,inf_supr_eq]

theorem sup_infi_eq {α ι : Type*} [complete_distrib_lattice α] {a : α} {s : ι → α} :
  a ⊔ (⨅(i:ι), s i) = ⨅(i:ι), a ⊔ s i :=
  eq.trans sup_Inf_eq $
    begin
      rw[<-sup_Inf_eq], suffices : (⨅(i:ι), a ⊔ s i) = ⨅(b∈(set.range s)), a ⊔ b,
      by {rw[this], apply sup_Inf_eq}, simp, apply le_antisymm,
      repeat{apply le_infi, intro}, rw[<-i_2], apply infi_le_of_le i_1, refl,
      repeat{apply infi_le_of_le}, show ι, from ‹ι›, show α, exact s i, refl, refl
    end

theorem infi_sup_eq {α ι : Type*} [complete_distrib_lattice α] {a : α} {s : ι → α} :
 (⨅(i:ι), s i) ⊔ a = ⨅(i:ι), s i ⊔ a :=
by {rw[sup_comm], conv{to_rhs, simp[sup_comm]}, apply sup_infi_eq}

@[simp]lemma inf_self {α : Type*} [lattice α] {a : α} : a ⊓ a = a :=
  by simp

@[simp]lemma sup_self {α : Type*} [lattice α] {a : α} : a ⊔ a = a :=
  by simp

def imp {α : Type*} [boolean_algebra α] : α → α → α :=
  λ a₁ a₂, (- a₁) ⊔ a₂

local infix ` ⟹ `:65 := lattice.imp

@[reducible, simp]def biimp {α : Type*} [boolean_algebra α] : α → α → α :=
  λ a₁ a₂, (a₁ ⟹ a₂) ⊓ (a₂ ⟹ a₁)

local infix ` ⇔ `:50 := lattice.biimp

lemma biimp_mp {α : Type*} [boolean_algebra α] {a₁ a₂ : α} : (a₁ ⇔ a₂) ≤ (a₁ ⟹ a₂) :=
  by apply inf_le_left

lemma biimp_mpr {α : Type*} [boolean_algebra α] {a₁ a₂ : α} : (a₁ ⇔ a₂) ≤ (a₂ ⟹ a₁) :=
  by apply inf_le_right

@[simp]lemma imp_le_of_right_le {α : Type*} [boolean_algebra α] {a a₁ a₂ : α} {h : a₁ ≤ a₂} : a ⟹ a₁ ≤ (a ⟹ a₂) :=
sup_le (by apply le_sup_left) $ le_sup_right_of_le h

@[simp]lemma imp_le_of_left_le {α : Type*} [boolean_algebra α] {a a₁ a₂ : α} {h : a₂ ≤ a₁} : a₁ ⟹ a ≤ (a₂ ⟹ a) :=
sup_le (le_sup_left_of_le $ neg_le_neg h) (by apply le_sup_right)

@[simp]lemma imp_le_of_left_right_le {α : Type*} [boolean_algebra α] {a₁ a₂ b₁ b₂ : α}
{h₁ : b₁ ≤ a₁} {h₂ : a₂ ≤ b₂} :
  a₁ ⟹ a₂ ≤ b₁ ⟹ b₂ :=
sup_le (le_sup_left_of_le (neg_le_neg h₁)) (le_sup_right_of_le h₂)

lemma neg_le_neg' {α : Type*} [boolean_algebra α] {a b : α} : b ≤ -a → a ≤ -b :=
by {intro H, rw[show b = - - b, by simp] at H, rwa[<-neg_le_neg_iff_le]}

lemma inf_imp_eq {α : Type*} [boolean_algebra α] {a b c : α} :
  a ⊓ (b ⟹ c) = (a ⟹ b) ⟹ (a ⊓ c) :=
by unfold imp; simp[inf_sup_left]

@[simp]lemma imp_bot {α : Type*} [boolean_algebra α]  {a : α} : a ⟹ ⊥ = - a := by simp[imp]

@[simp]lemma top_imp {α : Type*} [boolean_algebra α] {a : α} : ⊤ ⟹ a = a := by simp[imp]

@[simp]lemma imp_self {α : Type*} [boolean_algebra α] {a : α} : a ⟹ a = ⊤ := by simp[imp]

lemma imp_neg_sub {α : Type*} [boolean_algebra α] {a₁ a₂ : α} :  -(a₁ ⟹ a₂) = a₁ - a₂ :=
  by rw[sub_eq, imp]; simp*

lemma inf_eq_of_le {α : Type*} [distrib_lattice α] {a b : α} (h : a ≤ b) : a ⊓ b = a :=
  by apply le_antisymm; simp[*,le_inf]

lemma imp_inf_le {α : Type*} [boolean_algebra α] (a b : α) : (a ⟹ b) ⊓ a ≤ b :=
by { unfold imp, rw [inf_sup_right], simp }

lemma le_of_sub_eq_bot {α : Type*} [boolean_algebra α] {a b : α} (h : - b ⊓ a = ⊥) : a ≤ b :=
begin
  apply le_of_inf_eq, rw [←@neg_neg _ b _, ←sub_eq], apply sub_eq_left, rwa [inf_comm]
end

lemma le_neg_of_inf_eq_bot {α : Type*} [boolean_algebra α] {a b : α} (h : b ⊓ a = ⊥) : a ≤ - b :=
by { apply le_of_sub_eq_bot, rwa [neg_neg] }

lemma sub_eq_bot_of_le {α : Type*} [boolean_algebra α] {a b : α} (h : a ≤ b) : - b ⊓ a = ⊥ :=
by rw [←inf_eq_of_le h, inf_comm, inf_assoc, inf_neg_eq_bot, inf_bot_eq]

lemma inf_eq_bot_of_le_neg {α : Type*} [boolean_algebra α] {a b : α} (h : a ≤ - b) : b ⊓ a = ⊥ :=
by { rw [←@neg_neg _ b], exact sub_eq_bot_of_le h }


/-- the deduction theorem in β -/
@[simp]lemma imp_top_iff_le {α : Type*} [boolean_algebra α] {a₁ a₂ : α} : (a₁ ⟹ a₂ = ⊤) ↔ a₁ ≤ a₂ :=
begin
 split; intro H,
  {have : a₁ ⊓ a₂ = a₁, from
    calc a₁ ⊓ a₂ = ⊥ ⊔ (a₁ ⊓ a₂) : by simp
             ... = (a₁ ⊓ - a₁) ⊔ (a₁ ⊓ a₂) : by simp
             ... = a₁ ⊓ (- a₁ ⊔ a₂) : by {rw[inf_sup_left]}
             ... = a₁ ⊓ ⊤ : by {rw[<-H], refl}
             ... = a₁ : by {simp},
   finish},
 {have : a₁ ⊓ a₂ = a₁, from inf_eq_of_le H, apply top_unique,
  have this' : ⊤ = - a₁ ⊔ a₁, by rw[lattice.neg_sup_eq_top],
  rw[this', <-this, imp], simp only [lattice.neg_inf, lattice.sup_le_iff],
  repeat{split},
    suffices : (- a₁ ≤ - a₁ ⊔ - a₂ ⊔ a₂) = (- a₁ ≤ - a₁ ⊔ (- a₂ ⊔ a₂)),
      by rw[this]; apply le_sup_left, ac_refl,
    suffices : (-a₂ ≤ -a₁ ⊔ -a₂ ⊔ a₂) = (- a₂ ≤ - a₂ ⊔ (-a₁ ⊔ a₂)),
      by rw[this]; apply le_sup_left, ac_refl,
    suffices : - a₁ ⊔ - a₂ ⊔ a₂ = ⊤,
      by rw[this]; simp, apply top_unique,
      suffices : - a₁ ⊔ - a₂ ⊔ a₂ = - a₁ ⊔ (- a₂ ⊔ a₂),
        by simp[this], ac_refl}
end

/- ∀ {α : Type u_1} [_inst_1 : boolean_algebra α] {a₁ a₂ : α}, a₁ ⟹ a₂ = ⊤ ↔ a₁ ≤ a₂ -/

lemma curry_uncurry {α : Type*} [boolean_algebra α] {a b c : α} : ((a ⊓ b) ⟹ c) = (a ⟹ (b ⟹ c)) :=
  by simp[imp]; ac_refl

/-- the actual deduction theorem in β, thinking of ≤ as a turnstile -/
@[ematch]lemma deduction {α : Type*} [boolean_algebra α] {a b c : α} : a ⊓ b ≤ c ↔ a ≤ (b ⟹ c) :=
  by {[smt] eblast_using [curry_uncurry, imp_top_iff_le]}

lemma deduction_simp {α : Type*} [boolean_algebra α] {a b c : α} : a ≤ (b ⟹ c) ↔ a ⊓ b ≤ c := deduction.symm

lemma imp_top {α : Type*} [complete_boolean_algebra α] (a : α) : a ≤ a ⟹ ⊤ :=
by {rw[<-deduction]; simp}

/-- Given an η : option α → β, where β is a complete lattice, we have that the supremum of η
    is equal to (η none) ⊔ ⨆(a:α) η (some a)-/
@[simp]lemma supr_option {α β : Type*} [complete_lattice β] {η : option α → β} : (⨆(x : option α), η x) = (η none) ⊔ ⨆(a : α), η (some a) :=
begin
  apply le_antisymm, tidy, cases i, apply le_sup_left,
  apply le_sup_right_of_le, apply le_supr (λ x, η (some x)) i, apply le_supr, apply le_supr
end

/-- Given an η : option α → β, where β is a complete lattice, we have that the infimum of η
    is equal to (η none) ⊓ ⨅(a:α) η (some a)-/
@[simp]lemma infi_option {α β : Type*} [complete_lattice β] {η : option α → β} : (⨅(x : option α), η x) = (η none) ⊓ ⨅(a : α), η (some a) :=
begin
  apply le_antisymm, tidy, tactic.rotate 2, cases i, apply inf_le_left,
  apply inf_le_right_of_le, apply infi_le (λ x, η (some x)) i, apply infi_le, apply infi_le
end

lemma supr_option' {α β : Type*} [complete_lattice β] {η : α → β} {b : β} : (⨆(x : option α), (option.rec b η x : β) : β) = b ⊔ ⨆(a : α), η a :=
  by rw[supr_option]

lemma infi_option' {α β : Type*} [complete_lattice β] {η : α → β} {b : β} : (⨅(x : option α), (option.rec b η x : β) : β) = b ⊓ ⨅(a : α), η a :=
  by rw[infi_option]

/-- Let A : α → β such that b = ⨆(a : α) A a. Let c < b. If, for all a : α, A a ≠ b → A a ≤ c,
then there exists some x : α such that A x = b. -/
lemma supr_max_of_bounded {α β : Type*} [complete_lattice β] {A : α → β} {b c : β}
{h : b = ⨆(a:α), A a} {h_lt : c < b} {h_bounded : ∀ a : α, A a ≠ b → A a ≤ c} :
  ∃ x : α, A x = b :=
begin
  haveI : decidable ∃ (x : α), A x = b := by apply classical.prop_decidable,
  by_contra, rw[h] at a, simp at a,
  suffices : b ≤ c, by {suffices : c < c, by {exfalso, have this' := lt_irrefl,
  show Type*, exact β, show preorder (id β), by {dsimp, apply_instance}, exact this' c this},
  exact lt_of_lt_of_le h_lt this},
  rw[h], apply supr_le, intro a', from h_bounded a' (by convert a a')
end

lemma supr_max_of_bounded' {α β : Type*} [complete_lattice β] {A : α → β} {b c : β}
{h : b ≤ ⨆(a:α), A a} {h_lt : c < b} {h_bounded : ∀ a : α, (¬ b ≤ A a) → A a ≤ c} :
  ∃ x : α, b ≤ A x :=
begin
  haveI : decidable ∃ (x : α), b ≤ A x := by apply classical.prop_decidable,
  by_contra, simp at a,
  suffices : b ≤ c, by {suffices : c < c, by {exfalso, have this' := lt_irrefl,
  show Type*, exact β, show preorder (id β), by {dsimp, apply_instance}, exact this' c this},
  exact lt_of_lt_of_le h_lt this},
  apply le_trans h, apply supr_le, intro a', from h_bounded a' (a a')
end

/-- As a consequence of the previous lemma, if ⨆(a : α), A a = ⊤ such that whenever A a ≠ ⊤ → A α = ⊥, there exists some x : α such that A x = ⊤. -/
lemma supr_eq_top_max {α β : Type*} [complete_lattice β] {A : α → β} {h_nondeg : ⊥ < (⊤ : β)}
{h_top : (⨆(a : α), A a) = ⊤} {h_bounded : ∀ a : α, A a ≠ ⊤ → A a = ⊥} : ∃ x : α, A x = ⊤ :=
  by {apply supr_max_of_bounded, cc, exact h_nondeg, tidy}

lemma supr_eq_Gamma_max {α β : Type*} [complete_lattice β] {A : α → β} {Γ : β} {h_nonzero : ⊥ < Γ}
{h_Γ : Γ ≤ (⨆a, A a)} {h_bounded : ∀ a, (¬ Γ ≤ A a) → A a = ⊥} : ∃ x : α, Γ ≤ A x :=
begin
  apply supr_max_of_bounded', from ‹_›, from ‹_›, intros a H,
  specialize h_bounded a ‹_›, rwa[le_bot_iff]
end

/-- "eoc" means the opposite of "coe", of course -/
lemma eoc_supr {ι β : Type*} {s : ι → β} [complete_lattice β] {X : set ι} :
  (⨆(i : X), s i) = ⨆(i ∈ X), s i :=
begin
  apply le_antisymm; repeat{apply supr_le; intro},
  apply le_supr_of_le i.val, apply le_supr_of_le, exact i.property, refl,
  apply le_supr_of_le, swap, use i, assumption, refl
end

/- Can reindex sup over all sets -/
lemma supr_all_sets {ι β : Type*} {s : ι → β} [complete_lattice β] :
  (⨆(i:ι), s i) = ⨆(X : set ι), (⨆(x : X), s x) :=
begin
  apply le_antisymm,
    {apply supr_le, intro i, apply le_supr_of_le {i}, apply le_supr_of_le, swap,
     use i, from set.mem_singleton i, simp},
    {apply supr_le, intro X, apply supr_le, intro i, apply le_supr}
end

lemma supr_all_sets' {ι β : Type*} {s : ι → β} [complete_lattice β] :
  (⨆(i:ι), s i) = ⨆(X : set ι), (⨆(x ∈ X), s x) :=
by {convert supr_all_sets using 1, simp[eoc_supr]}

-- `b ≤ ⨆(i:ι) c i` if there exists an s : set ι such that b ≤ ⨆ (i : s), c s
lemma le_supr_of_le' {ι β : Type*} {s : ι → β} {b : β} [complete_lattice β]
  (H : ∃ X : set ι, b ≤ ⨆(x:X), s x) : b ≤ ⨆(i:ι), s i :=
begin
  rcases H with ⟨X, H_X⟩, apply le_trans H_X,
  conv{to_rhs, rw[supr_all_sets]},
  from le_supr_of_le X (by refl)
end

lemma le_supr_of_le'' {ι β : Type*} {s : ι → β} {b : β} [complete_lattice β]
  (H : ∃ X : set ι, b ≤ ⨆(x ∈ X), s x) : b ≤ ⨆(i:ι), s i :=
by {apply le_supr_of_le', convert H using 1, simp[eoc_supr]}

lemma infi_congr {ι β : Type*} {s₁ s₂ : ι → β} [complete_lattice β] {h : ∀ i : ι, s₁ i = s₂ i} :
  (⨅(i:ι), s₁ i) = ⨅(i:ι), s₂ i :=
by simp*

lemma imp_iff {β : Type*} {a b : β} [complete_boolean_algebra β] : a ⟹ b = -a ⊔ b := by refl

lemma sup_inf_left_right_eq {β} [distrib_lattice β] {a b c d : β} :
  (a ⊓ b) ⊔ (c ⊓ d) = (a ⊔ c) ⊓ (a ⊔ d) ⊓ (b ⊔ c) ⊓ (b ⊔ d) :=
by {rw[sup_inf_right, sup_inf_left, sup_inf_left]; ac_refl}

lemma inf_sup_right_left_eq {β} [distrib_lattice β] {a b c d : β} :
  (a ⊔ b) ⊓ (c ⊔ d) = (a ⊓ c) ⊔ (a ⊓ d) ⊔ (b ⊓ c) ⊔ (b ⊓ d) :=
by {rw[inf_sup_right, inf_sup_left, inf_sup_left], ac_refl}

-- by {[smt] eblast_using[sup_inf_right, sup_inf_left]}
-- interesting, this takes like 5 seconds
-- probably because both of those rules can be applied pretty much everywhere in the goal
-- and eblast is trying all of them

lemma eq_neg_of_partition {β} [boolean_algebra β] {a₁ a₂ : β} (h_anti : a₁ ⊓ a₂ = ⊥) (h_partition : a₁ ⊔ a₂ = ⊤) :
  a₂ = - a₁ :=
begin
  rw[show -a₁ = ⊤ ⊓ -a₁, by simp], rw[<-sub_eq],
  rw[<-h_partition,sub_eq], rw[inf_sup_right],
  simp*, rw[<-sub_eq], rw[inf_comm] at h_anti,
  from (sub_eq_left h_anti).symm
end

lemma le_trans' {β} [lattice β] {a₁ a₂ a₃ : β} (h₁ : a₁ ≤ a₂) {h₂ : a₁ ⊓ a₂ ≤ a₃} : a₁ ≤ a₃ :=
begin
  suffices : a₁ ≤ a₁ ⊓ a₂, from le_trans this ‹_›,
  rw[show a₁ = a₁ ⊓ a₁, by simp], conv {to_rhs, rw[inf_assoc]},
  apply inf_le_inf, refl, apply le_inf, refl, assumption
end

@[simp]lemma top_le_imp_top {β : Type*} {b : β} [boolean_algebra β] : ⊤ ≤ b ⟹ ⊤ :=
by rw[<-deduction]; apply le_top

lemma poset_yoneda {β : Type*} [partial_order β] {a b : β} (H : ∀ Γ : β, Γ ≤ a → Γ ≤ b) : a ≤ b :=
by specialize H a; finish

lemma poset_yoneda_inv {β : Type*} [partial_order β] {a b : β} (Γ : β) (H : a ≤ b) :
  Γ ≤ a → Γ ≤ b := λ _, le_trans ‹_› ‹_›

lemma split_context {β : Type*} [lattice β] {a₁ a₂ b : β} {H : ∀ Γ : β, Γ ≤ a₁ ∧ Γ ≤ a₂ → Γ ≤ b} : a₁ ⊓ a₂ ≤ b :=
by {apply poset_yoneda, intros Γ H', apply H, finish}

example {β : Type*} [bounded_lattice β] : ⊤ ⊓ (⊤ : β) ⊓ ⊤ ≤ ⊤ :=
begin
  apply split_context, intros, simp only [le_inf_iff] at a, auto.split_hyps, from ‹_›
end

lemma context_Or_elim {β : Type*} [complete_boolean_algebra β] {ι : Type*} {s : ι → β} {Γ b : β}
  (h : Γ ≤ ⨆(i:ι), s i) {h' : ∀ i, s i ⊓ Γ ≤ s i → s i ⊓ Γ ≤ b} : Γ ≤ b :=
begin
  apply le_trans' h, rw[inf_comm], rw[deduction], apply supr_le, intro i, rw[<-deduction],
  specialize h' i, apply h', apply inf_le_left
end

lemma context_or_elim {β : Type*} [complete_boolean_algebra β] {Γ a₁ a₂ b : β}
  (H : Γ ≤ a₁ ⊔ a₂) {H₁ : a₁ ⊓ Γ ≤ a₁ → a₁ ⊓ Γ ≤ b} {H₂ : a₂ ⊓ Γ ≤ a₂ → a₂ ⊓ Γ ≤ b} : Γ ≤ b :=
begin
  apply le_trans' H, rw[inf_comm], rw[deduction], apply sup_le; rw[<-deduction];
  [apply H₁, apply H₂]; from inf_le_left
end

lemma context_and_intro {β : Type*} [lattice β] {Γ} {a₁ a₂ : β}
  (H₁ : Γ ≤ a₁) (H₂ : Γ ≤ a₂) : Γ ≤ a₁ ⊓ a₂ := le_inf ‹_› ‹_›

lemma specialize_context {β : Type*} [partial_order β] {Γ b : β} (Γ' : β) {H_le : Γ' ≤ Γ} (H : Γ ≤ b)
  : Γ' ≤ b :=
le_trans H_le H

lemma context_specialize_aux {β : Type*} [complete_boolean_algebra β] {ι : Type*} {s : ι → β}
  (j : ι) {Γ : β} {H : Γ ≤ (⨅ i, s i)} : Γ ≤ (⨅i, s i) ⟹ s j :=
by {apply le_trans H, rw[<-deduction], apply inf_le_right_of_le, apply infi_le}

lemma context_specialize {β : Type*} [complete_lattice β] {ι : Type*} {s : ι → β}
  {Γ : β} (H : Γ ≤ (⨅ i, s i)) (j : ι) : Γ ≤ s j :=
le_trans H (infi_le _ _)

lemma context_specialize_strict {β : Type*} [complete_lattice β] {ι : Type*} {s : ι → β}
  {Γ : β} (H : Γ < (⨅ i, s i)) (j : ι) : Γ < s j :=
begin
  apply lt_iff_le_and_ne.mpr, split, from le_trans (le_of_lt H) (infi_le _ _),
  intro H', apply @lt_irrefl β _ _, show β, from (⨅ i, s i),
  apply lt_of_le_of_lt, show β, from Γ, rw[H'], apply infi_le, from ‹_›
end

lemma context_split_inf_left {β : Type*} [complete_lattice β] {a₁ a₂ Γ: β} (H : Γ ≤ a₁ ⊓ a₂) : Γ ≤ a₁ :=
by {rw[le_inf_iff] at H, finish}

lemma context_split_inf_right {β : Type*} [complete_lattice β] {a₁ a₂ Γ: β} (H : Γ ≤ a₁ ⊓ a₂) :
  Γ ≤ a₂ :=
by {rw[le_inf_iff] at H, finish}

lemma context_imp_elim {β : Type*} [complete_boolean_algebra β] {a b Γ: β} (H₁ : Γ ≤ a ⟹ b) (H₂ : Γ ≤ a) : Γ ≤ b :=
begin
  apply le_trans' H₁, apply le_trans, apply inf_le_inf H₂, refl,
  rw[inf_comm], simp[imp, inf_sup_right]
end

lemma context_imp_intro {β : Type*} [complete_boolean_algebra β] {a b Γ : β} (H : a ⊓ Γ ≤ a → a ⊓ Γ ≤ b) : Γ ≤ a ⟹ b :=
by {rw[<-deduction, inf_comm], from H (inf_le_left)}

instance imp_to_pi {β : Type*} [complete_boolean_algebra β] {Γ a b : β} : has_coe_to_fun (Γ ≤ a ⟹ b) :=
{ F := λ x, Γ ≤ a → Γ ≤ b,
  coe := λ H₁ H₂, by {apply context_imp_elim; from ‹_›}}

instance infi_to_pi {ι β : Type*} [complete_boolean_algebra β] {Γ : β} {ϕ : ι → β} : has_coe_to_fun (Γ ≤ infi ϕ) :=
{ F := λ x, Π i : ι, Γ ≤ ϕ i,
  coe := λ H₁ i, by {change Γ ≤ ϕ i, change Γ ≤ _ at H₁, finish}}

lemma bv_em {β : Type*} [boolean_algebra β] (Γ) (b : β) :
  Γ ≤ b ⊔ -b := by simp

lemma neg_imp {β : Type*} [boolean_algebra β] {a b : β} : -(a ⟹ b) = a ⊓ (-b) :=
by simp[imp]

lemma bot_lt_iff_not_le_bot {α} [bounded_lattice α] {a : α} : ⊥ < a ↔ (¬ a ≤ ⊥) :=
begin
  rw[le_bot_iff],
  split; intro,
    from bot_lt_iff_ne_bot.mp ‹_›,
  from bot_lt_iff_ne_bot.mpr ‹_›
end

lemma nonzero_wit {β : Type*} [complete_lattice β] {ι : Type*} {s : ι → β} :
  (⊥ < (⨆i, s i)) → ∃ j, (⊥ < s j) :=
begin
  intro H, have := bot_lt_iff_not_le_bot.mp ‹_›,
  haveI : decidable (∃ (j : ι), ⊥ < s j) := classical.prop_decidable _,
  by_contra, apply this, apply supr_le, intro i, rw[not_exists] at a,
  specialize a i, haveI : decidable (s i ≤ ⊥) := classical.prop_decidable _,
  by_contra, have := @bot_lt_iff_not_le_bot β _ (s i), tauto
end

def CCC (𝔹 : Type u) [boolean_algebra 𝔹] : Prop :=
  ∀ ι : Type u, ∀ 𝓐 : ι → 𝔹, (∀ i, ⊥ < 𝓐 i) →
    (∀ i j, i ≠ j → 𝓐 i ⊓ 𝓐 j ≤ ⊥) → (cardinal.mk ι) ≤ cardinal.omega

end lattice

namespace tactic
namespace interactive
section natded_tactics
open tactic interactive tactic.tidy
open lean.parser lean interactive.types

local postfix `?`:9001 := optional
meta def bv_intro : parse ident_? → tactic unit
| none := propagate_tags (`[refine lattice.le_infi _] >> intro1 >> tactic.skip)
| (some n) := propagate_tags (`[refine lattice.le_infi _] >> tactic.intro n >> tactic.skip)

meta def get_name : ∀(e : expr), name
| (expr.const c [])          := c
| (expr.local_const _ c _ _) := c
| _                          := name.anonymous

meta def lhs_rhs_of_le (e : expr) : tactic (expr × expr) :=
do `(%%x ≤ %%y) <- pure e,
   return (x,y)

meta def lhs_of_le (e : expr) : tactic expr :=
lhs_rhs_of_le e >>= λ x, return x.1

meta def rhs_of_le (e : expr) : tactic expr :=
lhs_rhs_of_le e >>= λ x, return x.2

-- meta def lhs_of_le (e : expr) : tactic expr :=
-- do v_a <- mk_mvar,
--    e' <- to_expr ``(%%v_a ≤ _),
--    unify e e',
--    return v_a

meta def hyp_is_ineq (e : expr) : tactic bool :=
  (do `(%%x ≤ %%y) <- infer_type e,
     return tt)<|> return ff

meta def trace_inequalities : tactic unit :=
  (local_context >>= λ l, l.mfilter (hyp_is_ineq)) >>= trace

meta def hyp_is_ineq_sup (e : expr) : tactic bool :=
  (do `(%%x ≤ %%y ⊔ %%z) <- infer_type e,
     return tt)<|> return ff

meta def trace_sup_inequalities : tactic unit :=
  (local_context >>= λ l, l.mfilter (hyp_is_ineq_sup)) >>= trace

meta def specialize_context_at (H : parse ident) (Γ : parse texpr) : tactic unit :=
do e <- resolve_name H,
   tactic.replace H ``(lattice.specialize_context %%Γ %%e),
   swap >> try `[refine lattice.le_top] >> skip

meta def specialize_context_core (Γ_old : expr) : tactic unit :=
do  v_a <- target >>= lhs_of_le,
    tp <- infer_type Γ_old,
    Γ_name <- get_unused_name "Γ",
    v <- mk_mvar, v' <- mk_mvar,
    Γ_new <- pose Γ_name none v,

    new_goal <- to_expr ``((%%Γ_new : %%tp) ≤ %%v'),
    tactic.change new_goal,
    ctx <- local_context,
    ctx' <- ctx.mfilter
      (λ e, (do infer_type e >>= lhs_of_le >>= λ e', succeeds $ is_def_eq Γ_old e') <|> return ff),
      ctx'.mmap' (λ H, tactic.replace (get_name H) ``(le_trans (by apply inf_le_right <|> simp : %%Γ_new ≤ _) %%H)),
    ctx2 <- local_context,
    ctx2' <- ctx.mfilter (λ e, (do infer_type e >>= lhs_of_le >>= instantiate_mvars >>= λ e', succeeds $ is_def_eq Γ_new e') <|> return ff),
    -- trace ctx2',
    ctx2'.mmap' (λ H, do H_tp <- infer_type H,
                         e'' <- lhs_of_le H_tp,
                         succeeds (unify Γ_new e'') >>
                   tactic.replace (get_name H) ``(_ : %%Γ_new ≤ _) >> swap >> assumption)


/-- If the goal is an inequality `a ≤ b`, extracts `a` and attempts to specialize all
  facts in context of the form `Γ ≤ d` to `a ≤ d` (this requires a ≤ Γ) -/
meta def specialize_context (Γ : parse texpr) : tactic unit :=
do
  Γ_old <- i_to_expr Γ,
  specialize_context_core Γ_old

example {β : Type u} [lattice.bounded_lattice β] {a b : β} {H : ⊤ ≤ b} : a ≤ b :=
by {specialize_context (⊤ : β), assumption}

meta def bv_exfalso : tactic unit :=
  `[refine le_trans _ (bot_le)]

meta def bv_cases_at (H : parse ident) (i : parse ident_)  : tactic unit :=
do
  e₀ <- resolve_name H,
  e₀' <- to_expr e₀,
  Γ_old <- target >>= lhs_of_le,
  `[refine lattice.context_Or_elim %%e₀'],
  tactic.intro i >> ((get_unused_name H) >>= tactic.intro) >>
  specialize_context_core Γ_old

meta def bv_cases_at' (H : parse ident) (i : parse ident_)  : tactic unit :=
do
  e₀ <- resolve_name H,
  e₀' <- to_expr e₀,
  Γ_old <- target >>= lhs_of_le,
  `[refine lattice.context_Or_elim %%e₀'],
  tactic.intro i >> ((get_unused_name H) >>= tactic.intro) >>
  skip

meta def bv_or_elim_at_core (e : expr) (Γ_old : expr) : tactic unit :=
do
   n <- get_unused_name "H_left",
   n' <- get_unused_name "H_right",
   `[apply lattice.context_or_elim %%e],
   (tactic.intro n) >> specialize_context_core Γ_old, swap,
   (tactic.intro n') >> specialize_context_core Γ_old, swap


meta def bv_or_elim_at (H : parse ident) : tactic unit :=
do Γ_old <- target >>= lhs_of_le,
   e <- resolve_name H >>= to_expr,
   bv_or_elim_at_core e Γ_old

meta def auto_or_elim_step : tactic unit :=
do  ctx <- local_context >>= (λ l, l.mfilter hyp_is_ineq_sup),
    if ctx.length > 0 then
    ctx.mmap' (λ e, do Γ_old <- target >>= lhs_of_le, bv_or_elim_at_core e Γ_old)
    else tactic.failed

meta def auto_or_elim : tactic unit := tactic.repeat auto_or_elim_step --TODO(jesse) debug this

-- example {β ι : Type u} [lattice.complete_boolean_algebra β] {s : ι → β} {H' : ⊤ ≤ ⨆i, s i} {b : β} : b ≤ ⊤ :=
-- by {specialize_context ⊤, bv_cases_at H' i, specialize_context Γ, sorry }

def eta_beta_cfg : dsimp_config :=
{ md := reducible,
  max_steps := simp.default_max_steps,
  canonize_instances := tt,
  single_pass := ff,
  fail_if_unchanged := ff,
  eta := tt,
  zeta := ff,
  beta := tt,
  proj := ff,
  iota := ff,
  unfold_reducible := ff,
  memoize := tt }

meta def bv_specialize_at (H : parse ident) (j : parse texpr) : tactic unit :=
do n <- get_unused_name H,
   e_H <- resolve_name H,
   e <- to_expr ``(lattice.context_specialize %%e_H %%j),
   note n none e >>= λ h, dsimp_hyp h none [] eta_beta_cfg

meta def bv_to_pi (H : parse ident) : tactic unit :=
do   e_H <- resolve_name H,
     e_rhs <- to_expr e_H >>= infer_type >>= rhs_of_le,
     (tactic.replace H  ``(lattice.context_specialize %%e_H) <|>
     tactic.replace H ``(lattice.context_imp_elim %%e_H)) <|>
     tactic.fail "target is not a ⨅ or an ⟹"

meta def bv_to_pi' : tactic unit :=
do ctx <- (local_context >>= (λ l, l.mfilter hyp_is_ineq)),
   ctx.mmap' (λ e, try ((tactic.replace (get_name e)  ``(lattice.context_specialize %%e) <|>
     tactic.replace (get_name e) ``(lattice.context_imp_elim %%e))))

meta def bv_split_at (H : parse ident) : tactic unit :=
do n₁ <- get_unused_name H,
   n₂ <- get_unused_name H,
   e_H <- resolve_name H,
   e <- to_expr ``(lattice.context_split_inf_left %%e_H),
   note n₁ none e >>= λ h, dsimp_hyp h none [] eta_beta_cfg,
   e <- to_expr ``(lattice.context_split_inf_right %%e_H),
   note n₂ none e >>= λ h, dsimp_hyp h none [] eta_beta_cfg

meta def bv_split : tactic unit :=
do ctx <- (local_context >>= (λ l, l.mfilter hyp_is_ineq)),
   ctx.mmap' (λ e, try (tactic.replace (get_name e) ``(lattice.le_inf_iff.mp %%e))),
   auto_cases >> skip

meta def bv_and_intro (H₁ H₂ : parse ident) : tactic unit :=
do
  H₁ <- resolve_name H₁,
  H₂ <- resolve_name H₂,
  e <- to_expr ``(lattice.context_and_intro %%H₁ %%H₂),
   n <- get_unused_name "H",
   note n none e >> skip

-- example {β ι : Type u} [lattice.complete_boolean_algebra β] {j : ι} {s : ι → β} {H : ⊤ ≤ ⨅i, s i} {b : β} : b ≤ ⊤ :=
-- by {specialize_context ⊤, bv_specialize_at H j, apply lattice.le_top, apply_instance}

meta def bv_imp_elim_at (H₁ : parse ident) (H₂ : parse texpr) : tactic unit :=
do n <- get_unused_name "H",
   e₁ <- resolve_name H₁,
   e <- to_expr ``(lattice.context_imp_elim %%e₁ %%H₂),
   note n none e >>= λ h, dsimp_hyp h none [] eta_beta_cfg

meta def bv_mp (H : parse ident) (H₂ : parse texpr) : tactic unit :=
do
   n <- get_unused_name H,
   e_H <- resolve_name H,
   e_L <- to_expr H₂,
   pr <- to_expr ``(le_trans %%e_H %%e_L),
   note n none pr >>= λ h, dsimp_hyp h none [] eta_beta_cfg

meta def bv_imp_intro : tactic unit :=
do Γ_old <- target >>= lhs_of_le,
  `[refine lattice.context_imp_intro _] >> (get_unused_name "H" >>= tactic.intro) >> skip,
  specialize_context_core Γ_old

/-- `ac_change g' changes the current goal `tgt` to `g` by creating a new goal of the form
  `tgt = g`, and will attempt close it with `ac_refl`. -/
meta def ac_change (r : parse texpr) : tactic unit :=
do
   v₁ <- mk_mvar,
   v₂ <- mk_mvar,
   refine ``(eq.mpr %%v₁ (%%v₂ : %%r)),
   gs <- get_goals,
   set_goals (list.cons v₁ list.nil),
   ac_refl <|> tactic.try `[simp only [bv_eq_symm]],
   -- TODO generalize the right branch to an is_symmetric typeclass
   gs' <- get_goals,
   set_goals $ gs' ++ gs

-- example {α : Type*} [lattice.boolean_algebra α] {a₁ a₂ a₃ a₄ : α} :
--   (a₁ ⊔ a₂) ⊔ (a₃ ⊔ a₄) = ⊤
-- :=
-- begin
--   ac_change a₁ ⊔ (a₂ ⊔ a₃ ⊔ a₄) = ⊤,
-- -- α : Type ?,
-- -- _inst_1 : lattice.boolean_algebra α,
-- -- a₁ a₂ a₃ a₄ : α
-- -- ⊢ a₁ ⊔ (a₂ ⊔ a₃ ⊔ a₄) = ⊤
-- end



meta def tidy_context_tactics : list (tactic string) :=
[ reflexivity                                 >> pure "refl",
  propositional_goal >> assumption            >> pure "assumption",
  intros1                                     >>= λ ns, pure ("intros " ++ (" ".intercalate (ns.map (λ e, e.to_string)))),
  auto_cases,
  `[simp only [le_inf_iff] at *]                                >> pure "simp only [le_inf_iff] at *",
  propositional_goal >> (`[solve_by_elim])    >> pure "solve_by_elim"
]

meta def tidy_split_goals_tactics : list (tactic string) :=
[ reflexivity >> pure "refl",
 propositional_goal >> assumption >> pure "assumption",
  propositional_goal >> (`[solve_by_elim])    >> pure "solve_by_elim",
  `[refine lattice.le_inf _ _] >> pure "refine lattice.le_inf _ _",
  `[rw[bSet.bv_eq_symm]] >> assumption >> pure "rw[bSet.bv_eq_symm], assumption",
   bv_intro none >> pure "bv_intro"
]

meta def bv_split_goal (trace : parse $ optional (tk "?")) : tactic unit :=
  tidy {trace_result := trace.is_some, tactics := tidy_split_goals_tactics}

meta structure context_cfg :=
(trace_result : bool := ff)
(trace_result_prefix : string := "/- `tidy_context` says -/ apply poset_yoneda, ")
(tactics : list(tactic string) := tidy_context_tactics)

meta def cfg_of_context_cfg : context_cfg → cfg :=
λ X, { trace_result := X.trace_result,
  trace_result_prefix := X.trace_result_prefix,
  tactics := X.tactics}

meta def tidy_context (cfg : context_cfg := {}) : tactic unit :=
`[apply poset_yoneda] >> tidy (cfg_of_context_cfg cfg)

end natded_tactics
end interactive
end tactic

namespace lattice
example {β : Type*} [bounded_lattice β] : ⊤ ⊓ (⊤ : β) ⊓ ⊤ ≤ ⊤ :=
begin
  tidy_context -- {trace_result := tt},
--/- `tidy_context` says -/ apply poset_yoneda, intros Γ a, simp only [le_inf_iff] at *, cases a, assumption
-- not bad!
end

end lattice

noncomputable theory
section
variables {α : Type u} {r : α → α → Prop}
def decidable_linear_order_of_is_well_order (r : α → α → Prop) [is_well_order α r] :
  decidable_linear_order α :=
by { haveI := linear_order_of_STO' r, exact classical.DLO α }

lemma trans_trichotomous_left [is_trans α r] [is_trichotomous α r] {a b c : α} :
  ¬r b a → r b c → r a c :=
begin
  intros h₁ h₂, rcases trichotomous_of r a b with h₃|h₃|h₃,
  exact trans h₃ h₂, rw h₃, exact h₂, exfalso, exact h₁ h₃
end

lemma trans_trichotomous_right [is_trans α r] [is_trichotomous α r] {a b c : α} :
  r a b → ¬r c b → r a c :=
begin
  intros h₁ h₂, rcases trichotomous_of r b c with h₃|h₃|h₃,
  exact trans h₁ h₃, rw ←h₃, exact h₁, exfalso, exact h₂ h₃
end

end



