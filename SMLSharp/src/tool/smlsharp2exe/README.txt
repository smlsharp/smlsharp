smlsharp2exe

 smlsharp2exe is a tool that compiles a SML source code to a 'native' executable file which does not require smlsharprun.exe to run.

@author YAMATODANI Kiyoshi
@version $Id: README.txt,v 1.3 2008/01/13 02:54:49 kiyoshiy Exp $

----------
Usage

  smlsharp2exe.sh [options] FILE

  options:
         -o FILE | --output=FILE     output file name
         -c                          generate .h and .o instead of exe file.
         other                       options for smlsharp are available.

----------------------------------------
Executable file generation.

The main use of this tool will be to generate a native executable file.
Example.

  $ echo 'app print (CommandLine.arguments());' > foo.sml
  $ smlsharp2exe.sh -o foo.exe ./foo.sml
  generated foo.exe.
  $ ./foo.exe hoge bar
  hogebar

----------------------------------------
Object file generation.

With -c option, smlsharp2exe.sh generates an object file instead of .exe file.
You can link this object file with your C program and calls functions defined in SML# file.

See 'sample' directory. 
There is a sample program which links C main code and SML code.

To export SML functions from a generated object file so that they are available from C code linked with the object file, you can use following function transportation mechanism.

SML# runtime defines following functions to import/export SML/C functions.

  void* smlsharp_importSymbol(const char* name);
  void smlsharp_exportSymbol(const char* name, void* ptr);

'smlsharp_importSymbol' imports a SML function into C code.
'smlsharp_exportSymbol' exports a C function into SML code.
These are defined in libsmlsharprun.

In SML code, functions are transported by using DynamicBind structure.

  signature DYNAMIC_BIND =
  sig
    type symbol
    val importSymbol : string -> symbol
    val exportSymbol : (string * symbol) -> unit
  end
  structure DynamicBind : DYNAMIC_BIND

'DynamicBind.importSymbol' imports a C function into SML code.
'DynamicBind.exportSymbol' exports a SML function into C code.
'symbol's are converted from/to SML function, by _export and _import.

A function has to be exported before imported into foregin code.

----------------------------------------
What smlsharp2exe does.

  1, invoke SML# compiler to obtain a bytecode sequence
    from a SML source code.
  2, invoke objcopy command to convert the bytecode sequence
    to a native object file.
  3, invoke a C compiler to link the object file with SML# runtime
    to obtain a native executable file.

 Approximately, smlsharp2exe.sh generates an executable file which would be obtained by compiling following C code.

  void smlsharp_execute(char* bytecode){
    int* PC = (int*)bytecode;
    while(true){
      switch(*PC){
        case LoadInt: ...
        case LoadReal: ...
            :
      }
    }
  }

  int main(){
    char bytecode[] = {0x1, 0xFE, 0xA1, ...}; /* generated from SML code. */
    smlsharp_execute(bytecode);
  }

----------------------------------------
