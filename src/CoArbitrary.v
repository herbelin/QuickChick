Require Import Arbitrary Random GenLow.
Import GenLow.

Require Import PArith.
Require Import List.
Import ListNotations.

(* LL: TODO: Add proof obligation that the result paths be prefix free? *)
Class CoArbitrary (A : Type) : Type :=
  {
    coarbitrary : A -> positive;
    coarbReverse : positive -> option A;
    coarbCorrect : forall a, coarbReverse (coarbitrary a) = Some a
  }.

Instance coArbPos : CoArbitrary positive := 
  {|
    coarbitrary x := x;
    coarbReverse x := Some x
  |}.
Proof. auto. Qed.

Local Open Scope positive.
Fixpoint posToPathAux (p : positive) : SplitPath := 
  match p with 
    | xH => []
    | xI p' => posToPathAux p' ++ [Left; Right]
    | xO p' => posToPathAux p' ++ [Left; Left ]
  end.

Definition posToPath (p : positive) : SplitPath := posToPathAux p ++ [Right].

Fixpoint pathToPos (p : SplitPath) : option positive := 
  match p with 
    | [Right] => Some xH
    | Left :: Right :: p' => 
      option_map xI (pathToPos p')
    | Left :: Left  :: p' =>
      option_map xO (pathToPos p')
    | _ => None
  end.

Lemma posPathInj : forall p, pathToPos (posToPath p) = Some p.
Admitted.

Lemma PosToPathPrefixFree : forall (x y : positive), ~ (x = y) -> 
                              PrefixFree [posToPath x;
                                          posToPath y].
intros.
apply FreeCons; [ apply FreeCons ; [ constructor | intros p Contra; inversion Contra] | ].
generalize dependent y.
induction x; intros.
+ destruct y eqn:Y.
  - eapply (IHx p).
    * congruence.
    * instantiate (1 := posToPath p); left; auto.
    * inversion H0.
      + unfold posToPath in *; simpl in *.
Admitted.
        
Eval compute in (pathToPos (posToPath 1)).
Eval compute in (pathToPos (posToPath 2)).
Eval compute in (pathToPos (posToPath 3)).
Eval compute in (pathToPos (posToPath 4)).
Eval compute in (pathToPos (posToPath 5)).

Function rangeNat (p : nat) : list nat :=
  match p with 
    | O => []
    | S n' => p :: (rangeNat n')
  end.

Definition rangePos (p : positive) : list positive := 
  map Pos.of_nat (rangeNat (Pos.to_nat p)).

Lemma ltInRange : forall m n, le n m -> n <> O -> In n (rangeNat m).
  induction m; intros.
  + inversion H. simpl. auto.
  + simpl. inversion H.
    - left; auto.
    - right; subst. apply IHm; auto.
Qed.

Lemma posLtInRange : forall max pos, Pos.le pos max -> In pos (rangePos max).
  intros.
  apply in_map_iff.
  exists (Pos.to_nat pos).
  split.
  - apply Pos2Nat.id.
  - apply ltInRange.
    + admit.
    + admit.
Qed.

Lemma rangeNatLt : forall n m, In m (rangeNat n) -> lt m (S n).
  induction n; intros.
  + simpl in H. inversion H. 
  + inversion H.
    - subst. unfold lt. apply le_n.
    - apply IHn in H0.
      unfold lt in *.
      apply le_S.
      auto.
Qed.    

Lemma rangePosPrefixFree : forall p, PrefixFree (map posToPath (rangePos p)).
  intros.
  unfold rangePos.
  induction (Pos.to_nat p).
  + constructor.
  + simpl. apply FreeCons; auto.
    intros.
    apply in_map_iff in H.
    clear IHn.
    inversion H; clear H.
    inversion H1; clear H1.
    subst.
    apply in_map_iff in H2.
    inversion H2; clear H2.
    inversion H; clear H.
    apply rangeNatLt in H2.
    remember (match n with | O => 1 | S _ => Pos.succ (Pos.of_nat n) end) as m.
    assert (x <> m). admit.
    pose proof PosToPathPrefixFree x m.
    apply H3 in H.
    inversion H.
    eapply H7.
    + left; auto.
    + eauto.
Qed.    

Definition posFunToPathFun (f : positive -> RandomSeed) (p : SplitPath) 
: RandomSeed :=
  match pathToPos p with 
    | Some a => f a
    | None   => newRandomSeed
  end.

Theorem coArbComplete' : forall (max : positive) (f : positive -> RandomSeed) ,
                          exists seed, forall p, p <= max -> 
                            varySeed (posToPath p) seed = f p.
intros.
pose proof (topLevelSeedTheorem (map posToPath (rangePos max)) 
                                (posFunToPathFun f) (rangePosPrefixFree max)).
inversion H; clear H.
exists x.
intros.
pose proof H0 (posToPath p).
rewrite H1.
+ unfold posFunToPathFun.
  rewrite posPathInj.
  reflexivity.
+ apply in_map_iff.
  exists p.
  split; auto.
  apply posLtInRange.
  auto.
Qed.

Instance arbFun {A B : Type} `{_ : CoArbitrary A} `{_ : Arbitrary B} : Arbitrary (A -> B) :=
  {|
    arbitrary := 
      reallyUnsafePromote (fun a => variant (posToPath (coarbitrary a)) arbitrary);
    shrink x := []
  |}.


(*
Definition varyComplete : forall (max : nat) (f : nat -> RandomSeed),
                          exists (seed : RandomSeed), 
                            forall (n : nat),
                              n <= max -> varySeed n seed = f n.


induction max; intros.
+ pose proof (randomSplitAssumption (f O) (f O)) as Seed; inversion Seed as [seed Hyp].
  exists seed; intros p H.
  inversion_clear H.
  unfold varySeed, varySeed_terminate, boolVary; simpl.
  rewrite Hyp.
  reflexivity.
+ pose proof (IHmax f) as Seed.
  inversion Seed as [seed Hyp]; clear Seed.
*)
(*  
exists randomSeedInhabitant; intros.
  inversion H. 
  - admit.
  - 

pose proof IHmax f as IH.
    inversion IH as [seed' Hyp'].
    
unfold varySeed, varySeed_terminate, boolVary. simpl.
  

  inversion 
admit.
+ admit.
+ pose proof (randomSplitAssumption (f xH) (f xH)) as Seed; inversion Seed as [seed Hyp].
  exists seed; intros p H.
  apply Pos.le_lteq in H.
  inversion H as [Contra | ].
  - apply Pos.nlt_1_r in Contra; inversion Contra.
  - subst. unfold varySeed. unfold boolVary. rewrite Hyp. reflexivity.
Qed.

Axiom randomSplitAssumption :
  forall s1 s2 : RandomSeed, exists s, randomSplit s = (s1,s2).
*)


