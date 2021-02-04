(*
Copyright 2021 DeepMind Technologies Limited.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*)

open HolKernel boolLib bossLib Parse dep_rewrite
  pairTheory optionTheory pred_setTheory categoryTheory
  cf0Theory cf1Theory cf2Theory cf4Theory cf8Theory cf9Theory cfaTheory

val _ = new_theory"cfb";

(* TODO: move *)

Theorem external_eval:
  (external v c).eval a e =
  if a ∈ (external v c).agent ∧ e ∈ (external v c).env then
    c.eval (decode_function a (FST (decode_pair e)))
      (SND (decode_pair e))
  else ARB
Proof
  rw[external_def, cf_external_def, mk_cf_def]
QED

(* -- *)

(* TODO:  three-digit number example *)

Definition obs_part_after_def:
  obs_part_after c t v ⇔ v ∈ obs_part (external t c)
End

Definition refines_def:
  refines v1 v2 ⇔
  ∀s1. s1 ∈ v1 ⇒ ∃s2. s2 ∈ v2 ∧ s1 ⊆ s2
End

Definition nested_partitions_def:
  nested_partitions w ts ⇔
  ts ≠ [] ∧
  HD ts = {w} ∧
  LAST ts = IMAGE (flip $INSERT EMPTY) w ∧
  EVERY (flip partitions w) ts ∧
  ∀n. (SUC n < LENGTH ts) ⇒
    refines (EL (SUC n) ts) (EL n ts)
End

Theorem refines_fn_part_eq:
  partitions v w ∧ partitions u w ∧ refines u v ∧
  (∀a e. a ∈ s ∧ e ∈ t ⇒ f a e ∈ w) ∧ a ∈ s ∧ b ∈ s ∧
  fn_part s t f u a = fn_part s t f u b
  ⇒
  fn_part s t f v a = fn_part s t f v b
Proof
  qho_match_abbrev_tac`P a b ⇒ X a = X b`
  \\ `∀a b. P a b ⇒ X a ⊆ X b` suffices_by metis_tac[SET_EQ_SUBSET]
  \\ rw[Abbr`P`, Abbr`X`, SET_EQ_SUBSET]
  \\ fs[fn_part_def, SUBSET_DEF]
  \\ rw[]
  \\ first_x_assum drule
  \\ disch_then (SUBST1_TAC o SYM)
  \\ first_x_assum (qspec_then`b`mp_tac)
  \\ impl_tac >- simp[]
  \\ disch_then drule
  \\ strip_tac
  \\ fs[refines_def, partitions_thm]
  \\ pop_assum mp_tac
  \\ SELECT_ELIM_TAC
  \\ conj_tac >- metis_tac[EXISTS_UNIQUE_THM]
  \\ qx_gen_tac`sua` \\ strip_tac
  \\ SELECT_ELIM_TAC
  \\ conj_tac >- metis_tac[EXISTS_UNIQUE_THM]
  \\ qx_gen_tac`sub` \\ strip_tac
  \\ strip_tac
  \\ `∃sv. sv ∈ v ∧ sua ⊆ sv` by metis_tac[]
  \\ `f a y ∈ sv ∧ f b y ∈ sv` by metis_tac[SUBSET_DEF]
  \\ metis_tac[EXISTS_UNIQUE_ALT]
QED

Theorem refines_fn_part_SUBSET:
  refines u v ∧ partitions v w ∧ partitions u w ∧ a ∈ s ∧
  (∀a e. a ∈ s ∧ e ∈ t ⇒ f a e ∈ w)
  ⇒
  fn_part s t f u a ⊆ fn_part s t f v a
Proof
  rw[fn_part_def, SUBSET_DEF]
  \\ first_x_assum drule
  \\ SELECT_ELIM_TAC
  \\ fs[refines_def, partitions_thm]
  \\ conj_tac >- metis_tac[EXISTS_UNIQUE_THM]
  \\ SELECT_ELIM_TAC
  \\ conj_tac >- metis_tac[EXISTS_UNIQUE_THM]
  \\ qx_gen_tac`su` \\ strip_tac
  \\ strip_tac
  \\ SELECT_ELIM_TAC \\ conj_tac >- metis_tac[]
  \\ qx_gen_tac`sv` \\ strip_tac
  \\ SELECT_ELIM_TAC \\ conj_tac >- metis_tac[]
  \\ fs[SUBSET_DEF, PULL_EXISTS]
  \\ metis_tac[EXISTS_UNIQUE_ALT]
QED

Theorem refines_multiplicative_subagent:
  c ∈ chu_objects w ∧
  partitions v w ∧ partitions u w ∧ refines u v
  ⇒
  multiplicative_subagent (external u c) (external v c)
Proof
  rw[multiplicative_subagent_externalising]
  \\ qexists_tac`(external u c).agent`
  \\ qabbrev_tac`b = fn_partition c.agent c.env c.eval`
  \\ `∃b'. (∀fp. fp ∈ b u ⇒ b' fp ∈ b v) ∧
           (∀a. a ∈ c.agent ⇒
                b' (fn_part c.agent c.env c.eval u a) =
                fn_part c.agent c.env c.eval v a)`
  by (
    qexists_tac`λfp. fn_part c.agent c.env c.eval v
      (@a. a ∈ c.agent ∧ fp = fn_part c.agent c.env c.eval u a)`
    \\ simp[]
    \\ conj_tac
    >- (
      simp[Abbr`b`, fn_partition_def, PULL_EXISTS]
      \\ metis_tac[] )
    \\ rw[]
    \\ SELECT_ELIM_TAC
    \\ conj_tac >- metis_tac[]
    \\ rw[]
    \\ irule refines_fn_part_eq
    \\ metis_tac[in_chu_objects, wf_def] )
  \\ imp_res_tac in_chu_objects_finite_world
  \\ imp_res_tac partitions_FINITE
  \\ `FINITE c.agent` by metis_tac[in_chu_objects, wf_def, finite_cf_def]
  \\ `FINITE (b u) ∧ FINITE (b v) ∧ EVERY_FINITE (b u) ∧ EVERY_FINITE (b v)`
  by ( simp[Abbr`b`] \\ metis_tac[FINITE_fn_partition] )
  \\ qabbrev_tac`ys = { encode_function (IMAGE encode_set (b v))
                        (restrict (encode_set o y o decode_set)
                          (IMAGE encode_set (b v))) |
       y | extensional y (b v) ∧ IMAGE y (b v) ⊆ b u ∧
           (∀fp. fp ∈ b v ⇒ b' (y fp) = fp) }`
  \\ qexists_tac`ys`
  \\ `FINITE ys`
  by (
    qunabbrev_tac`ys`
    \\ simp[CONJ_ASSOC]
    \\ qho_match_abbrev_tac`FINITE { f y | y | P y ∧ _ y}`
    \\ irule SUBSET_FINITE \\ qexists_tac`{f y | P y}`
    \\ reverse conj_tac
    >- (simp[SUBSET_DEF, PULL_EXISTS] \\ metis_tac[])
    \\ qspec_then`λq. IMAGE (λs. (s, decode_function q s))
                            (IMAGE encode_set (b v))`irule FINITE_INJ
    \\ qexists_tac`b`
    \\ qexists_tac`POW (IMAGE encode_set (b v) × IMAGE encode_set (b u))`
    \\ qexists_tac`v`
    \\ simp[]
    \\ simp[INJ_DEF, PULL_EXISTS, IN_POW, SUBSET_DEF]
    \\ conj_tac
    >- (
      rw[]
      \\ goal_assum(first_assum o mp_then Any mp_tac) \\ simp[]
      \\ simp[Abbr`f`]
      \\ simp[restrict_def]
      \\ fs[Abbr`P`, SUBSET_DEF, PULL_EXISTS]
      \\ metis_tac[] )
    \\ simp[Abbr`f`]
    \\ rpt strip_tac
    \\ AP_TERM_TAC
    \\ fs[EXTENSION, restrict_def, PULL_EXISTS]
    \\ rw[FUN_EQ_THM] \\ rw[] \\ simp[]
    \\ fsrw_tac[boolSimps.DNF_ss][EQ_IMP_THM]
    \\ metis_tac[decode_encode_set, PAIR_EQ])
  \\ qexists_tac`(external v c).env`
  \\ qabbrev_tac`f = λa y e. c.eval
       (decode_function a
         (decode_function y (FST (decode_pair e))))
       (SND (decode_pair e))`
  \\ qexists_tac`f`
  \\ simp[]
  \\ qmatch_goalsub_abbrev_tac`external u c ≃ d1 -: w1`
  \\ qmatch_goalsub_abbrev_tac`external v c ≃ d2 -: w1`
  \\ `c.world = w` by metis_tac[in_chu_objects]
  \\ `w1 = w` by simp[Abbr`w1`, external_def, cf_external_def]
  \\ qunabbrev_tac`w1`
  \\ `d1 ∈ chu_objects w`
  by (
    simp[Abbr`d1`]
    \\ `external u c ∈ chu_objects w` by simp[]
    \\ `external v c ∈ chu_objects w` by simp[]
    \\ fs[in_chu_objects]
    \\ fs[wf_def, finite_cf_def]
    \\ simp[image_def, SUBSET_DEF, PULL_EXISTS, EXISTS_PROD]
    \\ simp[Abbr`f`]
    \\ simp[external_def, cf_external_def, PULL_EXISTS, EXISTS_PROD]
    \\ simp[Abbr`ys`, PULL_EXISTS]
    \\ rpt strip_tac
    \\ simp[restrict_def]
    \\ reverse IF_CASES_TAC >- metis_tac[] \\ pop_assum kall_tac
    \\ fs[repfns_def, PULL_EXISTS]
    \\ simp[restrict_def]
    \\ qpat_x_assum`IMAGE _ _ ⊆ _`mp_tac
    \\ simp[SUBSET_DEF, PULL_EXISTS] \\ strip_tac
    \\ reverse IF_CASES_TAC >- metis_tac[] \\ pop_assum kall_tac
    \\ first_x_assum irule \\ simp[]
    \\ `y x ∈ b u` by metis_tac[]
    \\ pop_assum mp_tac
    \\ `q ( y x) ∈ y x` by metis_tac[is_repfn_def]
    \\ simp_tac(srw_ss())[Abbr`b`, fn_partition_def]
    \\ strip_tac \\ fs[fn_part_def])
  \\ `d2 ∈ chu_objects w`
  by (
    simp[Abbr`d2`]
    \\ `external u c ∈ chu_objects w` by simp[]
    \\ `external v c ∈ chu_objects w` by simp[]
    \\ fs[in_chu_objects]
    \\ fs[wf_def, finite_cf_def]
    \\ simp[image_def, SUBSET_DEF, PULL_EXISTS, EXISTS_PROD]
    \\ simp[Abbr`f`]
    \\ simp[external_def, cf_external_def, PULL_EXISTS, EXISTS_PROD]
    \\ simp[Abbr`ys`, PULL_EXISTS]
    \\ rpt strip_tac
    \\ simp[restrict_def]
    \\ reverse IF_CASES_TAC >- metis_tac[] \\ pop_assum kall_tac
    \\ fs[repfns_def, PULL_EXISTS]
    \\ simp[restrict_def]
    \\ qpat_x_assum`IMAGE _ _ ⊆ _`mp_tac
    \\ simp[SUBSET_DEF, PULL_EXISTS] \\ strip_tac
    \\ reverse IF_CASES_TAC >- metis_tac[] \\ pop_assum kall_tac
    \\ first_x_assum irule \\ simp[]
    \\ `y x ∈ b u` by metis_tac[]
    \\ pop_assum mp_tac
    \\ `q ( y x) ∈ y x` by metis_tac[is_repfn_def]
    \\ simp_tac(srw_ss())[Abbr`b`, fn_partition_def]
    \\ strip_tac \\ fs[fn_part_def])
  \\ conj_tac
  >- (
    simp[homotopy_equiv_def]
    \\ qexists_tac`mk_chu_morphism (external u c) d1 <|
         map_agent := I;
         map_env := λp. encode_pair (
           decode_function (FST (decode_pair p))
             (FST (decode_pair (SND (decode_pair p)))),
           SND (decode_pair (SND (decode_pair p)))) |>`
    \\ qexists_tac`mk_chu_morphism d1 (external u c) <|
        map_agent := I;
        map_env := λp.
        let b = FST (decode_pair p) in
        let b'b = encode_set (b' (decode_set b)) in
        encode_pair (
          (@y. y ∈ ys ∧ decode_function y b'b = b),
          encode_pair (b'b, (SND (decode_pair p)))) |>`
    \\ qmatch_goalsub_abbrev_tac`homotopic _ (g o h -: _)`
    \\ conj_asm1_tac
    >- (
      simp[maps_to_in_chu, Abbr`h`, Abbr`g`]
      \\ simp[is_chu_morphism_def, mk_chu_morphism_def]
      \\ simp[restrict_def]
      \\ simp[Abbr`d1`, PULL_EXISTS, EXISTS_PROD]
      \\ simp[mk_cf_def]
      \\ conj_tac
      >- (
        simp[external_def, cf_external_def, PULL_EXISTS, EXISTS_PROD]
        \\ simp[Abbr`ys`, PULL_EXISTS]
        \\ rpt strip_tac
        \\ simp[restrict_def]
        \\ qpat_x_assum`_ ⊆ _`mp_tac
        \\ simp[SUBSET_DEF, PULL_EXISTS]
        \\ metis_tac[] )
      \\ simp[external_eval]
      \\ rw[]
      \\ `F` suffices_by rw[]
      \\ qpat_x_assum`_ ∉ _`mp_tac \\ simp[]
      \\ ntac 3 (pop_assum mp_tac)
      \\ simp_tac(srw_ss())
           [external_def, cf_external_def, PULL_EXISTS, EXISTS_PROD, Abbr`ys`]
      \\ rpt strip_tac \\ simp[]
      \\ simp[restrict_def] \\ rfs[]
      \\ qpat_x_assum`_ ⊆ _`mp_tac
      \\ simp[PULL_EXISTS, SUBSET_DEF]
      \\ metis_tac[])
    \\ conj_asm1_tac
    >- (
      pop_assum kall_tac
      \\ simp[maps_to_in_chu, Abbr`h`, Abbr`g`]
      \\ simp[is_chu_morphism_def, mk_chu_morphism_def]
      \\ simp[restrict_def]
      \\ simp[Abbr`d1`, PULL_EXISTS, EXISTS_PROD]
      \\ simp[mk_cf_def]
      \\ conj_tac
      >- (
        simp[external_def, cf_external_def, PULL_EXISTS, EXISTS_PROD]
        \\ rpt strip_tac
        \\ SELECT_ELIM_TAC
        \\ conj_tac
        >- (
          simp[Abbr`ys`, PULL_EXISTS]
          \\ qexists_tac`restrict (λfp. if fp = b' x then x
                                        else @x. x ∈ b u ∧ b' x = fp)
                                  (b v)`
          \\ simp[]
          \\ simp[restrict_def, SUBSET_DEF, PULL_EXISTS]
          \\ conj_tac >- (
            rw[]
            \\ pop_assum mp_tac
            \\ simp[Abbr`b`, fn_partition_def, PULL_EXISTS]
            \\ metis_tac[] )
          \\ reverse conj_tac >- ( rw[] \\ metis_tac[] )
          \\ rpt strip_tac
          \\ IF_CASES_TAC \\ simp[]
          \\ qpat_x_assum`fp ∈ _`mp_tac
          \\ simp[PULL_EXISTS, Abbr`b`, fn_partition_def]
          \\ metis_tac[])
        \\ metis_tac[])
      \\ simp[external_eval]
      \\ simp[Abbr`f`]
      \\ simp[external_def, cf_external_def, PULL_EXISTS, EXISTS_PROD]
      \\ simp[repfns_def, PULL_EXISTS]
      \\ rpt strip_tac
      \\ SELECT_ELIM_TAC
      \\ conj_tac
      >- (
        simp[Abbr`ys`, PULL_EXISTS]
        \\ qexists_tac`restrict (λfp. if fp = b' x then x
                                      else @x. x ∈ b u ∧ b' x = fp)
                                (b v)`
        \\ simp[]
        \\ simp[restrict_def, SUBSET_DEF, PULL_EXISTS]
        \\ conj_tac >- (
          rw[]
          \\ pop_assum mp_tac
          \\ simp[Abbr`b`, fn_partition_def, PULL_EXISTS]
          \\ metis_tac[] )
        \\ reverse conj_tac >- ( rw[] \\ metis_tac[] )
        \\ rpt strip_tac
        \\ IF_CASES_TAC \\ simp[]
        \\ qpat_x_assum`fp ∈ _`mp_tac
        \\ simp[PULL_EXISTS, Abbr`b`, fn_partition_def]
        \\ metis_tac[])
      \\ rpt strip_tac
      \\ reverse IF_CASES_TAC \\ simp[]
      \\ metis_tac[])
    \\ qpat_assum`h :- _ → _ -: _`(mp_then Any mp_tac compose_in_chu)
    \\ disch_then(qpat_assum`g :- _ → _ -: _` o mp_then Any strip_assume_tac)
    \\ qpat_assum`g :- _ → _ -: _`(mp_then Any mp_tac compose_in_chu)
    \\ disch_then(qpat_assum`h :- _ → _ -: _` o mp_then Any strip_assume_tac)
    \\ simp[homotopic_id_map_agent_id]
    \\ simp[restrict_def]
    \\ simp[Abbr`g`, Abbr`h`, mk_chu_morphism_def]
    \\ simp[restrict_def]
    \\ simp[Abbr`d1`] )
  \\ simp[homotopy_equiv_def]
  \\ qexists_tac`mk_chu_morphism (external v c) d2 <|
       map_agent := λq.
         encode_pair (
           let q' = λs.
             option_CASE
               (some x. x ∈ IMAGE encode_set (b v) ∧
                        s = fn_part c.agent c.env c.eval u
                               (decode_function q x))
               (CHOICE s) (decode_function q) in
           encode_function (IMAGE encode_set (b u))
             (restrict (q' o decode_set) (IMAGE encode_set (b u))),
           encode_function (IMAGE encode_set (b v))
             (restrict (encode_set o fn_part c.agent c.env c.eval u o
                        decode_function q)
               (IMAGE encode_set (b v)))); map_env := I |>`
  \\ qexists_tac`mk_chu_morphism d2 (external v c) <|
       map_agent := λp. encode_function (IMAGE encode_set (b v))
         (restrict
           (decode_function (FST (decode_pair p))
            o decode_function (SND (decode_pair p)))
           (IMAGE encode_set (b v)));
       map_env := I |>`
  \\ qmatch_goalsub_abbrev_tac`homotopic _ (g o h -: _)`
  \\ conj_asm1_tac
  >- (
    simp[maps_to_in_chu, Abbr`h`, Abbr`g`]
    \\ simp[is_chu_morphism_def, mk_chu_morphism_def]
    \\ simp[Once restrict_def]
    \\ conj_tac >- simp[Abbr`d2`]
    \\ simp[Once restrict_def]
    \\ qho_match_abbrev_tac`(∀a. _ a ⇒ encode_pair
              (encode_function _ (restrict (qq a) _), _ a) ∈ _) ∧ _`
    \\ simp[external_eval]
    \\ simp[Once CONJ_COMM]
    \\ simp[Ntimes restrict_def 4]
    \\ simp[Abbr`d2`, mk_cf_def, Abbr`f`]
    \\ conj_asm2_tac \\ simp[]
    >- (
      simp[external_def, cf_external_def, PULL_EXISTS, EXISTS_PROD]
      \\ simp[repfns_def, PULL_EXISTS]
      \\ simp[restrict_def, PULL_EXISTS]
      \\ rpt strip_tac
      \\ reverse IF_CASES_TAC >- metis_tac[] \\ pop_assum kall_tac
      \\ simp[]
      \\ qmatch_goalsub_abbrev_tac`fp u (q x)`
      \\ `fp u (q x) ∈ b u`
      by (
        simp[Abbr`b`, fn_partition_def]
        \\ qexists_tac`q x` \\ simp[]
        \\ fs[is_repfn_fn_partition]
        \\ qpat_x_assum`_ ⊆ _`mp_tac
        \\ simp[SUBSET_DEF, PULL_EXISTS] )
      \\ reverse IF_CASES_TAC >- metis_tac[]
      \\ pop_assum kall_tac
      \\ simp[Abbr`qq`]
      \\ qmatch_goalsub_abbrev_tac`_ = fp u (qq _)`
      \\ `∀x. x ∈ b v ⇒ qq (encode_set x) = q x`
      by (
        simp[Abbr`qq`]
        \\ rpt strip_tac
        \\ DEP_REWRITE_TAC[decode_encode_function]
        \\ simp[extensional_def, PULL_EXISTS]
        \\ metis_tac[] )
      \\ DEEP_INTRO_TAC some_intro
      \\ simp[PULL_EXISTS]
      \\ `q x ∈ x` by metis_tac[is_repfn_def]
      \\ `q x ∈ c.agent` by (
        fs[Abbr`b`, fn_partition_def]
        \\ rfs[Abbr`fp`, fn_part_def] )
      \\ reverse conj_tac >- metis_tac[]
      \\ rpt strip_tac \\ rfs[]
      \\ qmatch_assum_rename_tac`_ = fp u (q x2)`
      \\ `q x2 ∈ x2` by metis_tac[is_repfn_def]
      \\ `q x2 ∈ c.agent` by (
        fs[Abbr`b`, fn_partition_def]
        \\ rfs[Abbr`fp`, fn_part_def] )
      \\ `fp v (q x) = fp v (q x2)` by metis_tac[]
      \\ `partitions (b v) c.agent`
      by (
        qunabbrev_tac`b`
        \\ irule partitions_fn_partition
        \\ metis_tac[in_chu_objects, wf_def] )
      \\ pop_assum mp_tac
      \\ simp[partitions_thm]
      \\ `q x ∈ fp v (q x)`
      by ( simp_tac(srw_ss())[Abbr`fp`, fn_part_def] \\ simp[] )
      \\ `q x2 ∈ fp v (q x2)`
      by ( simp_tac(srw_ss())[Abbr`fp`, fn_part_def] \\ simp[] )
      \\ `fp v (q x) ∈ b v ∧ fp v (q x2) ∈ b v`
      by metis_tac[]
      \\ strip_tac
      \\ `fp v (q x2) = x2` by metis_tac[EXISTS_UNIQUE_ALT]
      \\ `fp v (q x) = x` by metis_tac[EXISTS_UNIQUE_ALT]
      \\ metis_tac[])
    \\ simp[external_def, cf_external_def, PULL_EXISTS, EXISTS_PROD]
    \\ simp[repfns_def, PULL_EXISTS]
    \\ rpt strip_tac
    \\ qmatch_goalsub_abbrev_tac`qq qf`
    \\ qexists_tac`restrict (qq qf o encode_set) (b u)`
    \\ simp[GSYM CONJ_ASSOC]
    \\ conj_tac
    >- (
      AP_TERM_TAC
      \\ simp[restrict_def, FUN_EQ_THM]
      \\ rw[] \\ rw[] \\ gs[])
    \\ simp[Abbr`qf`]
    \\ simp[Abbr`qq`]
    \\ qmatch_goalsub_abbrev_tac`encode_set o fp u o _`
    \\ fs[is_repfn_def]
    \\ simp[Once restrict_def]
    \\ conj_tac
    >- (
      rpt strip_tac
      \\ DEEP_INTRO_TAC some_intro
      \\ simp[PULL_EXISTS]
      \\ conj_tac
      >- (
        rpt strip_tac
        \\ BasicProvers.VAR_EQ_TAC
        \\ qpat_x_assum`_ ∈ b u`mp_tac
        \\ simp[restrict_def]
        \\ reverse IF_CASES_TAC >- metis_tac[]
        \\ pop_assum kall_tac
        \\ qmatch_assum_rename_tac`x ∈ b v`
        \\ `q x ∈ x` by metis_tac[]
        \\ simp[Abbr`fp`, fn_part_def]
        \\ fs[Abbr`b`, fn_partition_def]
        \\ disch_then kall_tac
        \\ pop_assum mp_tac
        \\ simp[fn_part_def])
      \\ `x ≠ ∅` suffices_by metis_tac[CHOICE_DEF]
      \\ `partitions (b u) c.agent`
      by (
        qunabbrev_tac`b`
        \\ irule partitions_fn_partition
        \\ metis_tac[in_chu_objects, wf_def] )
      \\ metis_tac[partitions_thm])
    \\ simp[Abbr`ys`]
    \\ qexists_tac`restrict (fp u o q) (b v)`
    \\ simp[]
    \\ conj_tac
    >- (
      AP_TERM_TAC
      \\ simp[restrict_def, FUN_EQ_THM]
      \\ gen_tac \\ IF_CASES_TAC \\ simp[]
      \\ pop_assum strip_assume_tac
      \\ simp[] )
    \\ simp[restrict_def]
    \\ simp[SUBSET_DEF, PULL_EXISTS]
    \\ `∀x. x ∈ b v ⇒ q x ∈ c.agent`
    by (
      rpt strip_tac
      \\ `q x ∈ x` by metis_tac[]
      \\ ntac 2 (pop_assum mp_tac)
      \\ simp_tac(srw_ss())[Abbr`b`, fn_partition_def, PULL_EXISTS]
      \\ simp[fn_part_def])
    \\ conj_asm1_tac
    >- (
      rpt strip_tac
      \\ simp[Abbr`b`, fn_partition_def]
      \\ metis_tac[] )
    \\ rpt strip_tac
    \\ simp[]
    \\ qmatch_assum_rename_tac`x ∈ b v`
    \\ `partitions (b v) c.agent`
    by (
      qunabbrev_tac`b`
      \\ irule partitions_fn_partition
      \\ metis_tac[in_chu_objects, wf_def] )
    \\ `q x ∈ x` by metis_tac[]
    \\ `∃a. a ∈ c.agent ∧ x = fp v a`
    by (
      qpat_x_assum`x ∈ _`mp_tac
      \\ simp[Abbr`b`, fn_partition_def]
      \\ metis_tac[] )
    \\ `q x ∈ fp v (q x)` by (
      simp_tac(srw_ss())[Abbr`fp`, fn_part_def]
      \\ metis_tac[] )
    \\ `fp v (q x) ∈ b v` by metis_tac[]
    \\ qhdtm_x_assum`partitions`mp_tac
    \\ simp[partitions_thm]
    \\ strip_tac
    \\ metis_tac[EXISTS_UNIQUE_ALT])
  \\ conj_asm1_tac
  >- (
    pop_assum kall_tac
    \\ simp[maps_to_in_chu, Abbr`h`, Abbr`g`]
    \\ simp[is_chu_morphism_def, mk_chu_morphism_def]
    \\ simp[restrict_def]
    \\ simp[Abbr`d2`, PULL_EXISTS, EXISTS_PROD, mk_cf_def]
    \\ simp[external_eval]
    \\ simp[external_def, cf_external_def, PULL_EXISTS, EXISTS_PROD]
    \\ simp[Abbr`f`]
    \\ conj_asm1_tac \\ simp[]
    >- (
      simp[repfns_def, PULL_EXISTS, Abbr`ys`]
      \\ rpt strip_tac
      \\ qmatch_goalsub_abbrev_tac`encode_function _ qq`
      \\ qexists_tac`restrict (qq o encode_set) (b v)`
      \\ simp[is_repfn_def]
      \\ conj_tac
      >- (
        AP_TERM_TAC
        \\ simp[Abbr`qq`, FUN_EQ_THM]
        \\ simp[restrict_def]
        \\ gen_tac \\ IF_CASES_TAC \\ simp[]
        \\ IF_CASES_TAC \\ simp[]
        \\ pop_assum kall_tac
        \\ pop_assum strip_assume_tac
        \\ simp[]
        \\ IF_CASES_TAC \\ simp[]
        \\ metis_tac[] )
      \\ simp[Abbr`qq`]
      \\ simp[restrict_def]
      \\ rpt strip_tac
      \\ reverse IF_CASES_TAC >- metis_tac[]
      \\ qpat_x_assum`_ ⊆ _`mp_tac
      \\ simp[SUBSET_DEF, PULL_EXISTS]
      \\ strip_tac
      \\ reverse IF_CASES_TAC >- metis_tac[]
      \\ `q (y x) ∈ y x` by metis_tac[is_repfn_def]
      \\ `y x ∈ b u` by metis_tac[]
      \\ `b' (y x) = x` by metis_tac[]
      \\ qmatch_asmsub_abbrev_tac`b' (fp u _) = fp v _`
      \\ `∃a1. a1 ∈ c.agent ∧ y x = fp u a1`
      by (
        qpat_x_assum`y x ∈ _`mp_tac
        \\ simp_tac(srw_ss())[Abbr`b`, fn_partition_def]
        \\ metis_tac[] )
      \\ `x = fp v a1` by metis_tac[]
      \\ `fp u a1 ⊆ fp v a1` suffices_by metis_tac[SUBSET_DEF]
      \\ qunabbrev_tac`fp`
      \\ irule refines_fn_part_SUBSET
      \\ metis_tac[in_chu_objects, wf_def])
    \\ simp[repfns_def, PULL_EXISTS]
    \\ simp[Abbr`ys`, PULL_EXISTS]
    \\ rpt strip_tac
    \\ `y x ∈ b u` by (
      qpat_x_assum`_ ⊆ _`mp_tac
      \\ simp[SUBSET_DEF] \\ metis_tac[])
    \\ simp[restrict_def]
    \\ reverse IF_CASES_TAC >- metis_tac[]
    \\ pop_assum kall_tac
    \\ reverse IF_CASES_TAC >- metis_tac[]
    \\ pop_assum kall_tac
    \\ simp[]
    \\ DEP_REWRITE_TAC[decode_encode_function]
    \\ simp[extensional_def]
    \\ conj_tac >- metis_tac[]
    \\ reverse IF_CASES_TAC >- metis_tac[]
    \\ pop_assum kall_tac
    \\ reverse IF_CASES_TAC >- metis_tac[]
    \\ pop_assum kall_tac
    \\ simp[])
  \\ qpat_assum`h :- _ → _ -: _`(mp_then Any mp_tac compose_in_chu)
  \\ disch_then(qpat_assum`g :- _ → _ -: _` o mp_then Any strip_assume_tac)
  \\ qpat_assum`g :- _ → _ -: _`(mp_then Any mp_tac compose_in_chu)
  \\ disch_then(qpat_assum`h :- _ → _ -: _` o mp_then Any strip_assume_tac)
  \\ simp[homotopic_id_map_env_id]
  \\ simp[restrict_def]
  \\ simp[Abbr`g`, Abbr`h`, mk_chu_morphism_def]
  \\ simp[restrict_def]
  \\ simp[Abbr`d2`]
QED

val _ = export_theory();
