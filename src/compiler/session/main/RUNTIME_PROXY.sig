(**
 * Copyright (c) 2006, Tohoku University.
 *
 * proxy of a IML runtime instance.
 * A proxy abstracts the detail of messaging with a IML runtime instance.
 * @author YAMATODANI Kiyoshi
 * @version $Id: RUNTIME_PROXY.sig,v 1.2 2006/02/18 04:59:28 ohori Exp $
 *)
signature RUNTIME_PROXY =
sig

  (***************************************************************************)

  (**
   * parameter to the initialize function.
   *)
  type InitialParameter

  (***************************************************************************)

  (**
   * create a proxy of a IML runtime instance.
   * <p>
   * This function creates a new runtime instance or connects to an
   * existing runtime instance, and returns a proxy of the obtained runtime.
   * </p>
   *)
  val initialize : InitialParameter -> RuntimeProxyTypes.Proxy

  (***************************************************************************)

end
