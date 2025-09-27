
-- Experimental lean backend for Hax
-- The Hax prelude library can be found in hax/proof-libs/lean
import Hax
import Std.Tactic.Do
import Std.Do.Triple
import Std.Tactic.Do.Syntax
open Std.Do
open Std.Tactic

set_option mvcgen.warning false
set_option linter.unusedVariables false

structure Rust.ViskaSATExtension where


-- to debug missing item run: `just debug-json 0`

def Rust.__static_type_check  (_ : Rust_primitives.Hax.Tuple0)
  : Result Rust_primitives.Hax.Tuple0
  := do
  (← Rust_primitives.Hax.failure
    "ExplicitRejection { reason: "a node of kind [Raw_pointer] have been found in the AST" }

[90m
Note: the error was labeled with context `reject_RawOrMutPointer`.
[0m"
    "{
 let pat_ascription!(
 _unused as core::option::t_Option < arrow!(core::option::t_Option <
 arrow!(raw_pointer!() -> core::option::t_Option < arrow!(tuple0 -> tuple0) >)
 > -> raw_pointer!() -> raw_...")