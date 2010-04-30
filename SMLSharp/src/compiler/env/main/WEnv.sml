(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @version $Id: WEnv.sml,v 1.2 2008/08/06 02:20:19 ohori Exp $
 *)

structure WEnv = BinaryMapMaker(WOrd)
structure WEnvLazy = BinaryMapMaker(WOrd)
