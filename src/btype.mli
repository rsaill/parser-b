type t_alias
val no_alias: t_alias

module Unif :
sig
  type t =
    | T_Atomic of string
    | T_Power of t
    | T_Product of t * t
    | T_Record of (string*t) list
    | T_UVar of uv ref
  and uv = Unbound of int | Bound of t

  val t_int : t
  val t_bool : t
  val t_string : t

  val type_of_unary_fun : t -> t -> t 
  val type_of_binary_fun : t -> t -> t -> t 
  val type_of_sequence : t -> t 

  val to_string : t -> string
  val equal : t -> t -> bool

  val new_meta : unit -> t

  val get_stype : t_alias -> t -> t -> t option
end

type t

val t_int : t
val t_bool : t
val t_string : t

val to_string : t -> string
val equal : t -> t -> bool

val close : Unif.t -> t option
val to_unif: t -> Unif.t

val mk_Atomic : string -> t
val mk_Power : t -> t
val mk_Product : t -> t -> t
val mk_Record : (string*t) list -> t

type t_view =
  | T_Atomic of string
  | T_Power of t
  | T_Product of t * t
  | T_Record of (string*t) list

val view : t -> t_view

val is_equal_modulo_alias : t_alias -> t -> t -> bool
val add_alias : t_alias -> string -> t -> t_alias option
