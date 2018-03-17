module I = Map.Make(
  struct
    type t = int
    let compare = compare
  end )

type t =
  { mutable fvar: int;
    mutable subst_open: (Btype_mt.t) I.t;
    mutable subst_closed: (Btype_mt.t) I.t;
    mutable alias:(string*Btype_mt.t) list }

let create () : t = { fvar=0; subst_open=I.empty; subst_closed=I.empty; alias=[] }

let new_meta (env:t) : Btype_mt.t =
  env.fvar <- env.fvar+1;
  Btype_mt.T_Meta env.fvar

let rec safe_assoc a = function
  | [] -> None
  | (x,y)::tl -> if String.equal a x then Some y else safe_assoc a tl

let rec normalize (s:t) (ty:Btype_mt.t) : Btype_mt.t =
  match ty with
  | Btype_mt.T_Atomic _ as ty -> ty
  | Btype_mt.T_Power ty -> Btype_mt.T_Power (normalize s ty)
  | Btype_mt.T_Product (ty1,ty2) -> Btype_mt.T_Product (normalize s ty1,normalize s ty2)
  | Btype_mt.T_Meta m as ty ->
    begin match I.find_opt m s.subst_open with
      | Some ty -> ty
      | None ->
        begin match I.find_opt m s.subst_closed with
          | Some ty -> ty
          | None -> ty
        end
    end
  | Btype_mt.T_Record lst -> Btype_mt.T_Record (List.map (fun (x,ty) -> (x,normalize s ty)) lst)

let rec occurs_atm str t =
  match t with
  | Btype_mt.T_Atomic str2 -> String.equal str str2
  | Btype_mt.T_Power ty -> occurs_atm str ty
  | Btype_mt.T_Product (ty1,ty2) -> ( occurs_atm str ty1 || occurs_atm str ty2 )
  | Btype_mt.T_Meta m -> false
  | Btype_mt.T_Record lst ->  List.exists (fun (_,t) -> occurs_atm str t) lst

let update_subst_aux (s_op:Btype_mt.t I.t) (s_cl:Btype_mt.t I.t) (n:int) (is_closed:bool) (rep:Btype_mt.t) : Btype_mt.t I.t * Btype_mt.t I.t =
  let aux key old_ty (s_op,s_cl) =
    if is_closed then
      let new_ty,is_cl = Btype_mt.subst2 n rep old_ty in
      if is_cl then (s_op,I.add key new_ty s_cl)
      else (I.add key new_ty s_op,s_cl)
    else (I.add key (Btype_mt.subst n rep old_ty) s_op,s_cl)
  in
  I.fold aux s_op (I.empty,s_cl)

let update_subst (env:t) (n:int) (is_closed:bool) (rep:Btype_mt.t) : unit =
  let s_op, s_cl = update_subst_aux env.subst_open env.subst_closed n is_closed rep in
  let () = env.subst_open <- s_op in
  let () = env.subst_closed <- s_cl in
  if is_closed then env.subst_closed <- I.add n rep env.subst_closed
  else env.subst_open <- I.add n rep env.subst_open

let rec normalize_alias env ty =
  match ty with
  | Btype_mt.T_Atomic s as ty ->
    begin match safe_assoc s env.alias with
      | None -> ty
      | Some ty' -> ty'
    end
  | Btype_mt.T_Power ty -> Btype_mt.T_Power (normalize_alias env ty)
  | Btype_mt.T_Product (ty1,ty2) ->
    Btype_mt.T_Product (normalize_alias env ty1,normalize_alias env ty2)
  | Btype_mt.T_Meta _ as ty -> ty
  | Btype_mt.T_Record lst ->
    Btype_mt.T_Record (List.map (fun (x,ty) -> (x,normalize_alias env ty)) lst)

let add_alias (s:t) (alias:string) (ty:Btype_mt.t) : bool =
  let aux (x,y) = (x,normalize_alias s y) in
  let ty = normalize_alias s ty in
  if occurs_atm alias ty then false
  else ( s.alias <- (alias,ty)::(List.map aux s.alias); true )

let is_equal_modulo_alias env t1 t2 =
  Btype_mt.equal (normalize_alias env t1) (normalize_alias env t2)

let rec get_stype (env:t) (t1:Btype_mt.t) (t2:Btype_mt.t) : (Btype_mt.t) option =
  let open Btype_mt in
  match normalize env t1, normalize env t2 with
  | (T_Atomic s1) as ty1 , T_Atomic s2 when String.equal s1 s2 -> Some ty1
  | T_Power p1, T_Power p2 ->
    begin
      match get_stype env p1 p2 with
      | None -> None
      | Some p -> Some (T_Power p)
    end
  | T_Product (a1,b1), T_Product (a2,b2) ->
    begin
      match get_stype env a1 a2, get_stype env b1 b2 with
      | Some a, Some b -> Some (T_Product (a,b))
      | _, _ -> None
    end
  | T_Record lst1, T_Record lst2 ->
    begin
      let aux (s1,ty1) (s2,ty2) : string*Btype_mt.t =
        if String.equal s1 s2 then
          match get_stype env ty1 ty2 with
          | Some ty -> (s1,ty)
          | None -> raise (Failure "")
        else
          raise (Failure "")
      in
      ( try Some (T_Record (List.map2 aux lst1 lst2))
        with Failure _ | Invalid_argument _ -> None )
    end
  | T_Meta n, (T_Meta m as meta) when n=m -> Some meta
  | T_Meta n, ty | ty, T_Meta n ->
    let occ,is_closed = occurs2 n ty in
    if occ then None
    else (update_subst env n is_closed ty; Some ty)
  | (T_Atomic _ as ty1 , ty2) | (ty1 , (T_Atomic _ as ty2)) ->
    if is_equal_modulo_alias env ty1 ty2 then Some ty1 else None
  | _, _ -> None
