(**
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: RegExp.sml,v 1.1 2006/10/27 14:06:25 kiyoshiy Exp $
 *)
structure RegExp =
    RegExpFn(structure P = AwkSyntax structure E = BackTrackEngine);
