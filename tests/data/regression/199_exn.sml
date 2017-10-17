exception R3 of int
exception E31 = R3
exception R3 of string and E31 = R3 and E32 = E31;

(*
2012-05-18 katsu

Value printer of the interactive mode does not print exception replication.
This code fragment exports an exception R3 and two aliases of R3.

The above input leads the following output.

# exception R3 of int
> exception E31 = R3
> exception R3 of string and E31 = R3 and E32 = E31;
exception E32 of int
exception R3 of string

but the output should be something like the following.

exception E31 of int
exception E31 = R3
exception E32 = E31
exception R3 of string
*)

(*
2012-07-12 ohori 
Fixed by 4302:eead5f56b84a

The missing E31 is due to the bug 205_exnExport.sml.
The printer is also fixed to get the output correct.

# exception R3 of int
> exception E31 = R3
> exception R3 of string 
> and E31 = R3
> and E32 = E31;
exception E31 of int
exception E32 = E31
exception R3 of string

This is the expected output.
*)

