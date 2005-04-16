(*****************************************************************************)
(* Another example to illiustrate adding a component (see ../README).        *)
(*****************************************************************************)

quietdec := true;
loadPath := "../" :: "word32" :: "../dff/" :: !loadPath;
map load
 ["compileTheory","compile","metisLib","intLib","word32Theory", "word32Lib",
  "dffTheory","vsynth" ,"compile32Theory"];
open compile metisLib word32Theory;
open arithmeticTheory intLib pairLib pairTheory PairRules combinTheory
     devTheory composeTheory compileTheory compile vsynth dffTheory
     compile32Theory;
quietdec := false;

infixr 3 THENR;
infixr 3 ORELSER;
intLib.deprecate_int();

(*****************************************************************************)
(* Boilerplate. Probably more than is needed.                                *)
(*****************************************************************************)
add_combinational ["MOD","WL","DIV"];
add_combinational ["word_add","word_sub"];
add_combinational ["BITS","HB","w2n","n2w"];

(*****************************************************************************)
(* Start new theory "NotXor32"                                               *)
(*****************************************************************************)
val _ = new_theory "NotXor32";

(*****************************************************************************)
(* Load definitions of XOR32 and NOT32                                       *)
(*****************************************************************************)
use "XOR32.ml";
use "NOT32.ml";

(*****************************************************************************)
(* Implement an atomic device computing XOR                                  *)
(*****************************************************************************)
val (NotXor32,_,NotXor32_dev) =
 hwDefine
  `NotXor32(in1,in2) = ((in1 # in2), ~(in1 # in2))`;

(*****************************************************************************)
(* Derivation using refinement combining combinators                         *)
(*****************************************************************************)
val NotXor32Imp_dev =
 REFINE
  (DEPTHR ATM_REFINE)
  NotXor32_dev;

val NotXor32_cir =
 save_thm
  ("NotXor32_cir",
   time MAKE_CIRCUIT NotXor32Imp_dev);

(*****************************************************************************)
(* This dumps changes to all variables. Set to false to dump just the        *)
(* changes to module NotXor32.                                               *)
(*****************************************************************************)
dump_all_flag := true; 

verilog_simulator := iverilog;
waveform_viewer   := gtkwave;

(*****************************************************************************)
(* Stop zillions of warning messages that HOL variables of type ``:num``     *)
(* are being converted to Verilog wires or registers of type [31:0].         *)
(*****************************************************************************)
numWarning := false;

SIMULATE NotXor32_cir [("inp1","537"),("inp2","917")];

val _ = export_theory();
