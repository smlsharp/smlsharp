(* This code requires Excel.sml generated as follows.
 *
 *   $ OLE2SML.exe -c Application -c Workbooks -c Workbook -c Worksheets -c Worksheet -c Range Excel.Application
 *)

use "OLE.sml";

OLE.initialize [OLE.COINIT_MULTITHREADED];

use "./Excel.sml";

val excel = Excel.newApplication ();
val _ = #setVisible excel true;

(* traverse object hierarchy. *)
val workbooks = Excel.Workbooks(#getWorkbooks excel ());
val workbook = Excel.Workbook(#Add workbooks NONE);
val worksheets = Excel.Worksheets(#getSheets workbook ());

(* access indexed property *)
val sheetCount = #getCount worksheets ();
val worksheet = Excel.Worksheet (#getItem worksheets (OLE.I4 1));

(* exception raised by COM object *)
(#Goto excel (SOME(OLE.BSTR(OLE.L"hoge")), NONE); "bug")
handle (OLE.OLEError(OLE.ComApplicationError ({source, description, ...}))) =>
       (source ^ ":" ^ description ^ "\n")
     | (e as OLE.OLEError _) => (exnMessage e);

(* a range consisting of single cell. *)
val range1 = Excel.Range(#getRange worksheet (OLE.BSTR(OLE.L"A1"), NONE));
val _ = #setValue range1 (OLE.BSTR(OLE.L"North"));
val OLE.BSTR(value) = #getValue range1 ();
OLE.A value;

(* a range consisting of array of cells. *)
val range2 = Excel.Range(#getRange worksheet (OLE.BSTR(OLE.L"A1:C2"), NONE));
val vararray =
    OLE.VARIANTARRAY
        (
          Array.fromList
              (map (OLE.BSTR o OLE.L) ["1", "2", "3", "4", "5", "6"]),
          [2, 3]
        );
val _ = #setValue range2 vararray;
val OLE.VARIANTARRAY (a, ls) = #getValue range2 ();
val cellTexts = Array.foldr (op :: ) [] a;

#Select range2 ();
#Cut range2 NONE;

(* finish *)
#setSaved workbook true;
#Quit excel ();

#release range2 ();
#release range1 ();
#release worksheet ();
#release worksheets ();
#release workbook ();
#release workbooks ();
#release excel ();

SMLSharp.GC.collect(SMLSharp.GC.Minor);

OLE.uninitialize ();

