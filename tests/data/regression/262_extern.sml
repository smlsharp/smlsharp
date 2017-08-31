val x = S1.x

(*
2013-07-18 katsu

NameEval generates "extern val S1.x" twice.

% smlsharp -c 262_extern.sml -dprintStaticAnalysis=yes
set control option: printStaticAnalysis = yes
Static Analysis:
extern val Bind
extern val Match
extern val Subscript
extern val Size
extern val Overflow
extern val Div
extern val Domain
extern val Fail
extern val Chr
extern val Span
extern val Empty
extern val Option
extern val S1.x
extern val S1.x       <---- DOUBLED EXTERN DECLARATION
*)
