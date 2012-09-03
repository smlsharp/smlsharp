(**
 * NativeDataTransporter is a data structure converter between ML value and
 * 'native' data structure.
 * <p>
 * 'Native' means that its binary layout is explicitly specified.
 * 'Native' data structure is assumed to be passed between ML code and foreign
 * functions.
 * </p>
 * <p>
 * 'Transport' means transportion of ML value residing in ML heap to/from
 * 'native' data structure residing at outside of ML heap.
 * Because the 'native' data structure is graph of memory blocks connected
 * by pointers, this module is not a serializer which converts ML value into
 * a sequence.
 * </p>
 * <p>
 * Module interface is inspired by the serialize combinator of
 * "Type-Specialized Serialization with Sharing", Martin Elsman.
 * </p>
 *
 * <h3>'native' data structure</h3>
 * <p>
 * In some cases, passing ML values directly to foreign function causes
 * a problem for the following reasons.
 * <ul>
 *  <li>Garbage collector relocates ML values. </li>
 *  <li>SML# compiler performs some optimization on the assumption that ML
 *    value is not mutated in foreign function call, except for
 *    <code>ref</code> and <code>array</code>. </li>
 *  <li>Internally, SML# compiler transforms a tuple of relative large size
 *    into nested tuples of smaller sizes. Its actual layout in runtime is
 *    hidden to user.</li>
 * </ul>
 * </p>
 * <p>
 * The <code>export</code> function of this module converts ML value into
 * 'native' data which has following properties.
 * <ul>
 *   <li>allocated in fixed memory block.</li>
 *   <li>mutable.</li>
 *   <li>binary layout is specified explicitly.</li>
 * </ul>
 * In most situations, passing such 'native' data to foreign functions is
 * expected to be safe.
 * </p>
 *
 * <h3>passing an argument to foreign function</h3>
 * <p>
 * A typical usage of this module is to build a native data to pass to a
 * foreign function as argument.
 * </p>
 * <p>
 * Asssume we write a ML code to call a foreign function 'f' in a library
 * "libfoo", which has following signature.
 * <pre>
 * struct s{int x; int y;};
 * void f(struct s* p);
 * </pre>
 * First, we links to this function dynamically as folllows.
 * <pre>
 * structure S = NativeDataTransporter;
 * val lib = DynamicLink.dlsym "libfoo";
 * val f = DynamicLink.dlsym (lib, "f")
 *             : _import (UnmanagedMemory.address) -> unit;
 * </pre>
 * Then, we can use NativeDataTransporter to pass an argument to it as follows.
 * <ol>
 *   <li>build a transporter for the parameter by combining combinators
 *     according to ML type and structure of 'native' data.
 * <pre>
 *  val t = S.boxed (S.tuple2 (S.refNonNull int, S.refNonNull int));
 * </pre>
 *     </li>
 *   <li>export the argument by passing the argument and the transporter to
 *     <code>export</code> function.
 * <pre>
 *  val arg = (ref 1, ref 2);
 *  val e = S.export t arg;
 * </pre>
 *     </li>
 *   <li>obtain the address of the exported 'native' data.
 * <pre>
 *  val a = S.addressOf e;
 * </pre>
 *     </li>
 *   <li>call the foreign function with the obtained address as argument.
 * <pre>
 *  val r = f a;
 * </pre>
 *     </li>
 *   <li>if the foreign function mutates the contents of the argument, call
 *     <code>import</code> function to obtain the updated contents of 'native'
 *     data.
 * <pre>
 *  val arg' = S.import e;
 * </pre>
 *     </li>
 *   <li>call <code>release</code> function to release memory area which
 *     <code>export</code> allocated.
 * <pre>
 *  val _ = S.release e;
 * </pre>
 *       But, do not call <code>release</code> while the foreign code holds a
 *      reference to the 'native' data.
 *     </li>
 * </ol>
 * </p>
 *
 * <h3>accessing return value from foreign function</h3>
 * <p>
 * Another typical usage of this module is to convert a native data returned
 * from a foreign function into a ML value.
 * </p>
 * <p>
 * Assume a foreign function 'g' in "libfoo".
 * </p>
 * <pre>
 * struct s{int x; int y;};
 * struct s* g();
 * </pre>
 * As above example, this function is dynamically linked to ML code as follows.
 * <pre>
 * structure S = NativeDataTransporter;
 * val lib = DynamicLink.dlsym "libfoo";
 * val g = DynamicLink.dlsym (lib, "g")
 *             : _import () -> UnmanagedMemory.address
 * </pre>
 * Then, we can use NativeDataTransporter to import the return value from
 * <code>g</code> as follows.
 * <ol>
 *   <li>build a transporter for the return value by combining combinators
 *     according to ML type and structure of 'native' data.
 * <pre>
 *  val t = S.boxed (S.tuple2 (S.refNonNull int, S.refNonNull int));
 * </pre>
 *     </li>
 *   <li>call the foreign function to obtain the return value, which is a
 *     pointer to 'native' data.
 * <pre>
 *  val ptr = g ();
 * </pre>
 *     </li>
 *   <li>attach the transporter with the returned pointer value.
 * <pre>
 *  val e = S.attach t ptr;
 * </pre>
 *     </li>
 *   <li>call <code>import</code> function to obtain the contents of the
 *     returned 'native' data.
 * <pre>
 *  val r = S.import e;
 * </pre>
 *     </li>
 * </ol>
 * </p>
 *
 * <h3>boxing and unboxing transporter</h3>
 * <p>
 * 'Native' data structure is a graph of memory blocks connected by pointers.
 * At <code>export</code>, transporters build such graph by allocating memory
 * blocks and connecting them by pointers.
 * And at <code>import</code>, they traverse such graph by tracing pointers.
 * </p>
 * <p>
 * Transporters are categorized into boxing transporters and unboxing
 * transporters.
 * At <code>export</code>, a boxing transporter allocates a new memory block
 * and exports the value into there, and writes the address of the new memory
 * block into the current memory block.
 * A unboxing transporter writes the value in the current memory block.
 * </p>
 * <p>
 * For example, the following two transporters transport ML values of the same
 * type <code>int * (int * int) * int</code>.
 * <pre>
 * val bt = tuple3(int, boxed (tuple2 (int, int)), int);
 * val ut = tuple3(int, tuple2 (int, int), int);
 * </pre>
 * But <code>bt</code> is a boxing transporter, while <code>ut</code> is a
 * unboxing transporter.
 * </p>
 * <p>
 * Their corresponding 'native' data structures are different.
 * <pre>
 * struct sbt1 {int x1; int x2;};
 * struct sbt2 {int x1; struct sbt1* x2; int x3;};
 * struct sut {int x1; int x21; int x22; int x3;};
 * </pre>
 * The transporter <code>bt</code> transports <code>sbt2</code>,
 * while the transporter <code>ut</code> transports <code>sut</code>.
 * </p>
 * 
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: NATIVE_DATA_TRANSPORTER.sig,v 1.2 2007/05/20 05:32:56 kiyoshiy Exp $
 *)
signature NATIVE_DATA_TRANSPORTER =
sig

  (**
   * transport combinator to export and import data structures of type 'a.
   *)
  type 'a transporter

  (**
   * reference to a 'native' data structure transported to/from a value of ML
   * type <code>'a</code>.
   *)
  type 'a external

  (** raised when unexpected null address is found at <code>import</code>. *)
  exception NullPointerException

  (**
   * exports a ML data structure into memory blocks which can be passed to
   * foreign functions and can be mutated by them.
   * <p>
   * Example. The C function 'f' takes an address of a data structure and
   * modifies the contents of the argument.
   * <pre>
   * struct s{int x; int y;};
   * void f(struct s* p){p->x = p->x * 10;}
   * </pre>
   * The following ML code calls this 'f' and converts the returned address to
   * a ML data structure.
   * <pre>
   * structure S = NativeDataTransporter;
   * val f = DynamicLink.dlsym (lib, "f")
   *             : _import (UnmanagedMemory.address) -> unit;
   * val transporter = S.boxed(S.tuple2(S.int, S.int));
   * val s = (1, 2);
   * val r = S.export transporter s;
   * val _ = f(S.addressOf r);
   * val (x, y) = S.import r; (* We obtain x = 10, y = 2. *)
   * val _ = S.release r;
   * </pre>
   *)
  val export : 'a transporter -> 'a -> 'a external

  (**
   * prepares to import a data structure in a (external) memory area.
   * <p>
   * This function is expected to be used to obtain a data structure returned
   * from a foreign function.
   * </p>
   * <p>
   * Example. The C function 'g' returns an address of a data structure.
   * <pre>
   * struct s{int x; int y;};
   * struct s g_x = {1, 2};
   * struct s* g(){return &g_x;}
   * </pre>
   * The following ML code calls this 'g' and converts the returned address to
   * a ML data structure.
   * <pre>
   * structure S = NativeDataTransporter;
   * val g = DynamicLink.dlsym (lib, "g")
   *             : _import () -> UnmanagedMemory.address
   * val transporter = S.boxed(S.tuple2(S.int, S.int));
   * val ptr = g();
   * val r = S.attach transporter ptr;
   * val (x, y) = S.import r; (* We obtain x = 1 and y = 2. *)
   * val _ = S.release r;
   * </pre>
   * </p>
   *)
  val attach : 'a transporter -> UnmanagedMemory.address -> 'a external

  (**
   * obtains the address of memory area in which the data structure is
   * exportd.
   *)
  val addressOf : 'a external -> UnmanagedMemory.address

  (**
   * imports a data structure.
   * @exception NullPointerException
   *)
  val import : 'a external -> 'a

  (**
   * releases memory areas allocated to hold exportd data structure.
   * <p>
   * <code>export</code> allocates memory blocks outside of the GC heap.
   * This <code>release</code> releases these memory blocks.
   * Client has to invoke this function after the exportd data becomes no
   * use.
   * But, client should not invoke it before deserializing, because
   * <code>import</code> accesses these memory blocks.
   * And, client should not invoke it while a foreign code holds some
   * reference to the memory blocks.
   * </p>
   *)
  val release : 'a external -> unit

  (****************************************)

  (* base transporters *)

  val byte : Word8.word transporter
  (**
   * a transporter which packs a word in the native byte order of the platform
   * on which the runtime runs.
   *)
  val word : Word.word transporter
  (**
   * a transporter which packs a word in the big-endian byte order.
   *)
  val wordBig : Word.word transporter
  (**
   * a transporter which packs a word in the little-endian byte order.
   *)
  val wordLittle : Word.word transporter
  (**
   * a transporter which packs a 32-bit word in the native byte order of the
   * platform on which the runtime runs.
   *)
  val word32 : Word32.word transporter
  (**
   * a transporter which packs a 32-bit word in the big-endian byte order.
   *)
  val word32Big : Word.word transporter
  (**
   * a transporter which packs a 32-bit word in the little-endian byte order.
   *)
  val word32Little : Word.word transporter
  (**
   * a transporter which packs an int in the native byte order of the
   * platform on which the runtime runs.
   *)
  val int : int transporter
  (**
   * a transporter which packs an int in the big-endian byte order.
   *)
  val intBig : int transporter
  (**
   * a transporter which packs an int in the little-endian byte order.
   *)
  val intLittle : int transporter
  (**
   * a transporter which packs a 32-bit int in the native byte order of the
   * platform on which the runtime runs.
   *)
  val int32 : Int32.int transporter
  (**
   * a transporter which packs a 32-bit int in the big-endian byte order.
   *)
  val int32Big : int transporter
  (**
   * a transporter which packs a 32-bit int in the little-endian byte order.
   *)
  val int32Little : int transporter
  (**
   * a transporter which packs a real in the native byte order of the
   * platform on which the runtime runs.
   *)
  val real : real transporter
  (**
   * a transporter which packs a real in the big-endian byte order.
   *)
  val realBig : real transporter
  (**
   * a transporter which packs a real in the little-endian byte order.
   *)
  val realLittle : real transporter

  (**
   * a transporter of char.
   *)
  val char : char transporter

  (**
   * transporter of a pointer to a null terminated string.
   * This is corresponding to
   * <pre>
   * char*
   * </pre>
   * <p>
   * At export, this transporter allocates a memory block, copies the string
   * to there, and writes the address of this memory block.
   * </p>
   * <p>
   * At import, this transporter reads an address of a memory block, scans
   * from the address until 0w0 is found to collect characters, and builds
   * a string from them.
   * </p>
   *)
  val string : string transporter

  (**
   * a transporter of memory address.
   *)
  val address : UnmanagedMemory.address transporter

  (* transport constructors *)
  val tuple2 : 'a transporter * 'b transporter -> ('a * 'b) transporter
  val tuple3 : 'a transporter * 'b transporter * 'c transporter -> ('a * 'b * 'c) transporter
  val tuple4 : 'a transporter * 'b transporter * 'c transporter * 'd transporter -> ('a * 'b * 'c * 'd) transporter
  val tuple5
      : 'a transporter * 'b transporter * 'c transporter * 'd transporter * 'e transporter -> ('a * 'b * 'c * 'd * 'e) transporter
  val tuple6
      : 'a transporter * 'b transporter * 'c transporter * 'd transporter * 'e transporter * 'f transporter
        -> ('a * 'b * 'c * 'd * 'e * 'f) transporter
  val tuple7
      : 'a transporter * 'b transporter * 'c transporter * 'd transporter * 'e transporter * 'f transporter * 'g transporter
        -> ('a * 'b * 'c * 'd * 'e * 'f * 'g) transporter
  val tuple8
      : 'a transporter * 'b transporter * 'c transporter * 'd transporter * 'e transporter * 'f transporter * 'g transporter * 'h transporter
        -> ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h) transporter
  val tuple9
      : 'a transporter * 'b transporter * 'c transporter * 'd transporter * 'e transporter * 'f transporter * 'g transporter * 'h transporter * 'i transporter
        -> ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i) transporter
  val tuple10
      : 'a transporter * 'b transporter * 'c transporter * 'd transporter * 'e transporter * 'f transporter * 'g transporter * 'h transporter * 'i transporter * 'j transporter
        -> ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j) transporter

  (**
   * transporter of a pointer to 'a.
   * If null is found at 'import', NullPointerException is raised.
   * <p>
   * This transporter and refNullable keep the sharing property of references.
   * Example.
   * <pre>
   * val r1 = ref 1
   * val r2 = ref 2
   * val refInt = refNonNull 0 int
   * val t = boxed (tuple3 (refInt, refInt, refInt))
   * val e = export t (r1, r1, r2)
   * val (rA, rB, rC) = import e
   * </pre>
   * </p>
   * <p>
   * In the exported data structure 'e' which has three fields of pointers,
   * the first field and the second field points to the same block,
   * but the third field points to another block.
   * 'Import' also keeps this sharing property. So, rA is equal to rB, but not
   * to rC.
   * </p>
   * <p>
   * And, this transporter keeps the sharing property between export and
   * import also. In this example, r1 and rA, rB are equal to each other.
   * </p>
   *)
  val refNonNull : 'a -> 'a transporter -> 'a ref transporter
  (**
   * transporter of pointer to 'a.
   * If null is found at 'import', returns NONE.
   *)
  val refNullable : 'a -> 'a transporter -> 'a ref option transporter

  (**
   * transporter of boxed representation of 'a.
   * It is corresponding to C type
   * <pre>
   *  t*
   * </pre>
   * where C type t corresponds to the ML type which 'a is instantiated to.
   * <p>
   * NullPointerException is raised if import finds a NULL.
   * </p>
   *)
  val boxed : 'a transporter -> 'a transporter
  (**
   * transporter of boxed representation of 'a.
   * If null is found at 'import', returns NONE.
   *)
  val boxedNullable : 'a transporter -> 'a option transporter

  (**
   * transporter of array of unboxed elements.
   * <p>
   * For example, assume calling C function 'f' from ML code.
   * <pre>
   *  struct s{unsigned int x; int y;};
   *  void f(int num, struct s* p)
   *  {
   *    int index;
   *    for(index = 0; index < num; index++){
   *        p[index].x = p[index].x * 10;
   *    }
   *  }
   * </pre>
   * 'f' takes an array of struct s.
   * It is not an array of pointers to struct s.
   * How can we represent it in ML ?
   * <pre>
   *  (word * int) array
   * </pre>
   * is wrong, because this is an array of pointers to records.
   * </p>
   * <p>
   * Using NativeDataTransporter, we can build such 'flat' array as follows.
   * <pre>
   *  val lib = DynamicLink.dlopen "/home/yamato/tmp/foo.dll";
   *  val f = DynamicLink.dlsym (lib, "f")
   *            : _import (int, UnmanagedMemory.address) -> unit;
   *
   *  structure F = NativeDataTransporter;
   *  val transporter = F.flatArray (F.tuple2 (F.word, F.int));
   *
   *  val array = Array.fromList [(0w1, 2), (0w3, 4)];
   *  val ext = F.export transporter array;
   *  val _ = f (Array.length ar, F.addressOf ext);
   *  val array' = F.import ext;
   *  val (x, y) = Array.sub (array, 0); (* we have x = 0w10, y = 2 *)
   * </pre>
   * </p>
   * <p>
   * If 'f' takes an array of pointers to struct s, as follows,
   * <pre>
   *  struct s{unsigned int x; int y;};
   *  void f(int num, struct s** p)
   *  {
   *    int index;
   *    for(index = 0; index < num; index++){
   *        p[index]->x = p[index]->x * 10;
   *    }
   *  }
   * </pre>
   * 'boxed' combinator is used.
   * <pre>
   *  val transporter = F.flatArray (F.boxed(F.tuple2 (F.word, F.int)));
   * </pre>
   * </p>
   *)
  val flatArray : 'a transporter -> 'a Array.array transporter

  (**
   * transporter of FLOB(= Fixed Location OBject).
   * the dummy argument is necessary to give polymorphic type.
   *)
  val FLOB : unit -> 'a SMLSharp.FLOB.FLOB transporter

  (**
   * This transporter assures that 'native' data of <code>'a</code> is located
   * at alignment of the specified bytes.
   * <p>
   * In other words, this assures 
   * <pre>
   *   block % alignment == 0
   * </pre>
   * where <code>block</code> is the address of a memory block.
   * </p>
   * <p>
   * (SML# assures that memory blocks are located at alignment of 8 bytes.)
   * </p>
   * @params alignment trans
   * @param alignment the number of bytes of alignment.
   * @param trans transporter
   *)
  val align : int -> 'a transporter -> 'a transporter

  (**
   * generates a transporter of a type from a transporter of another type.
   *)
  val conv : ('a -> 'b) * ('b -> 'a) -> 'a transporter -> 'b transporter

end;
