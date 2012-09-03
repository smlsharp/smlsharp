(* OK *)
val _ = ([[]], [[]]);

(* OK *)
val _ = case () of () => ([[]], [[]]);

(* OK *)
val _ = case 1 of 1 => ([], []);

(* OK *)
val _ = case 1 of 1 => ([], [[]]);

(* NG *)
val _ = case 1 of 1 => ([[]], [[]]);
