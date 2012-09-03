/*
 * arith.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: arith.c,v 1.4 2008/01/23 08:20:07 katsu Exp $
 */

#include <stdlib.h>
#include <math.h>
#include "error.h"
#include "eval.h"

ml_int_t
abs_N(ml_int_t x)
{
	return abs(x);
}

ml_long_t
abs_NL(ml_long_t x)
{
	return llabs(x); /* FIXME: C99 */
}

float
abs_FS(float x)
{
	return fabsf(x); /* FIXME: C99 */
}

double
abs_F(double x)
{
	return fabs(x);
}

long double
abs_FL(long double x)
{
	return fabsl(x); /* FIXME: C99 */
}

ml_int_t
abso_N(ml_int_t x ATTR_UNUSED)
{
	FATAL((0, "not implemented"));
}

ml_long_t
abso_NL(ml_long_t x ATTR_UNUSED)
{
	FATAL((0, "not implemented"));
}

ml_int_t
addo_N(ml_int_t x ATTR_UNUSED, ml_int_t y ATTR_UNUSED)
{
	FATAL((0, "not implemented"));
}

ml_long_t
addo_NL(ml_long_t x ATTR_UNUSED, ml_long_t y ATTR_UNUSED)
{
	FATAL((0, "not implemented"));
}

ml_int_t
subo_N(ml_int_t x ATTR_UNUSED, ml_int_t y ATTR_UNUSED)
{
	FATAL((0, "not implemented"));
}

ml_long_t
subo_NL(ml_long_t x ATTR_UNUSED, ml_long_t y ATTR_UNUSED)
{
	FATAL((0, "not implemented"));
}

ml_int_t
mulo_N(ml_int_t x ATTR_UNUSED, ml_int_t y ATTR_UNUSED)
{
	FATAL((0, "not implemented"));
}

ml_long_t
mulo_NL(ml_long_t x ATTR_UNUSED, ml_long_t y ATTR_UNUSED)
{
	FATAL((0, "not implemented"));
}

div_t_N
divmod_N(ml_int_t x ATTR_UNUSED, ml_int_t y ATTR_UNUSED)
{
	div_t_N div;

	div.quot = x / y;
	div.rem = x % y;

	if ((y < 0 && div.rem > 0) || (y > 0 && div.rem < 0))
		div.quot -= 1, div.rem += y;

	return div;
}

div_t_N
divmodo_N(ml_int_t x ATTR_UNUSED, ml_int_t y ATTR_UNUSED)
{
	FATAL((0, "not implemented"));
}

div_t_NL
divmod_NL(ml_long_t x ATTR_UNUSED, ml_long_t y ATTR_UNUSED)
{
	div_t_NL div;

	div.quot = x / y;
	div.rem = x % y;

	if ((y < 0 && div.rem > 0) || (y > 0 && div.rem < 0))
		div.quot -= 1, div.rem += y;

	return div;
}

div_t_NL
divmodo_NL(ml_long_t x ATTR_UNUSED, ml_long_t y ATTR_UNUSED)
{
	FATAL((0, "not implemented"));
}

div_t_N
quotrem_N(ml_int_t x ATTR_UNUSED, ml_int_t y ATTR_UNUSED)
{
	div_t_N div;

	div.quot = x / y;
	div.rem = x % y;

	if ((y > 0 && div.rem > 0) || (y < 0 && div.rem < 0))
		div.quot += 1, div.rem -= y;

	return div;
}

div_t_N
quotremo_N(ml_int_t x ATTR_UNUSED, ml_int_t y ATTR_UNUSED)
{
	FATAL((0, "not implemented"));
}

div_t_NL
quotrem_NL(ml_long_t x ATTR_UNUSED, ml_long_t y ATTR_UNUSED)
{
	div_t_NL div;

	div.quot = x / y;
	div.rem = x % y;

	if ((y > 0 && div.rem > 0) || (y < 0 && div.rem < 0))
		div.quot += 1, div.rem -= y;

	return div;
}

div_t_NL
quotremo_NL(ml_long_t x ATTR_UNUSED, ml_long_t y ATTR_UNUSED)
{
	FATAL((0, "not implemented"));
}

ml_int_t
rashift_N(ml_int_t x ATTR_UNUSED, unsigned int y ATTR_UNUSED)
{
	unsigned int i;
	ml_int_t r;

	for (i = 0; i < y; i++) {
		r = x % 2;
		x = x / 2;
		if (r < 0)
			x--;
	}
	return x;
}

ml_long_t
rashift_NL(ml_long_t x ATTR_UNUSED, unsigned int y ATTR_UNUSED)
{
	unsigned int i;
	ml_long_t r;

	for (i = 0; i < y; i++) {
		r = x % 2;
		x = x / 2;
		if (r < 0)
			x--;
	}
	return x;
}

ml_uint_t
rashift_W(ml_uint_t x ATTR_UNUSED, unsigned int y ATTR_UNUSED)
{
	const ml_uint_t msb = ~(~(ml_uint_t)0 >> 1);
	unsigned int i;

	for (i = 0; i < y; i++)
		x = (x & msb) | (x >> 1);
	return x;
}

ml_ulong_t
rashift_L(ml_ulong_t x ATTR_UNUSED, unsigned int y ATTR_UNUSED)
{
	const ml_ulong_t msb = ~(~(ml_ulong_t)0 >> 1);
	unsigned int i;

	for (i = 0; i < y; i++)
		x = (x & msb) | (x >> 1);
	return x;
}
