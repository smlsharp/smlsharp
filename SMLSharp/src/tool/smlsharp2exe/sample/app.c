#include <stdio.h>

#include "interpreter.h"

int doOpen(const char* fileName){
    printf("doOpen(%s)\n", fileName);
    return 1;
}

int main(int argc, const char** argv)
{
    smlsharp_initialize(DEFAULT_HEAP_SIZE,
                        DEFAULT_STACK_SIZE,
                        STANDALONE,
                        argv[0],
                        argc - 1, 
                        argv + 1);
    smlsharp_exportSymbol("doOpen", (void*)doOpen);
    smlsharp_execute_prelude();

    int (*eval)(const char*) =
      (int (*)(const char*))smlsharp_importSymbol("eval");
    if(eval){
        int r = eval("foo");
        printf("result = %d\n", r);
    }

    smlsharp_finalize();

    return 0;
}
