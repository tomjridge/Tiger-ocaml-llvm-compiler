
module T = Types
module S = Symbol
type access = unit

type enventry = VarEntry of {ty: T.ty; access: unit}
              | FunEntry of {
		  level: Translate.level;
		  label: Temp.label;
		  formals: T.ty list;
		  result : T.ty}

let base_tenv =
  let addtotable (s, t) table  = S.enter(table, S.symbol(s), t) in
  let toadd = [("int", T.INT); ("string", T.STRING)] in
  List.fold_right addtotable toadd S.empty

let base_venv = (* predefined functions *)
  let addtotable (s, t) table = S.enter(table, S.symbol(s), t) in
  let toadd = [
      ("printInt", FunEntry ({level=Translate.outermost; label=Temp.namedlabel "print_int"; formals=[T.INT]; result=T.UNIT}));
      ("print", FunEntry ({level=Translate.outermost; label=Temp.namedlabel "printf"; formals=[T.STRING]; result=T.UNIT}));
      ("flush", FunEntry ({level=Translate.outermost; label=Temp.namedlabel "tig_flush"; formals=[]; result=T.UNIT}));
      ("getchar", FunEntry ({level=Translate.outermost; label=Temp.namedlabel "tig_getchar"; formals=[]; result=T.STRING}));
      ("ord", FunEntry ({level=Translate.outermost; label=Temp.namedlabel "tig_ord"; formals=[T.STRING]; result=T.INT}));
      ("chr", FunEntry ({level=Translate.outermost; label=Temp.namedlabel "tig_chr"; formals=[T.INT]; result=T.STRING}));
      ("size", FunEntry ({level=Translate.outermost; label=Temp.namedlabel "tig_size"; formals=[T.STRING]; result=T.INT}));
      ("substring", FunEntry ({level=Translate.outermost; label=Temp.namedlabel "tig_substring"; formals=[T.STRING; T.INT; T.INT]; result=T.STRING}));
      ("concat", FunEntry ({level=Translate.outermost; label=Temp.namedlabel "tig_concat"; formals=[T.STRING; T.STRING]; result=T.STRING}));
      ("not", FunEntry ({level=Translate.outermost; label=Temp.namedlabel "tig_not"; formals=[T.INT]; result=T.INT}));
      ("exit", FunEntry ({level=Translate.outermost; label=Temp.namedlabel "tig_exit"; formals=[T.INT]; result=T.UNIT}))
    ] in
  List.fold_right addtotable toadd S.empty 