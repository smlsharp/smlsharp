(**
 * Copyright (c) 2006, Tohoku University.
 *
 * pickler for name module.
 * @author YAMATODANI Kiyoshi
 * @version $Id: NamePickler.sml,v 1.2 2006/02/18 04:59:24 ohori Exp $
 *)
structure NamePickler 
  : sig

      val id : ID.id Pickle.pu
      val IDMap : 'value Pickle.pu -> 'value ID.Map.map Pickle.pu
      val IDSet : ID.Set.set Pickle.pu
      val pos : Loc.pos Pickle.pu
      val loc : Loc.loc Pickle.pu
      val path : Path.path Pickle.pu
      val sequence : SequentialNumber.sequence Pickle.pu

    end =
struct

  (***************************************************************************)

  structure P = Pickle

  (***************************************************************************)

  val id = P.conv (ID.fromInt, ID.toInt) P.int

  structure IDMapPickler = OrdMapPickler(ID.Map)
  fun IDMap value_pu = IDMapPickler.map (id, value_pu)

  structure IDSetPickler = OrdSetPickler(ID.Set)
  val IDSet = IDSetPickler.set id

  val pos =
      P.conv
          (
            fn (fileName, line, col) =>
               Loc.makePos{fileName = fileName, line = line, col = col},
            fn pos =>
               (Loc.fileNameOfPos pos, Loc.lineOfPos pos, Loc.colOfPos pos)
          )
          (P.tuple3 (P.string, P.int, P.int))

  val loc = P.tuple2 (pos, pos)

  val path =
      let
        fun toInt Path.NilPath = 0
          | toInt (Path.PStructure _) = 1
        fun pu_NilPath pu = P.con0 Path.NilPath pu
        fun pu_PStructure pu =
            P.con1
                Path.PStructure
                (fn Path.PStructure arg => arg)
                (P.tuple3 (id, P.string, pu))
      in
        P.data (toInt, [pu_NilPath, pu_PStructure])
      end

  val sequence =
      P.conv
          (
            fn (first, next) => {first = first, next = next},
            fn {first, next} => (first, next)
          )
          (P.tuple2(P.int, P.refCyc 0 P.int))

  (***************************************************************************)

end
