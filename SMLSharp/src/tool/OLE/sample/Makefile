TARGETS = \
	Excel.sml \
	MSHTML.sml \
	SHDocVw.sml \
	Scripting.sml \
	mscorlib.sml \


OLE2SML = ../OLE2SML.exe

all: $(TARGETS)

clean:
	-rm -f $(TARGETS)

Excel.sml:
	$(OLE2SML) -c Application -c Workbooks -c Workbook -c Worksheets -c Worksheet -c Range Excel.Application

MSHTML.sml:
	$(OLE2SML) -c HTMLDocument -c HTMLHtmlElement "C:\\WINDOWS\\system32\\MSHTML.TLB"

SHDocVw.sml:
	$(OLE2SML) InternetExplorer.Application

Scripting.sml:
	$(OLE2SML) Scripting.FileSystemObject

mscorlib.sml:
	$(OLE2SML) System.Collections.Stack
