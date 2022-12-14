{
open Parser
}

rule token = parse
  | "fun" { FUN }
  | "->" { TO }
  | "let" { LET }
  | "rec" { REC }
  | "if" { IF }
  | "then" { THEN }
  | "else" { ELSE }
  | "end" { END }
  | "=" { EQ }
  | "in" { IN }
  | "(" { LPAR }
  | ")" { RPAR }
  | "{" { LACC }
  | "}" { RACC }
  | "[" { LSPAR }
  | "]" { RSPAR }
  | "," { COMMA }
  | ";" { SC }
  | "." { DOT }
  | "+" { PLUS }
  | (['a'-'z']['a'-'z''\'']* as s) { IDENT s }
  | "\""([^'"']+ as s)"\"" { STRING s }
  | (['0'-'9']+ as n) { INT (int_of_string n) }
  | [' ']+ { token lexbuf }
  | "#"[^'\n']*"\n" { Lexing.new_line lexbuf; token lexbuf }
  | "\n" { Lexing.new_line lexbuf; token lexbuf }
  | eof { EOF }
