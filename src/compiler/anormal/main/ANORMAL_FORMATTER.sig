(**
 * Copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ANORMAL_FORMATTER.sig,v 1.5 2006/02/18 16:04:03 duchuu Exp $
 *)
signature ANORMAL_FORMATTER =
sig

 val anexpToString : Types.btvEnv list -> ANormal.anexp -> string

end
