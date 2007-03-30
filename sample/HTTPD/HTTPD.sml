(**
 * mini HTTP server
 * @author YAMATODANI Kiyoshi
 * @version $Id: HTTPD.sml,v 1.2 2007/03/04 03:08:46 kiyoshiy Exp $
 *)
structure HTTPD : HTTPD =
struct

  (***************************************************************************)

  type T_CONFIG = {vroot : string}
  type T_SOCKET = FFISocket.socket

  (***************************************************************************)

  val SERVERNAME = "TIBI-GUMO/0.1"

  fun readline sock =
      let
        val buf = Word8Array.array (1, Word8.fromInt 0)
        fun getchar () =
            case FFISocket.recv (sock, buf, 1, 0w0) of
              0 => NONE
            | ~1 => (FFISocket.perror "recv:"; raise Fail "read error.")
            | _ => SOME((Char.chr o Word8.toInt o Word8Array.sub) (buf, 0))
        fun readline' gotchars = 
            case getchar () of
              NONE => implode (rev gotchars)
            | SOME #"\n" => implode (rev gotchars)
            | SOME char => readline' (char :: gotchars)
        val line = readline' []
      in
        print (line ^ "\n");
        line
      end

  fun writevec sock vec =
      FFISocket.send (sock, vec, Word8Vector.length vec, 0w0)

  fun writestr sock str = 
      writevec
          sock
          (Word8Vector.fromList
               (map (Word8.fromInt o Char.ord) (explode str)))

  fun parseRequest con =
      let
        val firstline = readline con
        fun collectParams gotparams =
            case readline con of
              "\r" => gotparams
            | line => collectParams (line :: gotparams)
      in
        case String.tokens Char.isSpace firstline of
          [method, vpath, httpver] => 
          let val params = collectParams [] 
          in
            {
              method = method,
              vpath = vpath,
              httpver = httpver,
              params = params
            }
          end
        | _ => raise Fail ("Bug: cannot parse request: " ^ firstline)
      end

  fun resolvePath vroot vpath =
      let
        val canvpath = OS.Path.mkCanonical vpath
        val canvpath = if String.isPrefix ".." canvpath then "/" else canvpath
      in vroot ^ "/" ^ canvpath
      end

  fun resolveMimeType path buf = 
      case OS.Path.ext path of
        SOME ext => 
        (case ext of
           "html" => "text/html"
         | "jpg" => "image/jpeg"
         | "gif" => "image/gif"
         | _ => "text/plain")
      | NONE => "text/plain"
   
  fun makeOKResHeader mimetype contentlen=
      "HTTP/1.1 200 OK\r\n"
      ^ "Server: " ^ SERVERNAME ^ "\r\n"
      ^ "Content-Type: " ^ mimetype ^ "\r\n"
      ^ "Content-Length: " ^ Int.toString contentlen ^ "\r\n"
      ^ "\r\n"

  fun handleGet (config:T_CONFIG) con vpath =
      let
        val path = resolvePath (#vroot config) vpath
        val _ = print ("requested path = [" ^ path ^ "]\n")
        val ins = BinIO.openIn path
        val buf = BinIO.inputAll ins
        val _ = BinIO.closeIn ins
        val mimetype = resolveMimeType path buf
      in 
        writestr con (makeOKResHeader mimetype (Word8Vector.length buf ));
        writevec con buf;
        ()
      end

  fun selectMethodHandler method = 
      case method of
        "GET" => handleGet
      | _ => raise Fail ("unsupported method: " ^ method)

  fun doresponse config con cliaddr =
      let
        val {method, vpath, httpver, params} = parseRequest con 
        val handler = selectMethodHandler method
      in handler config con vpath 
      end

  val g_socket = ref (NONE:T_SOCKET option)  (* for debug *)

  fun start oneShot port vroot = 
      let
        val config : T_CONFIG = {vroot = vroot}
        val socket =
            FFISocket.socket(FFISocket.AF_INET, FFISocket.SOCK_STREAM, 0w0)
        val serv_addr =
            FFISocket.makeSockAddr
                {
                  family = FFISocket.AF_INET,
                  addr = FFISocket.INADDR_LOOPBACK,
                  port = port
                }
        val r =
            FFISocket.bind (socket, serv_addr, FFISocket.SizeOfSocketAddress)
        val r = FFISocket.listen(socket, 0w5)
        val _ = g_socket := SOME socket
        fun loop () = 
            let
              val cli_addrRef = ref FFISocket.ZeroAddr
              val con =
                  FFISocket.accept
                      (socket, cli_addrRef, ref FFISocket.SizeOfSocketAddress)
            in
	      doresponse config con (!cli_addrRef)
(*
	      handle error => print ("error: " ^ exnMessage error)
*)
              ;
              FFISocket.close con;
              if oneShot then () else loop()
            end
      in
        loop();
        FFISocket.close socket;
        ()
      end

  fun shutdown () =
      case !g_socket of
        NONE => ()
      | SOME socket => (FFISocket.close socket; g_socket := NONE)

  (***************************************************************************)

end;

