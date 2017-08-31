/**
 * main.c
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 */

#include "smlsharp.h"

int
main(int argc, char **argv)
{
	sml_init(argc, argv);
	sml_run(0);
	sml_exit(0);
}
