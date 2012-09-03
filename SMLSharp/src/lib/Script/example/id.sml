val user = case argv of [] => env "USER" | name :: _ => name;
case
  List.filter
      (fn entry => hd entry = user)
      (map (fields ":") (readlines (fopen "/etc/passwd" "r") (SOME "\n")))
 of [] => print ("not found: " ^ user)
  | [_ :: _ :: id :: gid :: _] => print ("uid=" ^ id ^ " gid=" ^ gid);
