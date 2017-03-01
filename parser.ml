open Utils
open Lexer_with_pp

module I = Grammar.MenhirInterpreter

let loc_from_env env : Lexing.position =
  let (start,_) = I.positions env in
  start

let rec loop_exn (state:state) (chkp:Component.component I.checkpoint) : Component.component =
  match chkp with
  | I.InputNeeded env -> loop_exn state (I.offer chkp (get_next_exn state))
  | I.Shifting _
  | I.AboutToReduce _ -> loop_exn state (I.resume chkp)
  | I.HandlingError env ->
    raise (Utils.Error (loc_from_env env, "Syntax error: unexpected token '"
                                          ^ get_last_token_str state ^ "'."))
  | I.Accepted v -> v
  | I.Rejected -> assert false (*unreachable*)

let parse_component (filename:string) (input:in_channel) : (Component.component,loc*string) result =
  try
    let state = mk_state_from_channel_exn filename input in
    Ok (loop_exn state (Grammar.Incremental.component_eof (get_current_pos state)))
  with
| Utils.Error (p,msg) -> Error (p,msg)

let parse_component_from_string (input:string) : (Component.component,loc*string) result =
  try
    let state = mk_state_from_string_exn input in
    Ok (loop_exn state (Grammar.Incremental.component_eof (get_current_pos state)))
  with
| Utils.Error (p,msg) -> Error (p,msg)
