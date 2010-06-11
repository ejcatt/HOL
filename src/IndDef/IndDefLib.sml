structure IndDefLib :> IndDefLib =
struct

local open IndDefRules in end;

open HolKernel Abbrev;

type monoset = InductiveDefinition.monoset;

val ERR = mk_HOL_ERR "IndDefLib";
val ERRloc = mk_HOL_ERRloc "IndDefLib";

local open Absyn
      fun head clause =
         let val appl = last (strip_imp (snd(strip_forall clause)))
         in fst(strip_app appl)
         end
      fun determ M =
          fst(Term.dest_var M handle HOL_ERR _ => Term.dest_const M)
           handle HOL_ERR _ => raise ERR "determ" "Non-atom in antiquote"
      fun dest (AQ (_,tm)) = determ tm
        | dest (IDENT (_,s)) = s
        | dest other = raise ERRloc "names_of.reln_names.dest"
                                    (locn_of_absyn other) "Unexpected structure"
in
fun term_of_absyn absyn = let
  val clauses   = strip_conj absyn
  fun checkcl a = let
    val nm = dest (head a)
  in
    if mem nm ["/\\", "\\/", "!", "?", UnicodeChars.conj,
               UnicodeChars.disj, UnicodeChars.forall, UnicodeChars.exists]
    then
      raise ERRloc "term_of_absyn" (locn_of_absyn a)
                   ("Abstract syntax looks to be trying to redefine "^nm^". "^
                     "This is probably an error.\nIf you must, define with \
                     \another name and use overload_on")
    else nm
  end
  val names     = mk_set (map checkcl clauses)
  val resdata   = List.map (fn s => (s, Parse.hide s)) names
  fun restore() =
      List.app (fn (s,d) => Parse.update_overload_maps s d) resdata
  val tm =
      Parse.absyn_to_term (Parse.term_grammar()) absyn
      handle e => (restore(); raise e)
in
  restore();
  (tm, map locn_of_absyn clauses)
end

fun term_of q = term_of_absyn (Parse.Absyn q)

end;

(* ----------------------------------------------------------------------
    Store all rule inductions
   ---------------------------------------------------------------------- *)

val term_rule_map : (term,thm list)Binarymap.dict ref =
    ref (Binarymap.mkDict Term.compare)

fun listdict_add (d, k, e) =
    case Binarymap.peek(d, k) of
      NONE => Binarymap.insert(d,k,[e])
    | SOME l => Binarymap.insert(d,k,e::l)

fun rule_induction_map() = !term_rule_map

fun ind_thm_to_consts thm = let
  open boolSyntax
  val c = concl thm
  val (_, bod) = strip_forall c
  val (_, con) = dest_imp bod
  val cons = strip_conj con
in
  map (fn t => t |> strip_forall |> #2 |> dest_imp |> #1 |> strip_comb |> #1)
      cons
end

fun add_rule_induction th = let
  val nm = current_theory()
  val ts = ind_thm_to_consts th
in
  term_rule_map := List.foldl (fn (t,d) => listdict_add(d,t,th))
                              (!term_rule_map)
                              ts
end

(* making it exportable *)
val {export = export_rule_induction, dest, ...} =
    ThmSetData.new_exporter "rule_induction" (app add_rule_induction)

fun thy_rule_inductions thyname = let
  val segdata =
    LoadableThyData.segment_data {thy = thyname, thydataty = "rule_induction"}
in
  case segdata of
    NONE => []
  | SOME d => map #2 (valOf (dest d))
end

(* ----------------------------------------------------------------------
    the built-in monoset, that users can update as they prove new
    monotonicity results about their constants
   ---------------------------------------------------------------------- *)

val the_monoset = ref InductiveDefinition.bool_monoset

fun mono_name th = let
  open boolLib
  val (_, con) = dest_imp (concl th)
in
  #1 (dest_const (#1 (strip_comb (#1 (dest_imp con)))))
end

fun add_mono_thm th = the_monoset := (mono_name th, th) :: (!the_monoset)

(* making it exportable *)
val {export = export_mono, dest, ...} =
    ThmSetData.new_exporter "mono" (app add_mono_thm)

fun thy_monos thyname =
    case LoadableThyData.segment_data {thy = thyname, thydataty = "mono"} of
      NONE => []
    | SOME d => map #2 (valOf (dest d))

(*---------------------------------------------------------------------------
  given a case theorem of the sort returned by new_inductive_definition
  return the name of the first new constant mentioned
  form is
        (!x y z.  (C x y z = ...)) /\
        (!u v w.  (D u v w = ...))
   in which case we return ["C", "D"]
 ---------------------------------------------------------------------------*)

fun names_from_casethm thm = let
  open HolKernel boolSyntax
  val forallbod = #2 o strip_forall
  val eqns = thm |> concl |> forallbod |> strip_conj |> map forallbod
  val cnsts = map (#1 o strip_comb o lhs) eqns
in
  map (#1 o dest_const) cnsts
end

val derive_mono_strong_induction = IndDefRules.derive_mono_strong_induction;
fun derive_strong_induction (rules,ind) =
    IndDefRules.derive_mono_strong_induction (!the_monoset) (rules, ind)

fun Hol_mono_reln monoset tm = let
  val (rules, indn, cases) =
      InductiveDefinition.new_inductive_definition monoset tm
      (* not! InductiveDefinition.bool_monoset tm *)
  val names = names_from_casethm cases
  val name = hd names
  val strong_ind = derive_strong_induction (rules, indn)
  val _ = save_thm(name^"_rules", rules)
  val _ = save_thm(name^"_ind", indn)
  val _ = save_thm(name^"_strongind", strong_ind)
  val _ = save_thm(name^"_cases", cases)
  val _ = export_rule_induction (name ^ "_strongind")
in
  (rules, indn, cases)
end
handle e => raise (wrap_exn "IndDefLib" "Hol_mono_reln" e);


(* ----------------------------------------------------------------------
    the standard entry-point
   ---------------------------------------------------------------------- *)

fun Hol_reln q =
    Hol_mono_reln (!the_monoset) (term_of q)
    handle e => Raise (wrap_exn "IndDefLib" "Hol_reln" e);

end
