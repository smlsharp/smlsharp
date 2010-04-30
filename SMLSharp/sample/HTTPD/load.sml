use "./FFI_SOCKET.sig";

(*
 * NOTE: "${OSNAME}" in the path string is substituted with the value of
 * environment variable "OSNAME". 
 *)
use "./FFISocket_${OSNAME}.sml";

use "./HTTPD.sig";
use "./HTTPD.sml";
