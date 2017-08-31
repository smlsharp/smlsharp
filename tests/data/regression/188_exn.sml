val _ = (raise E2) handle E2 => () | Fail s => ()
(*
2011-12-18 katsu

This causes BUG at DatatypeCompilation.

[BUG] composeExn: tag not found
    raised at: datatypecompilation/main/DatatypeCompilation.sml:766.29-766.68
   handled at: toplevel2/main/Top.sml:848.37
                main/main/SimpleMain.sml:376.53

This seems due to lack of exception declaration of E3.

*)
(*
2011-12-18 ohori

Fixed
*)
