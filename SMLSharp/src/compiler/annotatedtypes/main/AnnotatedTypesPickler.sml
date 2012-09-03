(**
 * @copyright (c) 2007, Tohoku University.
 * @author Isao Sasano
 * @version $Id: AnnotatedTypesPickler.sml,v 1.15 2008/08/06 17:23:39 ohori Exp $
 * refactored by Atsushi Ohori
 *)

structure AnnotatedTypesPickler =
struct
local
  structure P = Pickle
  structure T = Types
  structure TP = TypesPickler
  structure AT = AnnotatedTypes
  structure EP = EnvPickler
  val dummyTy = AT.ERRORty
  val dummyRecordKind = AT.UNIV
in

(* ty and recordKind are defined mutual recursively. *)
  val (tyFunctions, ty) = P.makeNullPu dummyTy
  val (recordKindFunctions, recordKind) = P.makeNullPu dummyRecordKind

  val eqKind = TP.eqKind (* This can be used. *)
(*
  val id = LocalVarID.pu_ID
*)
  val varId = TP.varId
  val varInfo = 
    P.conv
    (fn (displayName, ty, varId) =>
     {displayName=displayName, ty=ty, varId=varId},
     fn {displayName, ty, varId} => (displayName, ty, varId))
    (P.tuple3 (P.string, ty, varId))

  val primInfo = 
    P.conv
    (fn (name, ty) => {name=name, ty=ty},
     fn {name, ty} => (name, ty))
    (P.tuple2 (BuiltinPrimitivePickler.primitive, ty))

  val labelEquiv = 
    let 
      fun toInt (AT.LE_LABELS _) = 0
        | toInt AT.LE_GENERIC = 1
        | toInt AT.LE_UNKNOWN = 2
      fun pu_LE_LABELS pu = 
        P.con1 AT.LE_LABELS
        (
         fn AT.LE_LABELS arg => arg
          | _ => raise Control.Bug "LE_LABELS expected: AnnotatedTypesPickler"
         )
        EP.ISet
      fun pu_LE_GENERIC pu = P.con0 AT.LE_GENERIC pu
      fun pu_LE_UNKNOWN pu = P.con0 AT.LE_UNKNOWN pu
    in
      P.data (toInt, [pu_LE_LABELS, pu_LE_GENERIC, pu_LE_UNKNOWN])
    end

  val functionAnnotation = 
    P.conv 
    (fn (labels, boxed) => 
     {labels=labels, boxed=boxed},
     fn {labels, boxed} => 
     (labels, boxed))
    (P.tuple2 (labelEquiv, P.bool))

  val recordAnnotation = 
    P.conv
    (fn (labels, boxed, align) =>
     {labels=labels, boxed=boxed, align=align},
     fn {labels, boxed, align} =>
     (labels, boxed, align))
    (P.tuple3 (labelEquiv, P.bool, P.bool))

  val functionKind =
    P.enum
    (
     fn AT.CLOSURE => 0
      | AT.LOCAL => 1
      | AT.GLOBAL_FUNSTATUS => 2,
     [
      AT.CLOSURE,
      AT.LOCAL,
      AT.GLOBAL_FUNSTATUS
      ]
    )

 val owner =
   P.conv
   (fn (ownerId, ownerCode) =>
     {ownerId = ownerId, ownerCode =ownerCode},
    fn {ownerId, ownerCode} =>
     (ownerId, ownerCode))
   (P.tuple2 (P.int, P.refNonCycle functionKind))


  val funStatus =
    P.conv
    (fn (codeStatus, owners, functionId) =>
     {codeStatus=codeStatus, owners=owners, functionId=functionId},
     fn {codeStatus, owners, functionId} =>
      (codeStatus, owners, functionId))
    (P.tuple3 (P.refNonCycle functionKind, P.list owner, P.int))
  
    
  val btvKind = 
    P.conv
    (fn (id, recordKind, eqKind, instancesRef) =>
     {id=id,
      recordKind=recordKind,
      eqKind=eqKind,
      instancesRef=instancesRef},
     fn {id, recordKind, eqKind, instancesRef} =>
     (id, recordKind, eqKind, instancesRef)
     )
    (P.tuple4 (P.int, recordKind, eqKind, 
               P.refNonCycle (P.list ty)))

  val annotationLabel = P.int

  val btvEnv = EP.IEnv btvKind
  val tyFun : {tyargs : AT.btvKind IEnv.map, body : AT.ty} P.pu =
      P.conv
          (
           fn (tyargs, body) => {tyargs = tyargs, body = body},
            fn {tyargs, body} => (tyargs, body)
          )
          (P.tuple2(btvEnv, ty))
  val tyCon = TypesPickler.tyCon
  val dummyTyFun =
      {
        tyargs = IEnv.empty,
        body = AT.ERRORty
      }
  val (tyBindInfoFunctions, tyBindInfo) = P.makeNullPu (AT.TYFUN dummyTyFun)
  val tyBindInfoOption = P.option tyBindInfo


  local
    val newTyBindInfo : AT.tyBindInfo P.pu =
        let
          fun toInt (AT.TYCON arg) = 0
            | toInt (AT.TYFUN arg) = 1
            | toInt (AT.TYSPEC arg) = 2
          fun pu_TYCON pu = 
            P.con1 
            AT.TYCON 
            (fn AT.TYCON arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non TYCON to pu_TYCON (types/main/MVCalcPickler.sml)"
            ) 
            tyCon
          fun pu_TYFUN pu = 
            P.con1 
                AT.TYFUN 
                (fn AT.TYFUN arg => arg
                  | _ => 
                    raise 
                        Control.Bug 
                            "non TYFUN to pu_TYFUN (types/main/MVCalcPickler.sml)"
                            ) 
                tyFun
          fun pu_TYSPEC pu = 
            P.con1 
            AT.TYSPEC 
            (fn AT.TYSPEC arg => arg
              | _ => 
                raise 
                  Control.Bug 
                  "non TYCON to pu_TYCON (types/main/MVCalcPickler.sml)"
            ) 
            tyCon
        in
            P.data (toInt, [pu_TYCON, pu_TYFUN, pu_TYSPEC])
        end

    val newTy = 
      let
        fun toInt (AT.ERRORty) = 0
          | toInt (AT.DUMMYty _) = 1
          | toInt (AT.BOUNDVARty _) = 2
          | toInt (AT.FUNMty _) = 3
          | toInt (AT.MVALty _) = 4
          | toInt (AT.RECORDty _) = 5
          | toInt (AT.RAWty _) = 6
          | toInt (AT.POLYty _) = 7
          | toInt (AT.SPECty _) = 8
          
        fun pu_ERRORty pu = P.con0 AT.ERRORty pu

        fun pu_DUMMYty pu = 
          P.con1 AT.DUMMYty 
          (
           fn AT.DUMMYty arg => arg
            | _ => raise Control.Bug "DUMMYty expected: AnnotatedTypesPickler"
           ) 
          P.int

        fun pu_BOUNDVARty pu = 
          P.con1 AT.BOUNDVARty
          (
           fn AT.BOUNDVARty arg => arg
            | _ => raise Control.Bug "BOUNDVARty expected: AnnotatedTypesPickler"
           )
          P.int

        fun pu_FUNMty pu = 
          P.con1 AT.FUNMty
          (
           fn AT.FUNMty arg => arg
            | _ => raise Control.Bug "FUNMty expected: AnnotatedTypesPickler"
           )
          (P.conv (fn (argTyList, bodyTy, annotation, funStatus) =>
                   {argTyList=argTyList,
                    bodyTy=bodyTy,
                    annotation=annotation,
                    funStatus = funStatus
                    },
                   fn {argTyList, bodyTy, annotation, funStatus} =>
                   (argTyList, bodyTy, annotation, funStatus))
           (P.tuple4 (P.list ty,
                      ty,
                      P.refNonCycle functionAnnotation,
                      funStatus)))

        fun pu_MVALty pu =
          P.con1 AT.MVALty
          (
           fn AT.MVALty arg => arg
            | _ => raise Control.Bug "MVALty expected: AnnotatedTypesPickler"
           )
          (P.list ty)

        fun pu_RECORDty pu =
          P.con1 AT.RECORDty
          (
           fn AT.RECORDty arg => arg
            | _ => raise Control.Bug "RECORDty expected: AnnotatedTypesPickler"
           )
          (P.conv
           (fn (fieldTypes, annotation) =>
            {fieldTypes=fieldTypes, annotation=annotation},
            fn {fieldTypes, annotation} =>
            (fieldTypes, annotation))
           (P.tuple2 (EP.SEnv ty,
                      P.refNonCycle recordAnnotation)))

        fun pu_RAWty pu = 
          P.con1 AT.RAWty
          (
           fn AT.RAWty arg => arg
            | _ => raise Control.Bug "RAWty expected: AnnotatedTypesPickler"
           )
          (P.conv
           (fn (tyCon, args) => 
            {tyCon=tyCon, args=args},
            fn {tyCon, args} => 
            (tyCon, args))
           (P.tuple2 (tyCon, P.list ty)))

        fun pu_POLYty pu =
          P.con1 AT.POLYty
          (
           fn AT.POLYty arg => arg
            | _ => raise Control.Bug "POLYty expected: AnnotatedTypesPickler"
           )
          (P.conv
           (fn (boundtvars,body) =>
            {boundtvars=boundtvars, body=body},
            fn {boundtvars,body} =>
            (boundtvars,body))
           (P.tuple2 (EP.IEnv btvKind, ty)))

(*
 * Is this a simple mistake?
 *
        fun pu_SPECty pu =
          P.con1 AT.PREDEFINEDty
          (
           fn AT.PREDEFINEDty arg => arg
            | _ => raise Control.Bug "PREDEFINEDty expected: AnnotatedTypesPickler"
           )
          (P.conv
           (fn (tyCon, args) => 
            {tyCon=tyCon, args=args},
            fn {tyCon, args} => 
            (tyCon, args))
           (P.tuple2 (tyCon, P.list ty)))
*)

        fun pu_SPECty pu =
          P.con1 AT.SPECty
          (
           fn AT.SPECty arg => arg
            | _ => raise Control.Bug "SPECty expected: AnnotatedTypesPickler"
           )
          (P.conv
           (fn (tyCon, args) => 
            {tyCon=tyCon, args=args},
            fn {tyCon, args} => 
            (tyCon, args))
           (P.tuple2 (tyCon, P.list ty)))

      in
        P.data 
        (
         toInt, 
         [
          pu_ERRORty,
          pu_DUMMYty,
          pu_BOUNDVARty,
          pu_FUNMty,
          pu_MVALty,
          pu_RECORDty,
          pu_RAWty,
          pu_POLYty,
          pu_SPECty
          ]
         )
      end

    val newRecordKind =
      let
        fun toInt (AT.UNIV) = 0
          | toInt (AT.REC _) = 1
        fun pu_UNIV pu = P.con0 AT.UNIV pu
        fun pu_REC pu = 
          P.con1 AT.REC
          (
           fn AT.REC arg => arg
            | _ => raise Control.Bug "REC expected: AnnotatedTypesPickler"
           )
          (EP.SEnv ty)
      in
        P.data (toInt, [pu_UNIV, pu_REC])
      end
  in	
    val _ = P.updateNullPu tyFunctions newTy
    val _ = P.updateNullPu recordKindFunctions newRecordKind
    val _ = P.updateNullPu tyBindInfoFunctions newTyBindInfo
  end
end
end
