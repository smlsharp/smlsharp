structure CGI : sig

  exception HTTPNotFound
  exception HTTPMethodNotAllowed of string list
  exception HTTPBadRequest
  exception Type of string
  exception Field of string

  val escapeHTML : string -> string
  val unescape : string -> string
  val splitFormURLEncoded : string -> (string * string) list
  val fetchFormField : string
                       -> (string -> 'a option)
                       -> (string * string) list
                       -> 'a * (string * string) list

end =
struct

  exception HTTPNotFound
  exception HTTPMethodNotAllowed of string list
  exception HTTPBadRequest

  fun escapeHTML s =
      String.translate (fn #"&" => "&amp;"
                         | #"<" => "&lt;"
                         | #">" => "&gt;"
                         | #"\"" => "&quot;"
                         | c => str c)
                       s

  fun unescape s =
      case String.fields (fn c => c = #"%") s of
        nil => raise Fail "unescape"
      | h::t =>
        String.concat
          (h ::
           (map (fn s =>
                    let
                      val hex = String.substring (s, 0, 2)
                      val rest = String.extract (s, 2, NONE)
                      val c =
                          if CharVector.all Char.isHexDigit hex
                          then StringCvt.scanString (Int.scan StringCvt.HEX) hex
                          else NONE
                    in
                      case c of
                        SOME c => str (chr c) ^ rest
                      | NONE => "%" ^ s
                    end
                    handle Subscript => "%" ^ s)
                t))

  fun splitFormURLEncoded s =
      map (fn s =>
              let
                val (h,t) =
                    Substring.splitl (fn c => c <> #"=") (Substring.full s)
              in
                (unescape (Substring.string h),
                 unescape (Substring.string (Substring.triml 1 t)))
              end)
          (String.fields (fn c => c = #"&") s)

  exception Type of string
  exception Field of string

  fun fetchFormField fieldName reader fields =
      let
        fun fetch nil = raise Field fieldName
          | fetch ((h as (name, value:string))::t) =
            if name = fieldName
            then case reader value of
                   NONE => raise Type fieldName
                 | SOME x => (x, t)
            else let val (v, t) = fetch t
                 in (v, h::t) end
      in
        fetch fields
      end
(*
  fun decodeFormURLEncoded spec s =
      let
        val fields = splitFormURLEncoded s
      in
        map (fn (field, reader) =>
                case List.find (fn (x,y) => x = field) fields of
                  NONE => raise NotFound field
                | SOME (_, value) =>
                  case reader value of
                    NONE => raise Type field
                  | SOME x => x)
            spec
      end
*)

end
