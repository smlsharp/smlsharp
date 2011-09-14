/**
 * main.c
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 */

#include <stdio.h>
#include "smlsharp.h"

/* entry point of SML# object file. */
void SMLmain(void);

int
main(int argc, char **argv)
{
	sml_init(argc, argv);

#if 0
	__asm__ volatile ("movl $0xaa55aa55, %%eax\n\t"
			  "subl $0x4000, %%esp\n\t"
			  "movl %%esp, %%edi\n\t"
			  "movl $0x4000, %%ecx\n\t"
			  "cld\n\t"
			  "rep\n\t"
			  "stosb\n\t"
			  "addl $0x4000, %%esp\n\t"
			  : : : "edi", "eax", "ecx", "cc", "memory");
#endif

	SMLmain();

	sml_finish();
	return 0;
}
