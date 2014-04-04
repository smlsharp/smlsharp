/**
 * main.c
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 */

#include <stdio.h>
#include "smlsharp.h"

/* entry point of SML# toplevel */
void _SMLmain(void);

int
main(int argc, char **argv)
{
	sml_init(argc, argv);
	_SMLmain();
	sml_finish();
	return 0;
}
