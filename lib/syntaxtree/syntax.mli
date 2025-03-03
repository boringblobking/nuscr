open! Base
open Loc
open Names

module type EXPRS_SIG = sig
  type expr =
    | Var of VariableName.t
    | Int of int
    | Bool of bool
    | String of string
    | Binop of binop * expr * expr
    | Unop of unop * expr

  and binop = Add | Minus | Eq | Neq | Lt | Gt | Leq | Geq | And | Or

  and unop = Neg | Not | StrLen [@@deriving eq, ord, show, sexp_of]
end

include EXPRS_SIG

module Exprs :
  EXPRS_SIG with type binop = binop and type unop = unop and type expr = expr

type ty =
  | Simple of PayloadTypeName.t
  | Refined of VariableName.t * PayloadTypeName.t * expr
[@@deriving eq, ord, show, sexp_of]

type annotation = string [@@deriving show {with_path= false}, sexp_of]

type raw_mod_decl = {module_name: string}
[@@deriving show {with_path= false}]

type mod_decl = raw_mod_decl located option
[@@deriving show {with_path= false}]

type raw_type_decl =
  { domain: string (* where does the type come from java|xsd|... *)
  ; type_spec: string (* the spec of the type in its own domain *)
  ; location: string (* location of the the type definition *)
  ; type_name: string (* the name of the defined type *)
  ; is_type: bool (* true for types, false for signatures *) }
[@@deriving show {with_path= false}]

type type_decl = raw_type_decl located [@@deriving show {with_path= false}]

type payloadt =
  | PayloadName of PayloadTypeName.t
  | PayloadDel of ProtocolName.t * RoleName.t (* protocol @ role *)
  | PayloadBnd of VariableName.t * PayloadTypeName.t
  | PayloadRTy of ty
[@@deriving eq, ord, sexp_of, show]

type message =
  | Message of {name: LabelName.t; payload: payloadt list}
  | MessageName of LabelName.t
[@@deriving eq, ord, sexp_of, show]

val message_label : message -> string

val message_payload_ty : message -> string list

type rec_var =
  {var: VariableName.t; roles: RoleName.t list; ty: payloadt; init: expr}
[@@deriving show {with_path= false}, sexp_of]

type global_interaction = raw_global_interaction located
[@@deriving show {with_path= false}, sexp_of]

and raw_global_interaction =
  | MessageTransfer of
      { message: message
      ; from_role: RoleName.t
      ; to_roles: RoleName.t list
      ; ann: annotation option }
  (* recursion variable, protocol *)
  | Recursion of TypeVariableName.t * rec_var list * global_interaction list
  | Continue of TypeVariableName.t * expr list
  (* role, protocol options *)
  | Choice of RoleName.t * global_interaction list list
  (* protocol * roles *)
  | Do of ProtocolName.t * RoleName.t list * annotation option
  (* caller * protocol * roles *)
  | Calls of
      RoleName.t * ProtocolName.t * RoleName.t list * annotation option
[@@deriving show {with_path= false}]

type protocol_mods = Aux | AuxExplicit | Explicit
[@@deriving show {with_path= false}, sexp_of]

type global_protocol = raw_global_protocol located
[@@deriving show {with_path= false}, sexp_of]

and raw_global_protocol =
  { name: ProtocolName.t
  ; options: protocol_mods option
        (* if parameter is ("foo", None) it's a type *)
        (* if parameter is ("foo", Some "bar") it's a sig *)
        (* neither case I know what it is *)
  ; parameters: (string * string option) list
  ; rec_parameters: (string * annotation) list
        (* parameters for the recursion *)
  ; roles: RoleName.t list
  ; split_roles: RoleName.t list * RoleName.t list
  ; nested_protocols: global_protocol list
  ; interactions: global_interaction list
  ; ann: annotation option }
[@@deriving show {with_path= false}, sexp_of]

type scr_module =
  { decl: mod_decl
  ; pragmas: Pragma.pragmas
  ; types: type_decl list
  ; nested_protocols: global_protocol list
  ; protocols: global_protocol list }
[@@deriving show {with_path= false}]
