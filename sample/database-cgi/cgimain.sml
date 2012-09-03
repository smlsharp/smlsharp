structure CGIMain : sig
  val main : unit -> unit
end =
struct

  fun join s nil = ""
    | join s [x] = x
    | join s (h::t) = h ^ s ^ join s t

  fun errorResponse status headers body =
      (TextIO.print ("Content-Type: text/html\n\
                     \Status: " ^ status ^ "\n");
       app (fn s => TextIO.print (s ^ "\n")) headers;
       TextIO.print "\n";
       TextIO.print
         ("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\">\n\
          \<html>\n\
          \<head><title>" ^ CGI.escapeHTML status ^ "</title></head>\n\
          \<body>\n\
          \<h1>" ^ CGI.escapeHTML status ^ "</h1>\n" ^ body ^ "\n\
          \</body></html>\n"))

  fun valOf NONE = raise CGI.HTTPBadRequest
    | valOf (SOME x) = x

  fun main () =
      let
        val uri = case OS.Process.getEnv "PATH_INFO" of
                    SOME x => x | NONE => ""
        val method = valOf (OS.Process.getEnv "REQUEST_METHOD")
        val act = if method = "HEAD" then "GET" else method
        val args =
            case OS.Process.getEnv "CONTENT_LENGTH" of
              NONE => valOf (OS.Process.getEnv "QUERY_STRING")
            | SOME s => TextIO.inputN (TextIO.stdIn, valOf (Int.fromString s))

        val responseBody =
            Pages.dispatch {uri = uri, method = method, args = args}
      in
        TextIO.print "Content-Type: text/html\n\n";
        TextIO.print responseBody
      end
      handle CGI.HTTPBadRequest => errorResponse "400 Bad Request" nil ""
           | CGI.HTTPNotFound => errorResponse "404 Not Found" nil ""
           | CGI.HTTPMethodNotAllowed allows =>
             errorResponse "405 Method Not Allowed"
                           ["Allow: " ^ join ", " allows] ""
           | e =>
             errorResponse "500 Internal Server Error" nil
                           ("<pre>\n" ^
                            CGI.escapeHTML (exnMessage e) ^ "\n" ^
                            "</pre>")

end
