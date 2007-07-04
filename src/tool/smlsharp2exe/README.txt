smlsharp2exe

 smlsharp2exe is a tool that compiles a SML source code to a 'native' executable file which does not require smlsharprun.exe to run.

@author YAMATODANI Kiyoshi
@version $Id: README.txt,v 1.1 2007/03/26 00:12:57 kiyoshiy Exp $

----------
Usage

  smlsharp2exe.sh [options] FILE

  options:
         -o FILE | --output=FILE     output file name
         other                       options for smlsharp are available.

----------
Example.

  $ echo 'app print (CommandLine.arguments());' > foo.sml
  $ smlsharp2exe.sh -o foo.exe ./foo.sml
  generated foo.exe.
  $ ./foo.exe hoge bar
  hogebar

----------
What smlsharp2exe does.

  1, invoke SML# compiler to obtain a bytecode sequence
    from a SML source code.
  2, invoke objdump command to convert the bytecode sequence
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
    char bytecode[] = {0x1, 0xFE, 0xA1, ...};
    smlsharp_execute(bytecode);
  }

----------
