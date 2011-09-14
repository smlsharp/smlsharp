/**
 * exn.c
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 */

#include <stdlib.h>
#include "smlsharp.h"

/* builtin exceptions */

struct sml_exntag {
	const char * const * const name;
};

static const char * const exntags[] = {
	"Bind",
	"Match", 
	"Subscript",
	"Size",
	"Overflow",
	"Div",
	"Domain",
	"Fail",
	"MatchCompBug",
};

const struct sml_exntag SML4Bind = { &exntags[0] };
const struct sml_exntag SML5Match = { &exntags[1] };
const struct sml_exntag SML9Subscript = { &exntags[2] };
const struct sml_exntag SML4Size = { &exntags[3] };
const struct sml_exntag SML8Overflow = { &exntags[4] };
const struct sml_exntag SML3Div = { &exntags[5] };
const struct sml_exntag SML6Domain = { &exntags[6] };
const struct sml_exntag SML4Fail = { &exntags[7] };
const struct sml_exntag SMLN8SMLSharp12MatchCompBugE = { &exntags[8] };
/*
struct sml_exntag SMLN8SMLSharp9SMLFormat9FormatterE = { "Formatter" };
struct sml_exntag SMLN8SMLSharp9BootstrapE = { "Bootstrap" };
*/

/* for debug */
void
sml_matchcomp_bug()
{
	sml_error(0, "match compiler bug");
	abort();
}
