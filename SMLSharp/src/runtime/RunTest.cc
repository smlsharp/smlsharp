#include "@@CLASS@@.hh"
#include "SystemDef.hh"
#include "FileLogFacade.hh"

#include "TestRunner.h"
#include <stdio.h>

int
main(int argc, char* argv[])
{
    if(argc < 3){
        fprintf(stderr, "USAGE:%s <LogFileName> <TestName> ....\n",
                argv[0]);
        return 1;
    }

    TestRunner runner = TestRunner();
    runner.addTest("TEST",
                   new @@NAMESPACE@@::@@CLASS@@::Suite());

    {
        FILE* log = fopen(argv[1], "w");
        if(NULL == log){
            perror(argv[0]);
            return 1;
        }
        jp_ac_jaist_iml::FileLogFacade::setup(log);
    }

    runner.run(argc -1, argv + 1);

    return 0;
}
