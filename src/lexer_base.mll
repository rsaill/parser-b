{
  open Lexing
  open Grammar

  let chars_read = ref ""
  let string_loc = ref (0,0)
  let add_char c = chars_read := Printf.sprintf "%s%c" !chars_read c

  let flush () =
    chars_read := ""

let err lexbuf err_txt = Error.error lexbuf.lex_start_p err_txt

let keywords = Hashtbl.create 137

let _ = List.iter (fun (name, keyword) ->
    Hashtbl.add keywords name keyword) [
    "WHERE"     , WHERE;
   "THEN"      , THEN;
   "SELECT"    , SELECT;
   "TRUE"      , CONSTANT SyntaxCore.TRUE;
   "FALSE"     , CONSTANT SyntaxCore.FALSE;
   "MAXINT"    , CONSTANT SyntaxCore.MaxInt;
   "MININT"    , CONSTANT SyntaxCore.MinInt;
   "SIGMA"     , E_BINDER SyntaxCore.Sum;
   "INTEGER"   , CONSTANT SyntaxCore.INTEGER;
   "NATURAL1"  , CONSTANT SyntaxCore.NATURAL1;
   "NATURAL"   , CONSTANT SyntaxCore.NATURAL;
   "NAT1"      , CONSTANT SyntaxCore.NAT1;
   "NAT"       , CONSTANT SyntaxCore.NAT;
   "INT"       , CONSTANT SyntaxCore.INT;
   "BOOL"      , CONSTANT SyntaxCore.BOOLEANS;
   "STRING"    , CONSTANT SyntaxCore.STRINGS;
   "PI"        , E_BINDER SyntaxCore.Prod;
   "POW1"      , E_PREFIX_1 (SyntaxCore.Power_Set SyntaxCore.Non_Empty);
   "POW"       , E_PREFIX_1 (SyntaxCore.Power_Set SyntaxCore.Full);
   "FIN1"      , E_PREFIX_1 (SyntaxCore.Power_Set SyntaxCore.Finite_Non_Empty);
   "FIN"       , E_PREFIX_1 (SyntaxCore.Power_Set SyntaxCore.Finite);
   "UNION"     , E_BINDER SyntaxCore.Q_Union;
   "INTER"     , E_BINDER SyntaxCore.Q_Intersection;
   "DEFINITIONS"        , DEFINITIONS;
   "ELSIF"              , ELSIF;
   "ELSE"               , ELSE;
   "WHEN"               , WHEN;
   "OR"                 , CASE_OR;
   "BEGIN"              , BEGIN;
   "END"                , END;
   "skip"               , SKIP;
   "PRE"                , PRE;
   "ASSERT"             , ASSERT;
   "CHOICE"             , CHOICE;
   "IF"                 , IF;
   "CASE"               , CASE;
   "EITHER"             , EITHER;
   "ANY"                , ANY;
   "LET"                , LET;
   "BE"                 , BE;
   "VAR"                , VAR;
   "WHILE"              , WHILE;
   "DO"                 , DO;
   "INVARIANT"          , INVARIANT;
   "VARIANT"            , VARIANT;
   "MACHINE"            , MACHINE;
   "CONSTRAINTS"        , CONSTRAINTS;
   "SEES"               , SEES;
   "INCLUDES"           , INCLUDES;
   "PROMOTES"           , PROMOTES;
   "EXTENDS"            , EXTENDS;
   "USES"               , USES;
   "SETS"               , SETS;
   "CONCRETE_CONSTANTS" , CONCRETE_CONSTANTS;
   "CONSTANTS"          , CONSTANTS;
   "ABSTRACT_VARIABLES" , ABSTRACT_VARIABLES;
   "VARIABLES"          , VARIABLES;
   "ASSERTIONS"         , ASSERTIONS;
   "INITIALISATION"     , INITIALISATION;
   "OPERATIONS"         , OPERATIONS;
   "LOCAL_OPERATIONS"   , LOCAL_OPERATIONS;
   "IN"                 , IN;
   "REFINEMENT"         , REFINEMENT;
   "IMPLEMENTATION"     , IMPLEMENTATION;
   "REFINES"            , REFINES;
   "IMPORTS"            , IMPORTS;
   "VALUES"             , VALUES;
   "PROPERTIES"         , PROPERTIES;
   "OF"                 , OF;
   "CONCRETE_VARIABLES" , CONCRETE_VARIABLES;
   "VISIBLE_VARIABLES" , CONCRETE_VARIABLES;
   "ABSTRACT_CONSTANTS" , ABSTRACT_CONSTANTS;
   "HIDDEN_CONSTANTS" , ABSTRACT_CONSTANTS;

   "bool"      , CBOOL;
   "mod"       , E_INFIX_190 SyntaxCore.Modulo;
   "succ"      , CONSTANT SyntaxCore.Successor;
   "pred"      , CONSTANT SyntaxCore.Predecessor;
   "max"       , E_PREFIX_1 SyntaxCore.Max;
   "min"       , E_PREFIX_1 SyntaxCore.Min;
   "card"      , E_PREFIX_1 SyntaxCore.Cardinal;
   "union"     , E_PREFIX_1 SyntaxCore.G_Union;
   "inter"     , E_PREFIX_1 SyntaxCore.G_Intersection;
   "prj1"      , E_PREFIX_2 SyntaxCore.First_Projection;
   "prj2"      , E_PREFIX_2 SyntaxCore.Second_Projection;
   "iterate"   , E_PREFIX_2 SyntaxCore.Iteration;
   "closure"   , E_PREFIX_1 SyntaxCore.Closure;
   "closure1"  , E_PREFIX_1 SyntaxCore.Transitive_Closure;
   "dom"       , E_PREFIX_1 SyntaxCore.Domain;
   "fnc"       , E_PREFIX_1 SyntaxCore.Fnc;
   "rel"       , E_PREFIX_1 SyntaxCore.Rel;
   "not"       , NOT;
   "or"        , OR;
    "id"       , E_PREFIX_1 SyntaxCore.Identity_Relation;
   "rec"       , REC;
   "struct"    , STRUCT;
   "seq1"       , E_PREFIX_1 (SyntaxCore.Sequence_Set SyntaxCore.Non_Empty_Seq);
   "seq"        , E_PREFIX_1 (SyntaxCore.Sequence_Set SyntaxCore.All_Seq);
   "iseq1"      , E_PREFIX_1 (SyntaxCore.Sequence_Set SyntaxCore.Injective_Non_Empty_Seq);
   "iseq"       , E_PREFIX_1 (SyntaxCore.Sequence_Set SyntaxCore.Injective_Seq);
   "perm"       , E_PREFIX_1 (SyntaxCore.Sequence_Set SyntaxCore.Permutations);
   "tree"       , E_PREFIX_1 SyntaxCore.Tree;
   "btree"      , E_PREFIX_1 SyntaxCore.Btree;
   "const"      , E_PREFIX_1 SyntaxCore.Const;
   "top"        , E_PREFIX_1 SyntaxCore.Top;
   "sons"       , E_PREFIX_1 SyntaxCore.Sons;
   "prefix"     , E_PREFIX_1 SyntaxCore.Prefix;
   "postfix"    , E_PREFIX_1 SyntaxCore.Postfix;
   "sizet"      , E_PREFIX_1 SyntaxCore.SizeT;
   "size"       , E_PREFIX_1 SyntaxCore.Size;
   "mirror"     , E_PREFIX_1 SyntaxCore.Mirror;
   "rank"       , E_PREFIX_1 SyntaxCore.Rank;
   "ran"        , E_PREFIX_1 SyntaxCore.Range;
   "father"     , E_PREFIX_1 SyntaxCore.Father;
   "son"        , E_PREFIX_1 SyntaxCore.Son;
   "arity"      , E_PREFIX_1 SyntaxCore.Arity;
   "bin"        , E_PREFIX_1 SyntaxCore.Bin;
   "left"       , E_PREFIX_1 SyntaxCore.Left;
   "right"      , E_PREFIX_1 SyntaxCore.Right;
   "infix"      , E_PREFIX_1 SyntaxCore.Infix;
   "subtree"    , E_PREFIX_1 SyntaxCore.Subtree;
   "first"      , E_PREFIX_1 SyntaxCore.First;
   "front"      , E_PREFIX_1 SyntaxCore.Front;
   "last"       , E_PREFIX_1 SyntaxCore.Last;
   "tail"       , E_PREFIX_1 SyntaxCore.Tail;
   "conc"       , E_PREFIX_1 SyntaxCore.G_Concatenation;
   "size"       , E_PREFIX_1 SyntaxCore.Size;
   "rev"        , E_PREFIX_1 SyntaxCore.Reverse;
  ]

let ident_to_token _ id =
  try Hashtbl.find keywords id
  with Not_found -> IDENT id

}

let space   = [' ' '\t']
let ident   = ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']*
let int_lit = ['0'-'9']+
let hex_lit = "0x" ['0'-'9' 'A'-'F' 'a'-'f']+
let commented_line = "//" [^'\n']*
let def_file = '<' ['a'-'z' 'A'-'Z' '0'-'9' '_' '.']+ '>'

rule token = parse
  | space       { token lexbuf }
  | '\n'        { new_line lexbuf ; token lexbuf }
  | '\r'        { token lexbuf }
  | "/*"        { comment lexbuf }
  | commented_line     { token lexbuf }
  | '"'         { flush (); string lexbuf }
  
  | "+->>"      { E_INFIX_125 (SyntaxCore.Functions SyntaxCore.Partial_Surjections) }
  | "-->>"      { E_INFIX_125 (SyntaxCore.Functions SyntaxCore.Total_Surjections)  }
  | ">->>"      { E_INFIX_125 (SyntaxCore.Functions  SyntaxCore.Bijections) }
  | "/<<:"      { PREDICATE (SyntaxCore.Inclusion SyntaxCore.Non_Strict_Inclusion) }

  | "|->"       { MAPLET  }
  | "<->"       { E_INFIX_125 SyntaxCore.Relations  }
  | "<<|"       { E_INFIX_160 SyntaxCore.Domain_Soustraction  }
  | "|>>"       { E_INFIX_160 SyntaxCore.Codomain_Soustraction }
  | "+->"       { E_INFIX_125 (SyntaxCore.Functions SyntaxCore.Partial_Functions)  }
  | "-->"       { E_INFIX_125 (SyntaxCore.Functions SyntaxCore.Total_Functions) }
  | "<--"       { LEFTARROW  }
  | ">+>"       { E_INFIX_125 (SyntaxCore.Functions SyntaxCore.Partial_Injections)  }
  | ">->"       { E_INFIX_125 (SyntaxCore.Functions SyntaxCore.Total_Injections) }
  | "<=>"       { EQUIV  }
  | "<<:"       { PREDICATE (SyntaxCore.Inclusion SyntaxCore.Strict) }
  | "/<:"       { PREDICATE (SyntaxCore.Inclusion SyntaxCore.Non_Inclusion) }
  | "\\|/"      { E_INFIX_160 SyntaxCore.Tail_Restriction }
  | "/|\\"      { E_INFIX_160 SyntaxCore.Head_Restriction }

  | "<-"        { E_INFIX_160 SyntaxCore.Tail_Insertion }
  | "->"        { E_INFIX_160 SyntaxCore.Head_Insertion }
  | "|>"        { E_INFIX_160 SyntaxCore.Codomain_Restriction }
  | "**"        { E_INFIX_200 SyntaxCore.Power  }
  | "{}"        { CONSTANT SyntaxCore.Empty_Set  }
  | "[]"        { CONSTANT SyntaxCore.Empty_Seq  }
  | "<>"        { CONSTANT SyntaxCore.Empty_Seq  }
  | ".."        { E_INFIX_170 SyntaxCore.Interval  }
  | "\\/"       { E_INFIX_160 SyntaxCore.Union }
  | "/\\"       { E_INFIX_160 SyntaxCore.Intersection }
  | "><"        { E_INFIX_160 SyntaxCore.Direct_Product }
  | "||"        { PARALLEL  }
  | "<|"        { E_INFIX_160 SyntaxCore.Domain_Restriction }
  | "<+"        { E_INFIX_160 SyntaxCore.Surcharge }
  | "=>"        { IMPLY  }
  | "/="        { PREDICATE SyntaxCore.Disequality }
  | "/:"        { PREDICATE SyntaxCore.Non_Membership }
  | "<:"        { PREDICATE (SyntaxCore.Inclusion SyntaxCore.Not_Strict) }
  | "<="        { PREDICATE (SyntaxCore.Inequality SyntaxCore.Smaller_or_Equal) }
  | ">="        { PREDICATE (SyntaxCore.Inequality SyntaxCore.Greater_or_Equal) }
  | ":="        { AFFECTATION  }
  | "::"        { BECOMES_ELT  }
  | "=="        { EQUALEQUAL  }
  | "$0"        { DOLLAR_ZERO  }

  | '/'         { E_INFIX_190 SyntaxCore.Division }
  | '.'         { DOT  }
  | '\''        { SQUOTE  }
  | '|'         { BAR  }
  | '{'         { LBRA  }
  | '}'         { RBRA   }
  | '~'         { TILDE  }
  | ';'         { SEMICOLON  }
  | '['         { LSQU  }
  | ']'         { RSQU  }
  | '%'         { E_BINDER SyntaxCore.Lambda  }
  | '&'         { AND  }
  | '!'         { FORALL  }
  | '#'         { EXISTS  }
  | '='         { EQUAL  }
  | ':'         { MEMBER_OF  }
  | '<'         { PREDICATE (SyntaxCore.Inequality SyntaxCore.Strictly_Smaller) }
  | '>'         { PREDICATE (SyntaxCore.Inequality SyntaxCore.Strictly_Greater) }
  | '+'         { E_INFIX_180 SyntaxCore.Addition  }
  | '-'         { MINUS  }
  | '*'         { E_INFIX_190 SyntaxCore.Product }
  | ','         { COMMA  }
  | ')'         { RPAR  }
  | '('         { LPAR  }
  | '^'         { E_INFIX_160 SyntaxCore.Concatenation }

  | def_file as id {
      DEF_FILE ( String.sub id 1 ((String.length id)-2) ) }
  | ident as id { ident_to_token lexbuf.Lexing.lex_start_p id }

  | (ident as p) '.' (ident as id) { REN_IDENT (p,id) }
 
  | hex_lit as i {
      match Int64.of_string_opt i with
      | None -> err lexbuf ("The literal '"^i^"' does not fit in a signed 64 bits integer.")
      | Some lit -> CONSTANT (SyntaxCore.Integer ( lit ))
    }
  | int_lit as i  {
      match Int64.of_string_opt i with
      | None -> err lexbuf ("The literal '"^i^"' does not fit in a signed 64 bits integer.")
      | Some lit -> CONSTANT (SyntaxCore.Integer ( lit ))
    }
  | _   as c    { err lexbuf ("Unexpected character '" ^ String.make 1 c ^ "'.") }
  | eof         { EOF }

 and comment = parse
  | "*/" { token lexbuf          }
  | '\n' { new_line lexbuf ; comment lexbuf }
  | _    { comment lexbuf        }
  | eof	 { err lexbuf "Unexpected end of file" }

and string = parse
  | '\\' '"' { add_char '"'; string lexbuf }
  | '\\' (_ as c) { add_char '\\'; add_char c; string lexbuf }
  | '\n' { Lexing.new_line lexbuf ; add_char '\n'; string lexbuf }
  | '"'  {  STRING !chars_read }
  | _ as c { add_char c; string lexbuf }
  | eof	 { err lexbuf "Unexpected end of file." }
