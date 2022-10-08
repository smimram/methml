%{
open Lang
%}

%token FUN TO LET REC EQ IN APP
%token LPAR RPAR LSPAR RSPAR SC
%token LACC RACC COMMA DOT
%token<string> IDENT
%token<int> INT
%token<string> STRING
%token EOF

%start prog

%type<(bool * string * Lang.t) list> prog
%type<(bool * string * Lang.t) list> decls
%type<bool * string * Lang.t> decl
%type<Lang.t> expr
%type<bool> recursive
%type<string list> args
%type<Lang.t list> expr_list

%nonassoc INT STRING IDENT FUN TO LET IN LSPAR
%left DOT LPAR
%nonassoc APP
%%

prog:
  | decls EOF { $1 }

decls:
  | decl SC SC decls { $1::$4 }
  | { [] }

decl:
  | LET recursive IDENT args EQ expr { $2, $3, abs ~pos:$loc $4 $6 }

expr:
  | INT { mk ~pos:$loc (Int $1) }
  | STRING { mk ~pos:$loc (String $1) }
  | IDENT { mk ~pos:$loc (Var $1) }
  | FUN IDENT TO expr { abs ~pos:$loc [$2] $4 }
  (* Precedence of application is tricky:
     https://ptival.github.io/2017/05/16/parser-generators-and-function-application/
     *)
  | expr expr %prec APP { mk ~pos:$loc (App ($1, $2)) }
  | decl IN expr { let r, x, t = $1 in mk ~pos:$loc (Let (r, x, t, $3)) }
  | expr DOT LACC STRING EQ expr RACC { mk ~pos:$loc (Meth ($4, $6, $1)) }
  | expr DOT IDENT { mk ~pos:$loc (Invoke ($1, $3)) }
  | LPAR expr RPAR { $2 }
  | LSPAR RSPAR { mk ~pos:$loc (List []) }
  | LSPAR expr_list RSPAR { mk ~pos:$loc (List $2) }

expr_list:
  | expr { [$1] }
  | expr COMMA expr_list { $1::$3 }

args:
  | { [] }
  | IDENT args { $1::$2 }

recursive:
  | REC { true }
  | { false }
