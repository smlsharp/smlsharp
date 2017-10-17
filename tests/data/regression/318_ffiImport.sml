val sprintfInt = _import "sprintf" : (char array, string, ...(int)) -> int

(*
2015-01-20 Sasaki

This code is an official example 
(http://www.pllab.riec.tohoku.ac.jp/smlsharp/docs/2.0/ja/Ch9.S3.xhtml).

If there are more than two arguments before variable arguments, 
parser fails.

318_ffiImport.sml:1.48-1.48 Error: syntax error: replacing  COMMA with  ARROW
*)
(*
2015-01-21 katsu
fixed by changeset 4ef6211f5c05
*)
