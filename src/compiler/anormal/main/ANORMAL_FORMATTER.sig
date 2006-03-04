(**
 * formatter of A-Normal form.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ANORMAL_FORMATTER.sig,v 1.6 2006/02/28 16:10:58 kiyoshiy Exp $
 *)
signature ANORMAL_FORMATTER =
sig

 val anexpToString : Types.btvEnv list -> ANormal.anexp -> string

end
