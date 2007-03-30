(**
 * ArithmeticOptimizer.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ArithmeticOptimizer.sml,v 1.6 2006/11/06 01:50:00 kiyoshiy Exp $
 *)

(* This module simulates a simple numeric algebra and provides facilities for 
 * generating an optimized instruction list for computing a bunch of formulas.
 *)

structure ArithmeticOptimizer = struct

  structure BT = BasicTypes
  structure VMap = IEnv
  structure VSet = ISet
  type const = Word32.word
  type var = int
  type tid = int

  datatype exp =
     CONST of const
   | VAR of var
   | ADD of exp * exp
   | AND of exp * exp
   | OR of exp * exp
   | LSHIFT of exp * exp
   | RSHIFT of exp * exp
   | SIZE of tid
   | TAG of tid

  type batch = exp VMap.map
  exception VAR_FOUND of var

(**************************************************)
(*Printing utilities*)

  fun formatExp e =
      case e of
        CONST c => Word32.toString c
      | VAR v => "$" ^ (Int.toString v)
      | TAG tid => "tag(" ^ (Int.toString tid) ^ ")"
      | SIZE tid => "size(" ^ (Int.toString tid) ^ ")"
      | ADD(e1,e2) => (formatExp e1) ^ " + " ^ (formatExp e2)
      | AND(e1,e2) => (formatExp e1) ^ " AND " ^ (formatExp e2)
      | OR(e1,e2) => (formatExp e1) ^ " OR " ^ (formatExp e2)
      | LSHIFT(e1,e2) => (formatExp e1) ^ " << " ^ (formatExp e2)
      | RSHIFT(e1,e2) => (formatExp e1) ^ " >> " ^ (formatExp e2)

  fun formatBind (v,e) =
      (formatExp (VAR v)) ^ " = " ^ (formatExp e)

(**************************************************)
(*Merge Sort*)

  fun merge ([], []) = []
    | merge (L, []) = L
    | merge ([], L) = L
    | merge (x::xs, y::ys) =
      if x <= y 
      then x :: merge(xs, y::ys)
      else y :: merge(x::xs, ys)
           
  fun split L = 
      let
        val len = List.length L
        val halflen = Int.div (len, 2)
      in
        (List.take (L, halflen), List.drop (L, halflen))
      end

  fun mergeSort [] = []
    | mergeSort [x] = [x]
    | mergeSort L = 
      let
        val (left, right) = split L
      in
        merge (mergeSort left, mergeSort right)
      end

(**************************************************)

  local 
    val varSeed = ref 0
  in
    fun initialize () = varSeed := 0
    fun newVar () = (varSeed := !varSeed + 1; !varSeed);
  end

  val empty  = (VMap.empty) : batch

  (*compare two atomic formulas*)
  fun eq (CONST c1, CONST c2) = c1 = c2
    | eq (VAR v1, VAR v2) = v1 = v2
    | eq (SIZE tid1, SIZE tid2) = tid1 = tid2
    | eq (TAG tid1, TAG tid2) = tid1 = tid2
    | eq (ADD (exp11,exp12), ADD(exp21,exp22)) =
      (eq(exp11,exp21) andalso eq(exp12,exp22)) orelse
      (eq(exp11,exp22) andalso eq(exp12,exp21))
    | eq (AND (exp11,exp12), AND(exp21,exp22)) =
      (eq(exp11,exp21) andalso eq(exp12,exp22)) orelse
      (eq(exp11,exp22) andalso eq(exp12,exp21))
    | eq (OR (exp11,exp12), OR(exp21,exp22)) =
      (eq(exp11,exp21) andalso eq(exp12,exp22)) orelse
      (eq(exp11,exp22) andalso eq(exp12,exp21))
    | eq (LSHIFT (exp11,exp12), LSHIFT(exp21,exp22)) =
      eq(exp11,exp21) andalso eq(exp12,exp22)
    | eq (RSHIFT (exp11,exp12), RSHIFT(exp21,exp22)) =
      eq(exp11,exp21) andalso eq(exp12,exp22)
    | eq (_,_) = false

  (*Find an atomic formula*)
  fun findExp (batch,exp) =
      case exp of 
        VAR v => SOME v
      | _ =>
        (
         VMap.appi
             (fn (v,e) => 
                 if eq(e,exp) 
                 then raise VAR_FOUND v
                 else ()
             )
             batch;
         NONE
        ) handle VAR_FOUND v => SOME v

  fun lookup (batch,v) =
      case VMap.find(batch,v) of
        SOME e => e
      | NONE => raise Control.Bug "variable not found"

  (*insert an atomic formula into a batch*)
  fun insertAtom (batch,exp) =
      case findExp (batch,exp) of
        SOME v => (batch,v)
      | NONE => 
        let 
          val v = newVar()
        in 
          (VMap.insert(batch,v,exp),v)
        end

  fun atomArg (v,e) =
      case e of
        CONST _ => e
      | _ => VAR v

  fun insertBinaryAtom (batch,operator,arg1,arg2) =
      case (arg1,arg2) of
        (CONST _, _) => insertAtom(batch,operator(arg2,arg1))
      | (_,_) => insertAtom(batch,operator(arg1,arg2))

  (*insert a composite formula into a batch*)
  fun insert (batch,exp) =
      case exp of
        CONST _ => insertAtom(batch,exp)
      | VAR v => (batch,v)
      | SIZE _ => insertAtom(batch,exp)
      | TAG _ => insertAtom(batch,exp)
      | ADD (e1,e2) => insertAdd(batch,e1,e2)
      | AND (e1,e2) => insertAnd(batch,e1,e2)
      | OR (e1,e2) => insertOr(batch,e1,e2)
      | LSHIFT(e1,e2) => insertLShift(batch,e1,e2)
      | RSHIFT(e1,e2) => insertRShift(batch,e1,e2)

  (*insert an ADD formula and performing optimization
   * e + 0 = e
   * (e + c) + c = (e + (c + c))
   *)
  and insertAdd (batch,e1,e2) =
      let
        val (batch,v1) = insert(batch,e1)
        val (batch,v2) = insert(batch,e2)
      in
        case (lookup(batch,v1),lookup(batch,v2)) of
          (CONST c1,CONST c2) => insertAtom(batch,CONST (c1+c2))
        | (e,CONST 0w0) => (batch,v1)
        | (CONST 0w0,e) => (batch,v2)
        | (ADD(e,CONST c1),CONST c2) => insertAdd(batch,e,CONST(c1+c2))
        | (CONST c1,ADD(e,CONST c2)) => insertAdd(batch,e,CONST(c1+c2))
        | (e1',e2') => 
          insertBinaryAtom(batch,ADD,atomArg(v1,e1'),atomArg(v2,e2'))
      end

  (*insert an AND formula and performing optimization
   * e AND 0 = 0
   * (e AND c) AND c = (e AND (c AND c))
   *)
  and insertAnd (batch,e1,e2) =
      let
        val (batch,v1) = insert(batch,e1)
        val (batch,v2) = insert(batch,e2)
      in
        case (lookup(batch,v1),lookup(batch,v2)) of
          (CONST c1,CONST c2) => insertAtom(batch,CONST (Word32.andb(c1,c2)))
        | (e,CONST 0w0) => (batch,v2)
        | (CONST 0w0,e) => (batch,v1)
        | (AND(e,CONST c1),CONST c2) => insertAnd(batch,e,CONST(Word32.andb(c1,c2)))
        | (CONST c1,AND(e,CONST c2)) => insertAdd(batch,e,CONST(Word32.andb(c1,c2)))
        | (e1',e2') => 
          insertBinaryAtom(batch,AND,atomArg(v1,e1'),atomArg(v2,e2'))
      end

  (*insert an OR formula and performing optimization
   * e OR 0 = e
   * (e OR c) OR c = (e OR (c OR c))
   *)
  and insertOr (batch,e1,e2) =
      let
        val (batch,v1) = insert(batch,e1)
        val (batch,v2) = insert(batch,e2)
      in
        case (lookup(batch,v1),lookup(batch,v2)) of
          (CONST c1,CONST c2) => insertAtom(batch,CONST (Word32.orb(c1,c2)))
        | (e,CONST 0w0) => (batch,v1)
        | (CONST 0w0,e) => (batch,v2)
        | (OR(e,CONST c1),CONST c2) => insertOr(batch,e,CONST(Word32.orb(c1,c2)))
        | (CONST c1,OR(e,CONST c2)) => insertOr(batch,e,CONST(Word32.orb(c1,c2)))
        | (e1',e2') => 
          insertBinaryAtom(batch,OR,atomArg(v1,e1'),atomArg(v2,e2'))
      end

  (*insert a LSHIFT formula and performing optimization
   * e >> 0 = e
   * 0 >> e = 0
   * (e >> c) >> c = (e >> (c + c))
   *)
  and insertLShift (batch,e1,e2) =
      let
        val (batch,v1) = insert(batch,e1)
        val (batch,v2) = insert(batch,e2)
      in
        case (lookup(batch,v1),lookup(batch,v2)) of
          (CONST c1,CONST c2) => insertAtom(batch,CONST (Word32.<<(c1,BT.UInt32ToWord c2)))
        | (e,CONST 0w0) => (batch,v1)
        | (CONST 0w0,e) => (batch,v1)
        | (LSHIFT(e,CONST c1),CONST c2) => insertLShift(batch,e,CONST(c1 + c2))
        | (e1',e2') => 
          insertAtom(batch,LSHIFT(atomArg(v1,e1'),atomArg(v2,e2')))
      end

  (*insert a RSHIFT formula and performing optimization
   * e << 0 = e
   * 0 << e = 0
   * (e << c) << c = (e << (c + c))
   *)
  and insertRShift (batch,e1,e2) =
      let
        val (batch,v1) = insert(batch,e1)
        val (batch,v2) = insert(batch,e2)
      in
        case (lookup(batch,v1),lookup(batch,v2)) of
          (CONST c1,CONST c2) => insertAtom(batch,CONST (Word32.>>(c1,BT.UInt32ToWord c2)))
        | (e,CONST 0w0) => (batch,v1)
        | (CONST 0w0,e) => (batch,v1)
        | (RSHIFT(e,CONST c1),CONST c2) => insertRShift(batch,e,CONST(c1 + c2))
        | (e1',e2') => 
          insertAtom(batch,RSHIFT(atomArg(v1,e1'),atomArg(v2,e2')))
      end

  (*list a minimum variable set for computing an expression*)
  fun dependences (batch, e) =
      case e of
        CONST _ => VSet.empty
      | VAR v => VSet.add(dependences(batch,lookup(batch,v)),v)
      | TAG _ => VSet.empty
      | SIZE _ => VSet.empty
      | ADD(e1,e2) => VSet.union(dependences(batch,e1),dependences(batch,e2))
      | AND(e1,e2) => VSet.union(dependences(batch,e1),dependences(batch,e2))
      | OR(e1,e2) => VSet.union(dependences(batch,e1),dependences(batch,e2))
      | LSHIFT(e1,e2) => VSet.union(dependences(batch,e1),dependences(batch,e2))
      | RSHIFT(e1,e2) => VSet.union(dependences(batch,e1),dependences(batch,e2))

  (*extract an ordered list of instructions that forms a computation trees rooted by varList *)
  fun extract (batch,varList) =
      let
        val dependentVars =
            foldl 
                (fn (v,S) => VSet.union(S,dependences(batch,VAR v)))
                VSet.empty
                varList
      in
        map 
            (fn v => (v,lookup(batch,v))) 
            (mergeSort (VSet.listItems dependentVars))
      end

end

