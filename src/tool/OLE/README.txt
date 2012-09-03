OLE/SML#

 OLE/SML# is a support tool to enable SML code to access Microsoft COM/OLE objects.

@author YAMATODANI Kiyoshi
@version $Id: README.txt,v 1.12 2007/04/02 09:42:30 katsu Exp $

----------
Products.

  OLE2SML.exe
    Given a type library, this command generates SML# source code to
   access COM objects which are described in the type library.

  OLE.sml
    Base library to access Microsoft COM infrastructure.

----------
Usage.

 OLE2SML.exe generates SML code from user specified type library.

 Type library can be specified by
- file path of the type library, or
- ProgID of a Coclass of which type information is described in the type
 library.

   $ OLE.exe [options] TYPELIB_FILENAME
   $ OLE.exe [options] ProgID

Options:

   -c CLASSNAME   generates wrapper codes for specified coclasses or dispatch
                 interfaces only.
                 You can use this option more than once.
                 If no -c option is specified, wrappers for all coclasses and
                 dispatch interfaces are generated.
   -o FILENAME    writes wrapper code into the specified file name.
                 If no -o option is specified, file name is TYPELIBNAME.sml .
   -h             shows usage.

----------
Restriction.

 OLE structure and OLE2SML ignore methods which satisfy any of following.

  - any of its parameters has [out] or [ret] attribute.
  - any of its parameters is variant type which is not included in OLE.variant.

----------
Example use.

 For example, ProgID of Internet Explorer (= IE) is "InternetExplorer.Application".
The following session creates an IE instance, navigates to Home page and obtains URL of Home page.

  $ OLE2SML.exe -c InternetExplorer InternetExplorer.Application
  generated SHDocVw.sml
  $ OLE2SML.exe -c HTMLDocument -c HTMLHtmlElement \
  >     "C:\\WINDOWS\\system32\\MSHTML.TLB"
  generated MSHTML.sml
  $ OLE2SML.exe "C:\\WINDOWS\\system32\\MSHTML.TLB" *)
  $ smlsharp
  SML# 0.10 (2007-03-01 02:28:47)
  # use "OLE.sml";
  # OLE.initialize [OLE.COINIT_MULTITHREADED];
  # use "./IE.sml";
  # use "./MSHTML.sml";
  # val IE = SHDocVw.newInternetExplorer ();
  # #getVisible IE ();
  # #setVisible IE true;
  # #GoHome IE ();
  # val doc = MSHTML.HTMLDocument (#getDocument IE ());
  # val body = MSHTML.HTMLHtmlElement (#getbody doc ());
  # val bodyText = OLE.A (#getinnerText body ());
  # #release IE ();
  # OLE.uninitialize ();
  # exit 0;

 Instead of ProgID, you can specify file path of type library.

  $ OLE2SML.exe "C:\\WINDOWS\\System32\\shdocvw.dll"

The type library C:\WINDOWS\System32\shdocvw.dll defines COM objects implemented in Internet Explorer.

 By default, OLE2SML.exe generates code for every coclass and interfaces
described in the specified type library.
If you use only some of them, you can specify them with -c option to reduce the size of generated code.

  $ OLE2SML.exe -c InternetExplorer "C:\\WINDOWS\\System32\\shdocvw.dll"

Its generated code contains code for InternetExplorer coclass only.

===============================================================================
Implementation overview.

----------------------------------------
Example.

Source type library (in pseudo MIDL).

  interface Interface1 : IDispatch {
     [id(1)] BSTR method1 ([in] VARIANT_BOOL b);
     [id(2)] int propGet1 ();
     [id(3)] void propPut ([in] IDispatch* d);
  };

  library Lib1
  {
    coclass Coclass1 {
        [default] interface Interface1;
    };
  };

From this type library, generates following SML# code.

  signature LIB1 =
  sig
    type Coclass1 =
         {
           method1 : bool -> OLE.OLEString.string,
           getpropGet1 : unit -> int,
           setpropPut1 : OLE.object -> unit,
           addRef : unit -> OLE.ULONG,
           release : unit -> OLE.ULONG,
           this : OLE.object
         }
    val createCoclass1 : unit -> Coclass1
    val wrapCoclass1 : OLE.object -> Coclass1
  end

  structure Lib1 : LIB1 =
  struct
    type Coclass1 = ...
    fun Coclass1 dispatch = 
        let
          fun method1 p1 =
              case #invokeByDISPID dispatch 1 [OLE.BOOL p1]
                of SOME(OLE.BSTR x) => x
          fun getpropGet1 () =
              case #getByDISPID dispatch 2 ()
                of OLE.I4 x => x
          fun setpropPut1 p1 =
              #setByDISPID dispatch 3 (OLE.DISPATCH p1)
        in
          {
            method1 = method1,
            getpropGet1 = getpropGet1,
            setpropPut1 = setpropPut1,
            addRef = #addRef dispatch,
            release = #release dispatch,
            this = #this dispatch
          }
        end
    fun newCoclass1 () =
        let
          val dispatch =
              OLE.createInstance
                  (OLE.OLEString.fromAsciiString "Lib1.Coclass1")
        in Coclass1 dispatch
        end
  end

----------------------------------------
type mapping

  [VT_BSTR] => OLE.OLEString.string
  [VT_UT1] => Word8.word
  [VT_I4] => Int32.int
  [VT_BOOL] => bool
  [VT_DISPATCH] => OLE.object
  [t VT_PTR] => [t]
      VT_PTR 'a in TYPEDESC corresponds to VT_BYREF in VARIANT.
      Null pointer is not supported.
  [VT_VARIANT VT_SAFEARRAY] => OLE.variant array * word list

If optional parameter of type t, 
  [t] => [t] option

===============================================================================
COM in 3 minutes.

Microsoft COM (= Component Object Model) is object-based interoperability infrastructure.
In other words, COM provides object-based shared library and inter process communication.
OLE is upper layer of COM.

Compared to shared library, COM is characterized as follows.

 Shared library 

  - Library name is a path in a file system.

  - Library exports functions.

 COM

  - Component name is UUID.

    A component is identified by UUID, which is 128bit almost global
   unique ID.
   For example, Microsoft Internet Explorer has its UUID:
     {0002DF01-0000-0000-C000-000000000046}

    COM infrastructure manages mapping between UUID and the location
   of implementation code of the service identified by the UUID.
   In Windows, static information about this mapping is stored in
   registry.
   For the above UUID, the registry has an entry at
     HKEY_CLASSES_ROOT\CLSID\{0002DF01-0000-0000-C000-000000000046}
   By using C:/WINDOWS/regedit.exe, you can see there that the UUID is
   mapped to an executable file:
     "C:\Program Files\Internet Explorer\iexplore.exe"

  - Component exports object.

    From client, COM object is seen as a pair of instance data and
   an array of function pointers.
   Its layout resembles those of object which Microsoft C++ compiler
   generates.
   So, a COM object is seen as an usual object in C++ program if you
   use MS compiler.

 The following is an approximate code in pseudo C to access Internet Explorer.

  typedef struct tagIInternetExplorerVtbl 
  {
    void (*setVisible)(IInternetExplorer* this, bool visible);
    bool (*getVisible)(IInternetExplorer* this);
    void (*navigate)(IInternetExplorer* this, string url);
    void (*quit)(IInternetExplorer* this);
  } IInternetExplorerVtbl;

  typedef struct tagIInternetExplorer 
  {
    IInternetExplorerVtbl* vtbl;
  } IInternetExplorer;

  UUID IEUUID = {0002DF01-0000-0000-C000-000000000046};

  IInternetExplorer* ie =
       (IInternetExplorer*)CoCreateInstance(IEUUID);
  
  ie->vtbl->setVisible(ie, true);
  ie->vtbl->navigate(ie,
                     "http://www.pllab.riec.tohoku.ac.jp/smlsharp/");
  ie->vtbl->quit(ie);

===============================================================================
