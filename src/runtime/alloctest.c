#include <stdint.h>
#include "src/runtime/smlsharp.h"
#include "src/runtime/frame.h"
#include "src/runtime/timer.h"

void
SMLmain ()
{
        int ret;
        void *dummy_frame[3];
	int i;
	sml_timer_t b1,b2;
	sml_time_t t;
	volatile int n;

        FRAME_HEADER(&dummy_frame[1]) = 0;
        sml_control_start(&dummy_frame[1]);

	sml_timer_now(b1);
	for (i = 0; i < 0x10000000; i++) {
		void *p = sml_alloc(12, &dummy_frame[1]);
		*(volatile int*)p = 1;
		//n = *(int*)p;
	}
	sml_timer_now(b2);
	sml_timer_dif(b1,b2,t);
	printf(TIMEFMT" sec\n", TIMEARG(t));

        sml_control_finish(&dummy_frame[1]);

        return ret;
}
