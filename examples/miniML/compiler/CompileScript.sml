(* generated by Lem from compile.lem *)
open bossLib Theory Parse res_quanTheory
open finite_mapTheory listTheory pairTheory pred_setTheory integerTheory
open alistTheory CexpTypesTheory
open set_relationTheory sortingTheory stringTheory wordsTheory

val _ = new_theory "Compile"

open BytecodeTheory MiniMLTheory

(* TODO: move to lem *)
(*val fold_left2 : forall 'a 'b 'c. ('a -> 'b -> 'c -> 'a) -> 'a -> 'b list -> 'c list -> 'a*)
(* TODO: lem library should use this for List.for_all2 *)
(*val every2 : forall 'a 'b. ('a -> 'b -> bool) -> 'a list -> 'b list -> bool*)
(*val least : (num -> bool) -> num*)
(*val num_to_string : num -> string*)
(*val replace : forall 'a. 'a -> num -> 'a list -> 'a list*)
(*val int_to_num : int -> num*)
(*val alist_to_fmap : forall 'a 'b. ('a * 'b) list -> ('a,'b) Pmap.map*)
(*val optrel : forall 'a 'b 'c 'd. ('a -> 'b -> bool) -> 'c -> 'd -> bool*)
(*val flookup : forall 'a 'b 'c. ('a,'b) Pmap.map -> 'a -> 'c*)

(* TODO: elsewhere? *)
 val find_index_defn = Hol_defn "find_index" `

(find_index y [] _ =NONE)
/\
(find_index y (x::xs) (n:num) = if x= y then SOME n else find_index y xs (n+1))`;

val _ = Defn.save_defn find_index_defn;

val _ = Define `
 (fresh_var s =num_to_hex_string ($LEAST (\ n .~  (num_to_hex_string n IN s))))`;


(*open MiniML*)

(* TODO: elsewhere? *)
 val map_result_defn = Hol_defn "map_result" `

(map_result f (Rval v) = Rval (f v))
/\
(map_result f (Rerr e) = Rerr e)`;

val _ = Defn.save_defn map_result_defn;

(* observable values *)

val _ = Hol_datatype `
 ov =
    OLit of lit
  | OConv of conN => ov list
  | OFn`;


 val v_to_ov_defn = Hol_defn "v_to_ov" `

(v_to_ov (Litv l) = OLit l)
/\
(v_to_ov (Conv cn vs) = OConv cn (MAP v_to_ov vs))
/\
(v_to_ov (Closure _ _ _) = OFn)
/\
(v_to_ov (Recclosure _ _ _) = OFn)`;

val _ = Defn.save_defn v_to_ov_defn;

(* Intermediate language for MiniML compiler *)

val _ = Define `
 i0 = & 0`;

val _ = Define `
 i1 = & 1`;

val _ = Define `
 i2 = & 2`;



 val Cv_to_ov_defn = Hol_defn "Cv_to_ov" `

(Cv_to_ov m (CLitv l) = OLit l)
/\
(Cv_to_ov m (CConv cn vs) = OConv (FAPPLY  m  cn) (MAP (Cv_to_ov m) vs))
/\
(Cv_to_ov m (CRecClos _ _ _ _) = OFn)`;

val _ = Defn.save_defn Cv_to_ov_defn;

 val Cpat_vars_defn = Hol_defn "Cpat_vars" `

(Cpat_vars (CPvar n) = {n})
/\
(Cpat_vars (CPlit _) = {})
/\
(Cpat_vars (CPcon _ ps) = FOLDL (\ s p . s UNION Cpat_vars p) {} ps)`;

val _ = Defn.save_defn Cpat_vars_defn;

 val free_vars_defn = Hol_defn "free_vars" `

(free_vars (CDecl xs) = LIST_TO_SET xs)
/\
(free_vars (CRaise _) = {})
/\
(free_vars (CVar n) = {n})
/\
(free_vars (CLit _) = {})
/\
(free_vars (CCon _ es) =
  FOLDL (\ s e . s UNION free_vars e) {} es)
/\
(free_vars (CTagEq e _) = free_vars e)
/\
(free_vars (CProj e _) = free_vars e)
/\
(free_vars (CLet xs es e) =
  FOLDL (\ s e . s UNION free_vars e)
  (free_vars e DIFF LIST_TO_SET xs) es)
/\
(free_vars (CLetfun T ns defs e) =
  FOLDL (\ s (vs,e) .
    s UNION (free_vars e DIFF (LIST_TO_SET ns UNION
                            LIST_TO_SET vs)))
  (free_vars e DIFF LIST_TO_SET ns) defs)
/\
(free_vars (CLetfun F ns defs e) =
  FOLDL (\ s (vs,e) .
    s UNION (free_vars e DIFF LIST_TO_SET vs))
  (free_vars e DIFF LIST_TO_SET ns) defs)
/\
(free_vars (CFun xs e) = free_vars e DIFF (LIST_TO_SET xs))
/\
(free_vars (CCall e es) =
  FOLDL (\ s e . s UNION free_vars e)
  (free_vars e) es)
/\
(free_vars (CPrim2 _ e1 e2) = free_vars e1 UNION free_vars e2)
/\
(free_vars (CIf e1 e2 e3) = free_vars e1 UNION free_vars e2 UNION free_vars e3)`;

val _ = Defn.save_defn free_vars_defn;

(* Big-step semantics *)

 val no_closures_defn = Hol_defn "no_closures" `

(no_closures (CLitv _) = T)
/\
(no_closures (CConv _ vs) = EVERY no_closures vs)
/\
(no_closures (CRecClos _ _ _ _) = F)`;

val _ = Defn.save_defn no_closures_defn;

 val doPrim2_defn = Hol_defn "doPrim2" `

(doPrim2 b ty op (CLitv (IntLit x)) (CLitv (IntLit y)) =
  if b/\ (y= i0) then (Rerr (Rraise Div_error))
  else Rval (CLitv (ty (op x y))))
/\
(doPrim2 b ty op _ _ = Rerr Rtype_error)`;

val _ = Defn.save_defn doPrim2_defn;

 val CevalPrim2_defn = Hol_defn "CevalPrim2" `

(CevalPrim2 CAdd = doPrim2 F IntLit int_add)
/\
(CevalPrim2 CSub = doPrim2 F IntLit (int_sub))
/\
(CevalPrim2 CMul = doPrim2 F IntLit int_mul)
/\
(CevalPrim2 CDiv = doPrim2 T IntLit int_div)
/\
(CevalPrim2 CMod = doPrim2 T IntLit int_mod)
/\
(CevalPrim2 CLt = doPrim2 F Bool int_lt)
/\
(CevalPrim2 CEq = \ v1 v2 .
  if no_closures v1/\ no_closures v2
  then Rval (CLitv (Bool (v1= v2)))
  else Rerr Rtype_error)`;

val _ = Defn.save_defn CevalPrim2_defn;

val _ = Define `
 (extend_rec_env cenv env rs defs ns vs =FOLDL2  (\ en n v . FUPDATE  en ( n, v))
    (FOLDL
        (\ en n . FUPDATE  en ( n,
          (CRecClos cenv rs defs n)))
        env
        rs)
    ns  vs)`;


val _ = Hol_reln `
(! env error.
T
==>
Cevaluate env (CRaise error) (Rerr (Rraise error)))

/\
(! env n.
 n IN FDOM  env
==>
Cevaluate env (CVar n) (Rval (FAPPLY  env  n)))

/\
(! env l.
T
==>
Cevaluate env (CLit l) (Rval (CLitv l)))

/\
(! env n es vs.
Cevaluate_list env es (Rval vs)
==>
Cevaluate env (CCon n es) (Rval (CConv n vs)))
/\
(! env n es err.
Cevaluate_list env es (Rerr err)
==>
Cevaluate env (CCon n es) (Rerr err))

/\
(! env e n m vs.
Cevaluate env e (Rval (CConv m vs))
==>
Cevaluate env (CTagEq e n) (Rval (CLitv (Bool (n= m)))))
/\
(! env e n err.
Cevaluate env e (Rerr err)
==>
Cevaluate env (CTagEq e n) (Rerr err))

/\
(! env e n m vs.
Cevaluate env e (Rval (CConv m vs))/\
n< LENGTH vs
==>
Cevaluate env (CProj e n) (Rval (EL  n  vs)))
/\
(! env e n err.
Cevaluate env e (Rerr err)
==>
Cevaluate env (CProj e n) (Rerr err))

/\
(! env b r.
Cevaluate env b r
==>
Cevaluate env (CLet [] [] b) r)
/\
(! env n ns e es b v r.
Cevaluate env e (Rval v)/\
Cevaluate (FUPDATE  env ( n, v)) (CLet ns es b) r
==>
Cevaluate env (CLet (n::ns) (e::es) b) r)
/\
(! env n ns e es b err.
Cevaluate env e (Rerr err)
==>
Cevaluate env (CLet (n::ns) (e::es) b) (Rerr err))

/\
(! env ns defs a b r.
(LENGTH ns= LENGTH defs)/\ALL_DISTINCT ns/\~  (a IN free_vars b)/\
Cevaluate
  (FOLDL2
    (\ env' n (xs,b) .
      FUPDATE  env' ( n, (CRecClos env [a] [(xs,b)] a)))
    env  ns  defs)
  b r
==>
Cevaluate env (CLetfun F ns defs b) r)

/\
(! env ns defs b r.
(LENGTH ns= LENGTH defs)/\ALL_DISTINCT ns/\
Cevaluate
  (FOLDL
     (\ env' n .
       FUPDATE  env' ( n, (CRecClos env ns defs n)))
     env ns)
  b r
==>
Cevaluate env (CLetfun T ns defs b) r)

/\
(! env xs a b.~  (a IN free_vars b)
==>
Cevaluate env (CFun xs b) (Rval (CRecClos env [a] [(xs,b)] a)))

/\
(! env e es env' ns' defs n i ns b vs r.
Cevaluate env e (Rval (CRecClos env' ns' defs n))/\
(LENGTH ns'= LENGTH defs)/\ALL_DISTINCT ns'/\
Cevaluate_list env es (Rval vs)/\(
find_index n ns' 0=SOME i)/\
(EL  i  defs= (ns,b))/\
(LENGTH ns= LENGTH vs)/\ALL_DISTINCT ns/\
Cevaluate (extend_rec_env env' env' ns' defs ns vs) b r
==>
Cevaluate env (CCall e es) r)
/\
(! env e v es err.
Cevaluate env e (Rval v)/\
Cevaluate_list env es (Rerr err)
==>
Cevaluate env (CCall e es) (Rerr err))

/\
(! env e es err.
Cevaluate env e (Rerr err)
==>
Cevaluate env (CCall e es) (Rerr err))

/\
(! env p2 e1 e2 v1 v2.
Cevaluate_list env [e1;e2] (Rval [v1;v2])
==>
Cevaluate env (CPrim2 p2 e1 e2) (CevalPrim2 p2 v1 v2))
/\
(! env p2 e1 e2 err.
Cevaluate_list env [e1;e2] (Rerr err)
==>
Cevaluate env (CPrim2 p2 e1 e2) (Rerr err))

/\
(! env e1 e2 e3 b1 r.
Cevaluate env e1 (Rval (CLitv (Bool b1)))/\
Cevaluate env (if b1 then e2 else e3) r
==>
Cevaluate env (CIf e1 e2 e3) r)
/\
(! env e1 e2 e3 err.
Cevaluate env e1 (Rerr err)
==>
Cevaluate env (CIf e1 e2 e3) (Rerr err))

/\
(! env.
T
==>
Cevaluate_list env [] (Rval []))
/\
(! env e es v vs.
Cevaluate env e (Rval v)/\
Cevaluate_list env es (Rval vs)
==>
Cevaluate_list env (e::es) (Rval (v::vs)))
/\
(! env e es err.
Cevaluate env e (Rerr err)
==>
Cevaluate_list env (e::es) (Rerr err))
/\
(! env e es v err.
Cevaluate env e (Rval v)/\
Cevaluate_list env es (Rerr err)
==>
Cevaluate_list env (e::es) (Rerr err))`;

(* equivalence relations on intermediate language *)

val _ = Hol_reln `
(! l.
T
==>
syneq (CLitv l) (CLitv l))
/\
(! cn vs1 vs2.EVERY2 syneq vs1 vs2
==>
syneq (CConv cn vs1) (CConv cn vs2))
/\
(! env1 env2 ns defs d.
EVERY
  (\ (xs,b) .
    (! v. v IN (free_vars b DIFF (LIST_TO_SET ns UNION
                                    LIST_TO_SET xs))==> (OPTREL syneq) (FLOOKUP env1 v) (FLOOKUP env2 v)))
  defs
==>
syneq (CRecClos env1 ns defs d) (CRecClos env2 ns defs d))`;

(* relating source to intermediate language *)

val _ = Hol_reln `
(! G cm env Cenv err.
T
==>
exp_Cexp G cm env Cenv (Raise err) (CRaise err))
/\
(! G cm env Cenv l.
T
==>
exp_Cexp G cm env Cenv (Lit l) (CLit l))
/\
(! G cm env Cenv cn es Ces.
 cn IN FDOM  cm/\EVERY2 (exp_Cexp G cm env Cenv) es Ces
==>
exp_Cexp G cm env Cenv (Con cn es) (CCon (FAPPLY  cm  cn) Ces))
/\
(! G cm env Cenv vn v Cvn.(
lookup vn env=SOME v)/\
 Cvn IN FDOM  Cenv/\
G cm v (FAPPLY  Cenv  Cvn)
==>
exp_Cexp G cm env Cenv (Var vn) (CVar Cvn))
/\
(! G cm env Cenv vn e n Ce.
(! v Cv. G cm v Cv==>
  exp_Cexp G cm (bind vn v env) (FUPDATE  Cenv ( n, Cv)) e Ce)
==>
exp_Cexp G cm env Cenv (Fun vn e) (CFun [n] Ce))`;

val _ = Hol_reln `
(! G cm l.
T
==>
v_Cv G cm (Litv l) (CLitv l))
/\
(! G cm cn vs Cvs.
 cn IN FDOM  cm/\EVERY2 (v_Cv G cm) vs Cvs
==>
v_Cv G cm (Conv cn vs) (CConv (FAPPLY  cm  cn) Cvs))`;

(*
indreln
forall cm env Cenv err.
true
==>
exp_Cexp cm env Cenv (Raise err) (CRaise err)
and
forall cm env Cenv v Cv.
v_Cv cm v Cv
==>
exp_Cexp cm env Cenv (Val v) (CVal Cv)
and
forall cm env Cenv cn es Ces.
every2 (exp_Cexp cm env Cenv) es Ces
==>
exp_Cexp cm env Cenv (Con cn es) (CCon (Pmap.find cn cm) Ces)
and
forall cm env Cenv vn v Cvn Cv.
lookup vn env = Some v &&
Pmap.mem Cvn Cenv && Pmap.find Cvn Cenv = Cv && (* TODO: lookup *)
v_Cv cm v Cv
==>
exp_Cexp cm env Cenv (Var vn) (CVar Cvn)
and
forall cm env Cenv vn e n Ce.
(* but what to do here without a context of equal variables? *)
(* (see comments in v_Cv below) *)
==>
exp_Cexp cm env Cenv (Fun vn e) (CFun n Ce)
and
forall cm l.
true
==>
v_Cv cm (Lit l) (CLit l)
and
forall cm cn vs Cvs.
every2 (v_Cv cm) vs Cvs
==>
v_Cv cm (Conv cn vs) (CConv (Pmap.find cn cm) Cvs)
and
forall cm env vn e Cenv n Ce.
(* can't do this because it's a negative occurrence of v_Cv,
 * leading to a non-monotonic rule
(forall v Cv. v_Cv cm v Cv -->
 exp_Cexp cm (bind vn v env) (Pmap.add n Cv (alist_to_fmap Cenv)) e Ce)
*)
(* obviously this is incorrect (requires the functions to be equivalent on
 * arbitrary pairs of arguments)
 * options for extension include:
   * normal form (open): use the same free variable as the argument
     * but does this distinguish too many pairs of terms?
   * carry around a context of equal values/variables
     * but how does this relate with the environments in closures?
     * probably just have to have both independently
   * parameterise by a "global knowledge" relation of equal values *)
(forall v Cv. exp_Cexp cm (bind vn v env) (Pmap.add n Cv (alist_to_fmap Cenv)) e Ce)
==>
v_Cv cm (Closure env vn e) (CClosure Cenv [n] Ce)
*)

(*
let rec
Cv_to_bv (CLitv (IntLit i)) = Number i
and
Cv_to_bv (CLitv (Bool b)) = Number (bool_to_int b)
and
Cv_to_bv (CConv n vs) = Block n (Cvs_to_bvs vs)
and
Cv_to_bv (CClosure env vs b) = Block 0 [CodePtr ?, ?]
and
Cv_to_bv (CRecClos env ns defs n) = Block 0 [CodePtr ?, ?]
and
Cvs_to_bvs [] = []
and
Cvs_to_bvs (v::vs) = Cv_to_bv v :: Cvs_to_bvs vs
*)


val _ = Hol_datatype `
 nt =
    NTvar of num
  | NTapp of nt list => typeN
  | NTfn
  | NTnum
  | NTbool`;


 val t_to_nt_defn = Hol_defn "t_to_nt" `

(t_to_nt a (Tvar x) = (case find_index x a 0 of SOME n => NTvar n ))
/\
(t_to_nt a (Tapp ts tn) = NTapp (MAP (t_to_nt a) ts) tn)
/\
(t_to_nt a (Tfn _ _) = NTfn)
/\
(t_to_nt a Tnum = NTnum)
/\
(t_to_nt a Tbool = NTbool)`;

val _ = Defn.save_defn t_to_nt_defn;

(* values in compile-time environment *)
val _ = Hol_datatype `
 ctbind = CTLet of num | CTArg of num | CTEnv of num | CTRef of num`;

(* CTLet n means stack[sz - n]
   CTArg n means stack[sz + n]
   CTEnv n means El n of the environment, which is at stack[sz]
   CTRef n means El n of the environment, but it's a ref pointer *)

(*open Bytecode*)

val _ = Hol_datatype `
 call_context = TCNonTail | TCTail of num => num`;


val _ = type_abbrev( "ctenv" , ``: (string,ctbind) fmap``);

val _ = Hol_datatype `
 compiler_state =
  <| env: ctenv
   ; sz: num
   ; code: bc_inst list (* reversed *)
   ; code_length: num
   ; tail: call_context
   ; next_label: num
   (* not modified on return: *)
   ; decl: (ctenv # num)option
   ; inst_length: bc_inst -> num
   |>`;


val _ = Hol_datatype `
 repl_state =
  <| cmap : (conN, num) fmap
   ; cpam : (typeN, (num, conN # nt list) fmap) fmap
   ; cs : compiler_state
   |>`;


 val pat_to_Cpat_defn = Hol_defn "pat_to_Cpat" `

(pat_to_Cpat m pvs (Pvar vn) = (vn::pvs, CPvar vn))
/\
(pat_to_Cpat m pvs (Plit l) = (pvs, CPlit l))
/\
(pat_to_Cpat m pvs (Pcon cn ps) =
  let (pvs,Cps) = pats_to_Cpats m pvs ps in
  (pvs,CPcon (FAPPLY  m  cn) Cps))
/\
(pats_to_Cpats m pvs [] = (pvs,[]))
/\
(pats_to_Cpats m pvs (p::ps) =
  let (pvs,Cps) = pats_to_Cpats m pvs ps in
  let (pvs,Cp) = pat_to_Cpat m pvs p in
  (pvs,Cp::Cps))`;

val _ = Defn.save_defn pat_to_Cpat_defn;

val _ = Define `
 Cpes_vars =
  FOLDL (\ s (p,e) . s UNION Cpat_vars p UNION free_vars e) {}`;


(* Remove pattern-matching using continuations *)
(* TODO: more efficient method *)
(* TODO: store type information on CMat nodes *)

 val remove_mat_vp_defn = Hol_defn "remove_mat_vp" `

(remove_mat_vp fk sk v (CPvar pv) =
  CLet [pv] [CVar v] sk)
/\
(remove_mat_vp fk sk v (CPlit l) =
  CIf (CPrim2 CEq (CVar v) (CLit l))
    sk (CCall (CVar fk) []))
/\
(remove_mat_vp fk sk v (CPcon cn ps) =
  CIf (CTagEq (CVar v) cn)
    (remove_mat_con fk sk v 0 ps)
    (CCall (CVar fk) []))
/\
(remove_mat_con fk sk v n [] = sk)
/\
(remove_mat_con fk sk v n (p::ps) =
  let v' = fresh_var ({v;fk}UNION (free_vars sk)UNION (Cpat_vars p)) in
  CLet [v'] [CProj (CVar v) n]
    (remove_mat_vp fk (remove_mat_con fk sk v (n+1) ps) v' p))`;

val _ = Defn.save_defn remove_mat_vp_defn;

 val remove_mat_var_defn = Hol_defn "remove_mat_var" `

(remove_mat_var v [] = CRaise Bind_error)
/\
(remove_mat_var v ((p,sk)::pes) =
  let fk = fresh_var ({v}UNION (free_vars sk)) in
  CLetfun F [fk] [([],(remove_mat_var v pes))]
    (remove_mat_vp fk sk v p))`;

val _ = Defn.save_defn remove_mat_var_defn;

 val exp_to_Cexp_defn = Hol_defn "exp_to_Cexp" `

(exp_to_Cexp m (Raise err) = CRaise err)
/\
(exp_to_Cexp m (Lit l) = CLit l)
/\
(exp_to_Cexp m (Con cn es) =
  CCon (FAPPLY  m  cn) (exps_to_Cexps m es))
/\
(exp_to_Cexp m (Var vn) = CVar vn)
/\
(exp_to_Cexp m (Fun vn e) =
  CFun [vn] (exp_to_Cexp m e))
/\
(exp_to_Cexp m (App (Opn opn) e1 e2) =
  let Ce1 = exp_to_Cexp m e1 in
  let Ce2 = exp_to_Cexp m e2 in
  CPrim2 ((case opn of
            Plus   => CAdd
          | Minus  => CSub
          | Times  => CMul
          | Divide => CDiv
          | Modulo => CMod
          ))
  Ce1 Ce2)
/\
(exp_to_Cexp m (App (Opb opb) e1 e2) =
  let Ce1 = exp_to_Cexp m e1 in
  let Ce2 = exp_to_Cexp m e2 in
  (case opb of
    Lt => CPrim2 CLt Ce1 Ce2
  | Leq => CPrim2 CLt (CPrim2 CSub Ce1 Ce2) (CLit (IntLit i1))
  | opb =>
      let x1 = fresh_var (free_vars Ce2) in
      let x2 = fresh_var {x1} in
      CLet [x1;x2] [Ce1;Ce2]
        (case opb of
          Gt =>  CPrim2 CLt (CVar x2) (CVar x1)
        | Geq => CPrim2 CLt (CPrim2 CSub (CVar x2) (CVar x1)) (CLit (IntLit i1))
        )
  ))
/\
(exp_to_Cexp m (App Equality e1 e2) =
  let Ce1 = exp_to_Cexp m e1 in
  let Ce2 = exp_to_Cexp m e2 in
  CPrim2 CEq Ce1 Ce2)
/\
(exp_to_Cexp m (App Opapp e1 e2) =
  let Ce1 = exp_to_Cexp m e1 in
  let Ce2 = exp_to_Cexp m e2 in
  CCall Ce1 [Ce2])
/\
(exp_to_Cexp m (Log log e1 e2) =
  let Ce1 = exp_to_Cexp m e1 in
  let Ce2 = exp_to_Cexp m e2 in
  ((case log of
     And => CIf Ce1 Ce2 (CLit (Bool F))
   | Or  => CIf Ce1 (CLit (Bool T)) Ce2
   )))
/\
(exp_to_Cexp m (If e1 e2 e3) =
  let Ce1 = exp_to_Cexp m e1 in
  let Ce2 = exp_to_Cexp m e2 in
  let Ce3 = exp_to_Cexp m e3 in
  CIf Ce1 Ce2 Ce3)
/\
(exp_to_Cexp m (Mat e pes) =
  let Cpes = pes_to_Cpes m pes in
  let v = fresh_var (Cpes_vars Cpes) in
  let Ce = exp_to_Cexp m e in
  CLet [v] [Ce] (remove_mat_var v Cpes))
/\
(exp_to_Cexp m (Let vn e b) =
  let Ce = exp_to_Cexp m e in
  let Cb = exp_to_Cexp m b in
  CLet [vn] [Ce] Cb)
/\
(exp_to_Cexp m (Letrec defs b) =
  let (fns,Cdefs) = defs_to_Cdefs m defs in
  let Cb = exp_to_Cexp m b in
  CLetfun T fns Cdefs Cb)
/\
(defs_to_Cdefs m [] = ([],[]))
/\
(defs_to_Cdefs m ((d,vn,e)::defs) =
  let Ce = exp_to_Cexp m e in
  let (fns,Cdefs) = defs_to_Cdefs m defs in
  (d::fns,([vn],Ce)::Cdefs))
/\
(pes_to_Cpes m [] = [])
/\
(pes_to_Cpes m ((p,e)::pes) =
  let (_pvs,Cp) = pat_to_Cpat m [] p in
  let Ce = exp_to_Cexp m e in
  let Cpes = pes_to_Cpes m pes in
  (Cp,Ce)::Cpes)
/\
(exps_to_Cexps s [] = [])
/\
(exps_to_Cexps m (e::es) =
  exp_to_Cexp m e:: exps_to_Cexps m es)`;

val _ = Defn.save_defn exp_to_Cexp_defn;

(* conversions between values in different languages *)

 val v_to_Cv_defn = Hol_defn "v_to_Cv" `

(v_to_Cv m (Litv l) = CLitv l)
/\
(v_to_Cv m (Conv cn vs) =
  CConv (FAPPLY  m  cn) (vs_to_Cvs m vs))
/\
(v_to_Cv m (Closure env vn e) =
  let Cenv =alist_to_fmap (env_to_Cenv m env) in
  let Ce = exp_to_Cexp m e in
  let a = fresh_var (free_vars Ce) in
  CRecClos Cenv [a] [([vn],Ce)] a)
/\
(v_to_Cv m (Recclosure env defs vn) =
  let Cenv =alist_to_fmap (env_to_Cenv m env) in
  let (fns,Cdefs) = defs_to_Cdefs m defs in
  CRecClos Cenv fns Cdefs vn)
/\
(vs_to_Cvs m [] = [])
/\
(vs_to_Cvs m (v::vs) = v_to_Cv m v:: vs_to_Cvs m vs)
/\
(env_to_Cenv m [] = [])
/\
(env_to_Cenv m ((x,v)::env) =
  (x, v_to_Cv m v)::(env_to_Cenv m env))`;

val _ = Defn.save_defn v_to_Cv_defn;

(*
let rec
Cv_to_bv (CLitv (IntLit i)) = Number i
and
Cv_to_bv (CLitv (Bool b)) = Number (bool_to_int b)
and
Cv_to_bv (CConv n vs) = Block n (Cvs_to_bvs vs)
and
Cv_to_bv (CClosure env vs b) = Block 0 [CodePtr ?, ?]
and
Cv_to_bv (CRecClos env ns defs n) = Block 0 [CodePtr ?, ?]
and
Cvs_to_bvs [] = []
and
Cvs_to_bvs (v::vs) = Cv_to_bv v :: Cvs_to_bvs vs
*)

val _ = Define `
 (lookup_conv_ty m ty n = FAPPLY  (FAPPLY  m  ty)  n)`;


 val inst_arg_defn = Hol_defn "inst_arg" `

(inst_arg tvs (NTvar n) = EL  n  tvs)
/\
(inst_arg tvs (NTapp ts tn) = NTapp (MAP (inst_arg tvs) ts) tn)
/\
(inst_arg tvs tt = tt)`;

val _ = Defn.save_defn inst_arg_defn;

 val num_to_bool_defn = Hol_defn "num_to_bool" `

(num_to_bool (0:num) = F)
/\
(num_to_bool 1 = T)`;

val _ = Defn.save_defn num_to_bool_defn;

 val bv_to_ov_defn = Hol_defn "bv_to_ov" `

(bv_to_ov m NTnum (Number i) = OLit (IntLit i))
/\
(bv_to_ov m NTbool (Number i) = OLit (Bool (num_to_bool (Num i))))
/\
(bv_to_ov m (NTapp _ ty) (Number i) =
  OConv (FST (lookup_conv_ty m ty (Num i))) [])
/\
(bv_to_ov m (NTapp tvs ty) (Block n vs) =
  let (tag, args) = lookup_conv_ty m ty n in
  let args = MAP (inst_arg tvs) args in
  OConv tag (MAP2 (\ ty v . bv_to_ov m ty v) args vs)) (* uneta: Hol_defn sucks *)
/\
(bv_to_ov m NTfn (Block 0 _) = OFn)`;

val _ = Defn.save_defn bv_to_ov_defn;


(* TODO: simple type system and checker *)

(* TODO: map_Cexp? *)

(* TODO: use Pmap.peek instead of mem when it becomes available *)
(* TODO: collapse nested functions *)
(* TODO: collapse nested lets *)
(* TODO: Letfun introduction and reordering *)
(* TODO: let floating *)
(* TODO: removal of redundant expressions *)
(* TODO: simplification (e.g., constant folding) *)
(* TODO: avoid Shifts when possible *)
(* TODO: registers, register allocation, greedy shuffling? *)
(* TODO: bytecode optimizer: repeated Pops, unreachable code (e.g. after a Jump) *)

 val error_to_int_defn = Hol_defn "error_to_int" `

(error_to_int Bind_error = i0)
/\
(error_to_int Div_error = i1)`;

val _ = Defn.save_defn error_to_int_defn;

 val prim2_to_bc_defn = Hol_defn "prim2_to_bc" `

(prim2_to_bc CAdd = Add)
/\
(prim2_to_bc CSub = Sub)
/\
(prim2_to_bc CMul = Mult)
/\
(prim2_to_bc CDiv = Div)
/\
(prim2_to_bc CMod = Mod)
/\
(prim2_to_bc CLt = Less)
/\
(prim2_to_bc CEq = Equal)`;

val _ = Defn.save_defn prim2_to_bc_defn;

val _ = Define `
 emit = FOLDL
  (\ s i .  s with<| next_label := s.next_label+ s.inst_length i+ 1;
                        code := i:: s.code; code_length := s.code_length+ 1 |>)`;


 val compile_varref_defn = Hol_defn "compile_varref" `

(compile_varref s (CTLet n) = emit s [Stack (Load (s.sz - n))])
/\
(compile_varref s (CTArg n) = emit s [Stack (Load (s.sz+ n))])
/\
(compile_varref s (CTEnv n) = emit s [Stack (Load s.sz); Stack (El n)])
/\
(compile_varref s (CTRef n) = emit (compile_varref s (CTEnv n)) [Deref])`;

val _ = Defn.save_defn compile_varref_defn;

val _ = Define `
 (incsz s =  s with<| sz := s.sz+ 1 |>)`;

val _ = Define `
 (decsz s =  s with<| sz := s.sz - 1 |>)`;

val _ = Define `
 (sdt s = ( s with<| decl :=NONE; tail := TCNonTail |>, (s.decl,s.tail)))`;

val _ = Define `
 (ldt (d,t) s =  s with<| decl := d; tail := t |>)`;


(* helper for reconstructing closure environments *)
val _ = Hol_datatype `
 cebind = CEEnv of string | CERef of num`;


 val emit_ec_defn = Hol_defn "emit_ec" `

(emit_ec z s (CEEnv fv) = incsz (compile_varref s (FAPPLY  s.env  fv)))
/\
(emit_ec z s (CERef j) = incsz (emit s [Stack (Load (s.sz - z - j))]))`;

val _ = Defn.save_defn emit_ec_defn;

 val replace_calls_defn = Hol_defn "replace_calls" `

(replace_calls j [_] c = c)
/\
(replace_calls j ((_,lab)::(jl,l)::ls) c =
  replace_calls j ((jl,l)::ls)
    (REPLACE_ELEMENT (Call lab) (j - jl) c))`;

val _ = Defn.save_defn replace_calls_defn;

 val bind_fv_defn = Hol_defn "bind_fv" `

(bind_fv ns xs az k fv (n,env,((ecl:num),ec)) =
  (case find_index fv xs 1 of
   SOME j => (n, FUPDATE  env ( fv, (CTArg (2+ az - j))), (ecl,ec))
  |NONE => (case find_index fv ns 0 of
     NONE => (n+1, FUPDATE  env ( fv, (CTEnv n)), (ecl+1,CEEnv fv::ec))
    |SOME j => if j= k
                then (n, FUPDATE  env ( fv, (CTArg (2+ az))), (ecl,ec))
                else (n+1, FUPDATE  env ( fv, (CTRef n)), (ecl+1,(CERef (j+1))::ec))
    )
  ))`;

val _ = Defn.save_defn bind_fv_defn;

 val compile_defn = Hol_defn "compile" `

(compile s (CDecl vs) =
  (case s.decl of SOME (env0,sz0) =>
  let sz1 = s.sz in
  let k = sz1 - sz0 in
  let (s,i,env) = FOLDL
    (\ (s,i,env) v .
      if  v IN FDOM  env0 then
        ((case FAPPLY  env0  v of
           CTLet x => emit (compile_varref s (FAPPLY  s.env  v))
                           [Stack (Store (s.sz - x))]
         | _ => emit s [Stack (PushInt i2); Exception] (* should not happen *)
         ), i, env)
      else
        (incsz (compile_varref s (FAPPLY  s.env  v)),
         i+1,
         FUPDATE  env ( v, (CTLet i))))
         (s,sz0+1,env0) vs in
  let s = emit s [Stack (Shift (i -(sz0+1)) k)] in
   s with<| sz := sz1+1; decl :=SOME (env,s.sz - k) |>
  |NONE => emit s [Stack (PushInt i2); Exception] (* should not happen *)
  ))
/\
(compile s (CRaise err) =
  incsz (emit s [Stack (PushInt (error_to_int err)); Exception]))
/\
(compile s (CLit (IntLit i)) =
  incsz (emit s [Stack (PushInt i)]))
/\
(compile s (CLit (Bool b)) =
  incsz (emit s [Stack (PushInt (bool_to_int b))]))
/\
(compile s (CVar vn) = incsz (compile_varref s (FAPPLY  s.env  vn)))
/\
(compile s (CCon n es) =
  let z = s.sz+ 1 in
  let (s,dt) = sdt s in
  let s = FOLDL (\ s e . compile s e) s es in (* uneta because Hol_defn sucks *)
  let s = emit (ldt dt s) [Stack (Cons n (LENGTH es))] in
   s with<| sz := z |>)
/\
(compile s (CTagEq e n) =
  let (s,dt) = sdt s in
  ldt dt (emit (compile s e) [Stack (TagEq n)]))
/\
(compile s (CProj e n) =
  let (s,dt) = sdt s in
  ldt dt (emit (compile s e) [Stack (El n)]))
/\
(compile s (CLet xs es e) =
  let z = s.sz+ 1 in
  let (s,dt) = sdt s in
  let s = FOLDL (\ s e . compile s e) s es in (* uneta because Hol_defn sucks *)
  compile_bindings s.env z e 0 (ldt dt s) xs)
/\
(compile s (CLetfun recp ns defs e) =
  let z = s.sz+ 1 in
  let s = compile_closures (if recp then ns else []) s defs in
  compile_bindings s.env z e 0 s ns)
/\
(compile s (CFun xs e) =
  compile_closures [] s [(xs,e)])
/\
(compile s (CCall e es) =
  let n = LENGTH es in
  let t = s.tail in
  let (s,dt) = sdt s in
  let s = (case t of
    TCNonTail =>
    let s = compile s e in
    let s = FOLDL (\ s e . compile s e) s es in (* uneta because Hol_defn sucks *)
    (* argn, ..., arg2, arg1, Block 0 [CodePtr c; env], *)
    let s = emit s [Stack (Load n); Stack (El 1)] in
    (* env, argn, ..., arg1, Block 0 [CodePtr c; env], *)
    let s = emit s [Stack (Load (n+1)); Stack (El 0)] in
    (* CodePtr c, env, argn, ..., arg1, Block 0 [CodePtr c; env], *)
    emit s [CallPtr]
    (* before: env, CodePtr ret, argn, ..., arg1, Block 0 [CodePtr c; env], *)
    (* after:  retval, *)
(* does it make sense to distinguish this case?
  | TCTop sz0 ->
    let k = match s.decl with None -> s.sz - sz0 | Some _ -> 0 end in
    let n1 = 1+1+n+1 in
    let (i,s) = pad k n1 s in
    let s = compile s e in
    let s = List.fold_left (fun s e -> compile s e) s es in (* uneta because Hol_defn sucks *)
    (* argn, ..., arg1, Block 0 [CodePtr c; env], 0i, ..., 01, vk, ..., v1, *)
    let s = emit s [Stack (Load n); Stack (El 1)] in
    (* env, argn, ..., arg1, Block 0 [CodePtr c; env], 0i, ..., 01, vk, ..., v1, *)
    let s = emit s [Stack (Load (n+1)); Stack (El 0)] in
    (* CodePtr c, env, argn, ..., arg1, Block 0 [CodePtr c; env], 0i, ..., 01, vk, ..., v1, *)
    let s = mv (k+i) n1 s in
    (* CodePtr c, env, argn, ..., arg1, Block 0 [CodePtr c; env], *)
    emit s [CallPtr]
*)
  | TCTail j k =>
    let s = compile s e in
    let s = FOLDL (\ s e . compile s e) s es in (* uneta because Hol_defn sucks *)
    (* argn, ..., arg1, Block 0 [CodePtr c; env],
     * vk, ..., v1, env1, CodePtr ret, argj, ..., arg1, Block 0 [CodePtr c1; env1], *)
    let s = emit s [Stack (Load (n+1+k+1))] in
    (* CodePtr ret, argn, ..., arg1, Block 0 [CodePtr c; env],
     * vk, ..., v1, env1, CodePtr ret, argj, ..., arg1, Block 0 [CodePtr c1; env1], *)
    let s = emit s [Stack (Load (n+1)); Stack (El 1)] in
    (* env, CodePtr ret, argn, ..., arg1, Block 0 [CodePtr c; env],
     * vk, ..., v1, env1, CodePtr ret, argj, ..., arg1, Block 0 [CodePtr c1; env1], *)
    let s = emit s [Stack (Load (n+2)); Stack (El 0)] in
    (* CodePtr c, env, CodePtr ret, argn, ..., arg1, Block 0 [CodePtr c; env],
     * vk, ..., v1, env1, CodePtr ret, argj, ..., arg1, Block 0 [CodePtr c1; env1], *)
    let s = emit s [Stack (Shift (1+1+1+n+1) (k+1+1+j+1))] in
    emit s [JumpPtr]
  ) in
  ldt dt  s with<| sz := s.sz - n |>)
/\
(compile s (CPrim2 op e1 e2) =
  let (s,dt) = sdt s in
  let s = compile s e1 in
  let s = compile s e2 in (* TODO: need to detect div by zero *)
  decsz (ldt dt (emit s [Stack (prim2_to_bc op)])))
/\
(compile s (CIf e1 e2 e3) =
  let (s,dt) = sdt s in
  let s = ldt dt (compile s e1) in
  let s = emit s [JumpNil 0; Jump 0] in
  let j1 = s.code_length in
  let n1 = s.next_label in
  let s = compile (decsz s) e2 in
  let s = emit s [Jump 0] in
  let j2 = s.code_length in
  let n2 = s.next_label in
  let s = compile (decsz s) e3 in
  let n3 = s.next_label in
  let j3 = s.code_length in
   s with<| code :=
      (REPLACE_ELEMENT (Jump n3) (j3 - j2)
      (REPLACE_ELEMENT (Jump n2) (j3 - j1)
      (REPLACE_ELEMENT (JumpNil n1) (j3 - j1+ 1) s.code))) |>)
/\
(compile_bindings env0 sz1 e n s [] =
  let s = (case s.tail of
    TCTail j k => compile ( s with<| tail := TCTail j (k+n) |>) e
  | TCNonTail => (case s.decl of
     NONE => emit (compile s e) [Stack (Pops n)]
    |SOME _ => compile s e
    )
  ) in
   s with<| env := env0 ; sz := sz1 |>)
/\
(compile_bindings env0 sz1 e n s (x::xs) =
  compile_bindings env0 sz1 e
    (n+1) (* parentheses below because Lem sucks *)
    ( s with<| env := FUPDATE  s.env ( x, (CTLet (sz1+ n))) |>)
    xs)
/\
(compile_closures ns s defs =
  (* calling convention:
   * before: env, CodePtr ret, argn, ..., arg1, Block 0 [CodePtr c; env],
   * thus, since env = stack[sz], argk should be CTArg (2 + n - k)
   * after:  retval,
       PushInt 0, Ref
       ...            (* create RefPtrs for recursive closures *)
       PushInt 0, Ref                       RefPtr 0, ..., RefPtr 0, rest
       PushInt 0                            0, RefPtr 0, ..., RefPtr 0, rest
       Call L1                              0, CodePtr f1, RefPtr 0, ..., RefPtr 0, rest
       ?
       ...      (* function 1 body *)
       Pops ?   (* delete local variables and env *)
       Load 1
       Store n+2(* replace closure with return pointer *)
       Pops n+1 (* delete arguments *)
       Return
   L1: Call L2                              0, CodePtr f2, CodePtr f1, RefPtrs, rest
       ?
       ...      (* function 2 body *)
       Return
   L2: Call L3
       ?
       ...      (* more function bodies *)
   ...
       Return
   LK: Call L
       ...
       Return   (* end of last function *)
   L:  Pop                                  CodePtr fk, ..., CodePtr f1, RefPtrs, rest
       Load ?   (* copy code pointer for function 1 *)
       Load ?   (* copy free mutrec vars for function 1 *)
       Load ?   (* copy free vars for function 1 *)
       ...                                  vm1, ..., v1, RefPtr 0, ..., RefPtr 0, CodePtr f1, CodePtr fk, ..., CodePtr f1, RefPtrs, rest
       Cons 0 (m1 + n1)
       Cons 0 2                             Block 0 [CodePtr f1; Block 0 Env], CodePtr fk, ..., CodePtr f1, RefPtrs, rest
       Store ?                              CodePtr fk, ..., CodePtr f2, f1, RefPtrs, rest
       Load ?   (* copy code pointer for function 2 *)
       Load ?   (* copy free mutrec vars for function k-1 *)
       Load ?   (* copy free vars for function k-1 *)
       ...
       Cons 0 (m2 + n2)
       Cons 0 2
       Store ?                              CodePtr fk, ..., CodePtr f3, f2, f1, RefPtrs, rest
       ...                                  fk, ..., f2, f1, RefPtrs, rest
       Load ?
       Load 1                               fk, RefPtr 0, fk, f(k-1), ..., RefPtrs, rest
       Update                               fk, f(k-1), ..., f1, RefPtrs, rest
       Load ?
       Load 2
       Update
       ...      (* update RefPtrs with closures *)
       Store ?  (* pop RefPtrs *)           fk, f(k-1), ..., f1, rest
       ...
  *)
  (*
   * - push refptrs and leading 0
   * - for each function (in order), push a Call 0, remember the next label,
   *   calculate its environment, remember the environment, compile its body in
   *   that environment
   * - update Calls
   * - for each environment emit code to load that
   *   environment and build the closure
   * - update refptrs, etc.
   *)
  let sz0 = s.sz in
  let s = FOLDL (\ s _n . incsz (emit s [Stack (PushInt i0); Ref])) s ns in
  let s = emit s [Stack (PushInt i0)] in
  let (s,k,labs,ecs) = FOLDL
    (\ (s,k,labs,ecs) (xs,e) .
      let az = LENGTH xs in
      let lab = s.next_label in
      let s = emit s [Call 0] in
      let j = s.code_length in
      let (n,env,(ecl,ec)) =
        ITSET (bind_fv ns xs az k) (free_vars e) (0,FEMPTY,(0,[])) in
      let s' =  s with<| env := env; sz := 0; tail := TCTail az 0 |> in
      let s' = compile s' e in
      let n = (case s'.tail of TCNonTail => 1 | TCTail j k => k+1 ) in
      let s' = emit s' [Stack (Pops n);
                        Stack (Load 1);
                        Stack (Store (az+2));
                        Stack (Pops (az+1));
                        Return] in
      let s =  s' with<| env := s.env; sz := s.sz+ 1; tail := s.tail |> in
      (s,k+1,(j,lab)::labs,(ecl,ec)::ecs))
    (s,0,[],[]) defs in
  let s =  s with<| code :=
    replace_calls s.code_length ((0,s.next_label)::labs) s.code |> in
  let s = emit s [Stack Pop] in
  let nk = LENGTH defs in
  let (s,k) = FOLDL
    (\ (s,k) (j,ec) .
      let s = incsz (emit s [Stack (Load (nk - k))]) in
      let s = FOLDL (emit_ec sz0) s (REVERSE ec) in
      let s = emit s [Stack (if j= 0 then PushInt i0 else Cons 0 j)] in
      let s = emit s [Stack (Cons 0 2)] in
      let s = decsz (emit s [Stack (Store (nk - k))]) in
      let s =  s with<| sz := s.sz - j |> in
      (s,k+1))
    (s,1) (REVERSE ecs) in
  let (s,k) = FOLDL
    (\ (s,k) _n .
      let s = emit s [Stack (Load (nk+ nk - k))] in
      let s = emit s [Stack (Load (nk+ 1 - k))] in
      let s = emit s [Update] in
      (s,k+1))
    (s,1) ns in
  let k = nk - 1 in
  FOLDL
    (\ s _n . decsz (emit s [Stack (Store k)]))
         s ns)`;

val _ = Defn.save_defn compile_defn;

val _ = Hol_reln `
(! il c cc.
T
==>
bc_code_prefix il (APPEND c cc) (0:num) c)
/\
(! il p i c cc.
bc_code_prefix il cc p c
==>
bc_code_prefix il (i::cc) (p+ il i) c)`;

 val body_cs_defn = Hol_defn "body_cs" `

(body_cs il env xs lab =
  <| env := env; sz := 0; tail := TCTail (LENGTH xs) 0;
     code := []; code_length := 0;
     next_label := lab;
     decl :=NONE;
     inst_length := il |>)`;

val _ = Defn.save_defn body_cs_defn;

 val body_env_defn = Hol_defn "body_env" `

(body_env ns xs j fvs =
  let (n,env,(nec,ec)) =
    ITSET (bind_fv ns xs (LENGTH xs) j) fvs (0,FEMPTY,(0,[])) in
  (env,ec))`;

val _ = Defn.save_defn body_env_defn;

val _ = Hol_reln `
(! il c i.
T
==>
bceqv il c (CLitv (IntLit i)) (Number i))
/\
(! il c b.
T
==>
bceqv il c (CLitv (Bool b)) (Number (bool_to_int b)))
/\
(! il c n vs bvs.EVERY2 (bceqv il c) vs bvs
==>
bceqv il c (CConv n vs) (Block n bvs))
/\
(! il c env ns defs n j xs e cenv ec f bvs lab.(
find_index n ns 0=SOME j)/\
(EL  j  defs= (xs,e))/\
((cenv,ec)= body_env ns xs j (free_vars e))/\
(LENGTH bvs= LENGTH ec)/\
(! i. i< LENGTH ec==>
    (? fv. (EL  i  ec= CEEnv fv)/\
               bceqv il c (FAPPLY  env  fv) (EL  i  bvs))\/
    (? k kxs ke kenv kec g l.
        (EL  i  ec= CERef k)/\
        (EL  k  defs= (kxs,ke))/\
        ((kenv,kec)= body_env ns xs k (free_vars ke))/\
        bc_code_prefix il c g
          (REVERSE (compile (body_cs il kenv kxs l) ke).code)))/\
bc_code_prefix il c f (REVERSE (compile (body_cs il cenv xs lab) e).code)
==>
bceqv il c (CRecClos env ns defs n)
  (Block 0 [CodePtr f; if bvs= [] then Number i0 else Block 0 bvs]))`;

val _ = Define `
 init_compiler_state =
  <| env := FEMPTY
   ; code := []
   ; code_length := 0
   ; next_label := 0 (* depends on exception handlers *)
   ; sz := 0
   ; inst_length := \ i . 0 (* depends on runtime *)
   ; decl :=NONE
   ; tail := TCNonTail
   |>`;


val _ = Define `
 init_repl_state =
  <| cmap := FEMPTY
   ; cpam := FEMPTY
   ; cs := init_compiler_state
   |>`;


val _ = Define `
 (compile_Cexp rs Ce =
  let cs =  rs.cs with<| code := [] ; code_length := 0 |> in
  let cs = compile cs Ce in
  let cs = (case cs.decl of
     NONE => cs
    |SOME (env,sz) =>  cs with<| env := env ; sz := sz |>
    ) in
   rs with<| cs := cs |>)`;


(* TODO: typechecking *)
(* TODO: printing *)

 val number_constructors_defn = Hol_defn "number_constructors" `

(number_constructors a (cm,cw) (n:num) [] = (cm,cw))
/\
(number_constructors a (cm,cw) n ((c,tys)::cs) =
  let cm' = FUPDATE  cm ( c, n) in
  let cw' = FUPDATE  cw ( n, (c, MAP (t_to_nt a) tys)) in
  number_constructors a (cm',cw') (n+1) cs)`;

val _ = Defn.save_defn number_constructors_defn;

 val repl_dec_defn = Hol_defn "repl_dec" `

(repl_dec rs (Dtype []) =
   rs with<| cs := rs.cs with<| code := []; code_length := 0|> |>)
/\
(repl_dec rs (Dtype ((a,ty,cs)::ts)) =
  let (cm,cw) = number_constructors a (rs.cmap,FEMPTY) 0 cs in
  repl_dec ( rs with<| cmap := cm; cpam := FUPDATE  rs.cpam ( ty, cw) |>) (Dtype ts)) (* parens: Lem sucks *)
/\
(repl_dec rs (Dletrec defs) =
  let (fns,Cdefs) = defs_to_Cdefs rs.cmap defs in
  let rs = rs with<| cs := rs.cs with<| decl:=SOME(rs.cs.env,rs.cs.sz)|> |> in
  compile_Cexp rs (CLetfun T fns Cdefs (CDecl fns)))
/\
(repl_dec rs (Dlet p e) =
  let (pvs,Cp) = pat_to_Cpat rs.cmap [] p in
  let Cpes = [(Cp,CDecl pvs)] in
  let vn = fresh_var (Cpes_vars Cpes) in
  let Ce = exp_to_Cexp rs.cmap e in
  let rs' = rs with<| cs := rs.cs with<| decl:=SOME(rs.cs.env,rs.cs.sz)|> |> in
  compile_Cexp rs' (CLet [vn] [Ce] (remove_mat_var vn Cpes)))`;

val _ = Defn.save_defn repl_dec_defn;

val _ = Define `
 (repl_exp s exp =
  compile_Cexp (s with<| cs := s.cs with<| decl:=NONE|> |>) (exp_to_Cexp s.cmap exp))`;
 (* parens *)

(* Constant folding
val fold_consts : exp -> exp

let rec
fold_consts (Raise err) = Raise err
and
fold_consts (Val v) = Val (v_fold_consts v)
and
fold_consts (Con c es) = Con c (List.map fold_consts es)
and
fold_consts (Var vn) = Var vn
and
fold_consts (Fun vn e) = Fun vn (fold_consts e)
and
fold_consts (App (Opn opn) (Val (Lit (IntLit n1))) (Val (Lit (IntLit n2)))) =
  Val (Lit (IntLit (opn_lookup opn n1 n2)))
and
fold_consts (App (Opb opb) (Val (Lit (IntLit n1))) (Val (Lit (IntLit n2)))) =
  Val (Lit (Bool (opb_lookup opb n1 n2)))
and
fold_consts (App Equality (Val (Lit (IntLit n1))) (Val (Lit (IntLit n2)))) =
  Val (Lit (Bool (n1 = n2)))
and
fold_consts (App Equality (Val (Lit (Bool b1))) (Val (Lit (Bool b2)))) =
  Val (Lit (Bool (b1 = b2)))
and
fold_consts (App op e1 e2) =
  let e1' = fold_consts e1 in
  let e2' = fold_consts e2 in
  if e1 = e1' && e2 = e2' then (App op e1 e2) else
  fold_consts (App op e1' e2')
and
fold_consts (Log And (Val (Lit (Bool true))) e2) =
  fold_consts e2
and
fold_consts (Log Or (Val (Lit (Bool false))) e2) =
  fold_consts e2
and
fold_consts (Log _ (Val (Lit (Bool b))) _) =
  Val (Lit (Bool b))
and
fold_consts (Log log e1 e2) =
  Log log (fold_consts e1) (fold_consts e2)
and
fold_consts (If (Val (Lit (Bool b))) e2 e3) =
  if b then fold_consts e2 else fold_consts e3
and
fold_consts (If e1 e2 e3) =
  If (fold_consts e1) (fold_consts e2) (fold_consts e3)
and
fold_consts (Mat (Val v) pes) =
  fold_match v pes
and
fold_consts (Mat e pes) =
  Mat (fold_consts e) (match_fold_consts pes)
and
fold_consts (Let vn e1 e2) =
  Let vn (fold_consts e1) (fold_consts e2)
and
fold_consts (Letrec funs e) =
  Letrec (funs_fold_consts funs) (fold_consts e)
and
fold_consts (Proj (Val (Conv None vs)) n) =
  Val (List.nth vs n)
and
fold_consts (Proj e n) = Proj (fold_consts e) n
and
v_fold_consts (Lit l) = Lit l
and
v_fold_consts (Conv None vs) =
  Conv None (List.map v_fold_consts vs)
and
v_fold_consts (Closure envE vn e) =
  Closure (env_fold_consts envE) vn (fold_consts e)
and
v_fold_consts (Recclosure envE funs vn) =
  Recclosure (env_fold_consts envE) (funs_fold_consts funs) vn
and
env_fold_consts [] = []
and
env_fold_consts ((vn,v)::env) =
  ((vn, v_fold_consts v)::env_fold_consts env)
and
funs_fold_consts [] = []
and
funs_fold_consts ((vn1,vn2,e)::funs) =
  ((vn1,vn2,fold_consts e)::funs_fold_consts funs)
and
match_fold_consts [] = []
and
match_fold_consts ((p,e)::pes) =
  (p, fold_consts e)::match_fold_consts pes
and
fold_match v [] = Raise Bind_error
and
fold_match (Lit l) ((Plit l',e)::pes) =
  if l = l' then
    fold_consts e
  else
    fold_match (Lit l) pes
and
(* TODO: fold more pattern matching (e.g. to Let)? Need envC? *)
fold_match v pes =
  Mat (Val v) (match_fold_consts pes)
*)
val _ = export_theory()

