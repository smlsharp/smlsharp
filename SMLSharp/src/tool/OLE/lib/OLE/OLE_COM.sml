(**
 * COM fundamentals.
 * @copyright (c) 2010, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
structure OLE_COM =
struct

  (****************************************)

  structure Finalizable = SMLSharp.Finalizable
  structure UM = UnmanagedMemory

  structure OLEString = UTF16LECodec.String

  structure W = OLE_Win32
  structure E = OLE_Error

  (****************************************)

  datatype coinit =
           COINIT_MULTITHREADED
         | COINIT_APARTMENTTHREADED
         | COINIT_DISABLE_OLE1DDE
         | COINIT_SPEED_OVER_MEMORY

  type Unknown =
       {
         addRef : unit -> W.ULONG,
         release : unit -> W.ULONG,
         queryInterface : W.LPGUID -> UM.address,
         this : UM.address Finalizable.finalizable
       }

  (****************************************)

  fun UMSubWord word = UM.subWord (UM.wordToAddress word)

  fun formatMessage hresult =
      let
        val bufferRef = ref 0w0
        val flag =
            Word.orb
              (W.FORMAT_MESSAGE_FROM_SYSTEM, W.FORMAT_MESSAGE_ALLOCATE_BUFFER)
        val numchars = 
            W.FormatMessageW
                (flag, 0w0, hresult, W.LANGID_ENGLISH_US, bufferRef, 0w0, 0w0)
      in
        if numchars = 0w0
        then OLEString.fromAsciiString "cannot format message"
        else
          let
            val bytes =
                UM.import
                    (UM.wordToAddress(!bufferRef), Word.toInt numchars * 2)
            val _ = W.LocalFree (!bufferRef)
          in
            OLEString.bytesToMBS bytes
          end
      end

  fun checkHRESULT hresult =
      if 0 <= Word32.toIntX hresult
      then ()
      else
        raise
          E.OLEError
              (E.ComSystemError
                   (OLEString.toAsciiString (formatMessage hresult)))

  fun initialize coinits =
      let
        fun coinitOf COINIT_MULTITHREADED = W.COINIT_MULTITHREADED
          | coinitOf COINIT_APARTMENTTHREADED = W.COINIT_APARTMENTTHREADED
          | coinitOf COINIT_DISABLE_OLE1DDE = W.COINIT_DISABLE_OLE1DDE
          | coinitOf COINIT_SPEED_OVER_MEMORY = W.COINIT_SPEED_OVER_MEMORY
        val flag = List.foldl Word.orb 0w0 (map coinitOf coinits)
      in
        checkHRESULT (W.CoInitializeEx (0, flag))
      end

  val uninitialize = W.CoUninitialize

  (****************************************)
  (* IUnknown *)

  val NullUnknown =
       {
         addRef = fn () => raise E.OLEError E.NullObjectPointer,
         release = fn () => raise E.OLEError E.NullObjectPointer,
         queryInterface = fn _ => raise E.OLEError E.NullObjectPointer,
         this = Finalizable.new (UM.NULL, fn _ => ())
       } : Unknown

  fun isNullUnknown ({this, ...} : Unknown) =
      UM.isNULL (Finalizable.getValue this)

  fun wrapUnknown ptrUnknown =
      let
        type this = UM.address

        val _ = if UM.isNULL ptrUnknown
                then raise E.OLEError E.NullObjectPointer
                else ()

        val vptr = UM.subWord ptrUnknown

        val fptrQueryInterface = UM.wordToAddress (UMSubWord vptr)
        val IUnknown_QueryInterface =
            fptrQueryInterface
            : _import _stdcall (this, W.REFIID, UM.address ref) -> W.HRESULT

        val fptrAddRef = UM.wordToAddress (UMSubWord (vptr + 0w4))
        val IUnknown_AddRef =
            fptrAddRef : _import _stdcall (this) -> W.ULONG

        val fptrRelease = UM.wordToAddress (UMSubWord (vptr + 0w8))
        val IUnknown_Release =
            fptrRelease : _import _stdcall (this) -> W.ULONG

        val this =
            Finalizable.new (ptrUnknown, fn t => (IUnknown_Release t; ()))

        fun queryInterface IID =
            let
              val resultRef = ref UM.NULL
              val hresult = IUnknown_QueryInterface(ptrUnknown, IID, resultRef)
            in
              checkHRESULT hresult;
              !resultRef
            end

      in
        {
          addRef = fn () => IUnknown_AddRef (Finalizable.getValue this),
          release = fn () => IUnknown_Release (Finalizable.getValue this),
          queryInterface = queryInterface,
          this = this
        } : Unknown
      end

  (****************************************)

end