/* parser.mly */

%{

module A = Absyn
module S = Symbol

(*
let parse_error msg =
  match !lexbuf_ref with
  | Some lexbuf ->
      Error.error (curr_loc lexbuf) (Error.Syntax (Lexing.lexeme lexbuf))
  | None ->
      Error.internal "lexbuf_ref is unset" *)

let addFuncDec  = function
                    | (A.FunctionDec(oldFuncDecs), newFuncDecs) -> A.FunctionDec(oldFuncDecs @ newFuncDecs)
                    | (_, newFuncDecs) -> A.FunctionDec(newFuncDecs)

let addTypeDec x = match x with
                  | (A.TypeDec(oldTypes), newTypes) -> A.TypeDec(oldTypes @ newTypes)
                  | (_, newTypes) -> A.TypeDec(newTypes)
%}

%token <int>    INT
%token <string> STRING
%token <string> ID
%token          FOR WHILE BREAK LET IN NIL TO END
%token          FUNCTION VAR TYPE ARRAY IF THEN ELSE DO OF
%token          LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE
%token          DOT COLON COMMA SEMI
%token          PLUS MINUS TIMES DIVIDE UMINUS
%token          EQ NEQ LT LE GT GE
%token          AND OR
%token          ASSIGN
(*%token          EOF*)

%nonassoc FUNCTION TYPE VAR IF DO OF ASSIGN ARRAY WHILE FOR TO
%left OR
%left AND
%right THEN
%right ELSE

%nonassoc EQ NEQ LT LE GT GE
%left PLUS MINUS
%left TIMES DIVIDE
%left UMINUS

%start prog
%type <A.exp> prog
%type <A.exp> exp
%%

prog:
  exp                                              { $1 }
;

exp:

  NIL                                              { A.NilExp }
| INT                                              { A.IntExp $1 }
| STRING                                           { A.StringExp($1, $startofs) }

| ID LBRACK exp RBRACK OF exp                      { A.ArrayExp {typ = Symbol.symbol($1); size = $3; init = $6; pos = $startofs($1)} }
| ID LBRACE field_value_list RBRACE                { A.RecordExp {fields = $3; typ = Symbol.symbol($1); pos = $startofs} }


| lvalue                                           { A.VarExp $1 }

| lvalue ASSIGN exp                                { A.AssignExp({ var = $1; exp = $3; pos = $startofs($2) }) }

| ID LPAREN args RPAREN                            { A.CallExp({func = Symbol.symbol($1); args = $3; pos = $startofs }) }

| exp OR exp                                       { A.IfExp({ test = $1; then' = A.IntExp(1); else' = Some($3); pos = $startofs}) }
| exp AND exp                                      { A.IfExp({ test = $1; then' = $3; else' = Some(A.IntExp(0)); pos = $startofs}) }
| exp EQ exp                                       { A.OpExp({ left=$1; oper= A.EqOp; right= $3; pos= $startofs}) }
| exp NEQ exp                                       { A.OpExp({ left=$1; oper= A.NeqOp; right= $3; pos= $startofs}) }
| exp LT exp                                       { A.OpExp({ left=$1; oper= A.LtOp; right= $3; pos= $startofs}) }
| exp LE exp                                       { A.OpExp({ left=$1; oper= A.LeOp; right= $3; pos= $startofs}) }
| exp GT exp                                       { A.OpExp({ left=$1; oper= A.GtOp; right= $3; pos= $startofs}) }
| exp GE exp                                       { A.OpExp({ left=$1; oper= A.GeOp; right= $3; pos= $startofs}) }
| exp PLUS exp                                     { A.OpExp({ left=$1; oper= A.PlusOp; right= $3; pos= $startofs}) }
| exp MINUS exp                                    { A.OpExp({ left=$1; oper= A.MinusOp; right= $3; pos= $startofs}) }
| exp TIMES exp                                    { A.OpExp({ left=$1; oper= A.TimesOp; right= $3; pos= $startofs}) }
| exp DIVIDE exp                                      { A.OpExp({ left=$1; oper= A.DivideOp; right= $3; pos= $startofs}) }
| MINUS exp %prec UMINUS                           { A.OpExp({ left=A.IntExp(0); oper=A.MinusOp; right=$2; pos= $startofs}) }

| IF exp THEN exp ELSE exp                         { A.IfExp({ test = $2; then' = $4; else' = Some $6; pos = $startofs}) }
| IF exp THEN exp                                  { A.IfExp({ test = $2; then' = $4; else' = None; pos = $startofs}) }
| WHILE exp DO exp                                 { A.WhileExp({test = $2; body = $4; pos = $startofs}) }
| FOR ID ASSIGN exp TO exp DO exp                  { A.ForExp({var = Symbol.symbol($2); escape = (ref true); lo = $4; hi = $6 ; body = $8; pos = $startofs}) }
| BREAK                                            { A.BreakExp($startofs) }

| LET decs IN sequence END                         { A.LetExp({decs = $2; body = A.SeqExp($4); pos = $startofs }) }

| LPAREN sequence RPAREN                           { A.SeqExp($2) }
;

field_value_list:
  ID EQ exp                                        { [(Symbol.symbol($1), $3, $startofs)] }
| ID EQ exp COMMA field_value_list                 { (Symbol.symbol($1), $3, $startofs) :: $5 } (*Check later*)
;

lvalue:
  ID                                               { A.SimpleVar(Symbol.symbol($1), $startofs) }
| lvalue DOT ID                                    { A.FieldVar ($1, Symbol.symbol($3), $startofs($2)) }
| lvalue LBRACK exp RBRACK                         { A.SubscriptVar($1, $3, $startofs($2)) }
;

fields:
  ID COLON ID tyfieldstail { (A.Field {name = Symbol.symbol($1); escape = (ref true); typ = Symbol.symbol($3); pos = $startofs}) :: $4 }
;

tyfieldstail : (* empty*) {[]}
| COMMA ID COLON ID tyfieldstail { (A.Field {name = Symbol.symbol($2); escape = (ref true);
                                    typ = Symbol.symbol($4); pos = $startofs($2)}) :: $5 }

sequence:
  /* empty */                                      { []}
| exp                                              { ($1, $startofs) :: [] }
| exp SEMI sequence_rest                           { ($1, $startofs) :: $3 }
;

sequence_rest:
  exp                                              { ($1, $startofs) :: [] }
| exp SEMI sequence_rest                           { ($1, $startofs) :: $3 }
;

args:
  /* empty */                                      { [] }
| exp                                              { $1 :: [] }
| exp COMMA args_rest                              { $1 :: $3 }
;

args_rest:
  exp                                              { $1 :: [] }
| exp COMMA args_rest                              { $1 :: $3 }
;

type_opt:
  /* empty */                                      { None } 
| COLON ID                                         { Some (S.symbol($2), $startofs($2)) }

varDec:
  VAR ID COLON type_opt ASSIGN exp                 { A.VarDec({name = Symbol.symbol($2); escape = (ref true);
                                                              typ = $4;
                                                              init = $6; pos = $startofs}) }
;

functionDec:
  FUNCTION ID LPAREN fields RPAREN type_opt EQ exp { A.FunctionDec([A.Func { name = Symbol.symbol($2); params = $4;
                                                      result = $6; body = $8; pos = $startofs}]) }
| functionDec FUNCTION ID LPAREN fields RPAREN type_opt EQ exp { addFuncDec ($1, [
                                                                A.Func { name = Symbol.symbol($3); params = $5;
                                                                        result = $7; body = $9; pos = $startofs}]) }
;

typeDec:
  TYPE ID EQ ty                                    { A.TypeDec([A.Type { name = Symbol.symbol($2); ty = $4; pos = $startofs }]) }
| TYPE ID EQ ty typeDec                            { addTypeDec ($5, [A.Type { name = Symbol.symbol($2); ty = $4; pos = $startofs }]) }
;



ty:
  ID                                               { A.NameTy (Symbol.symbol($1), $startofs) }
| LBRACE fields RBRACE                             { A.RecordTy $2 }
| ARRAY OF ID                                      { A.ArrayTy (Symbol.symbol($3), $startofs) }
;

dec:
  varDec                              { $1 }
| functionDec                         { $1 }
| typeDec                             { $1 }
;

decs: dec decs                        {$1 :: $2 }
| (*empty*)                           {[]}


%%
