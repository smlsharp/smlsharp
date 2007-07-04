/*
 * callback.c
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: callback.c,v 1.2 2007/04/02 09:42:29 katsu Exp $
 */

#include <stdio.h>

void f4(void)
{
	printf("f4\n");
}

void f3(void(*f)(void(*)(void)))
{
	printf("f3\n");
	f(f4);
}

void f2(void(*f)(void(*)(void(*)(void(*)(void)))))
{
	printf("f2\n");
	f(f3);
}

void f1(void(*f)(void(*)(void(*)(void(*)(void(*)(void(*)(void)))))))
{
	printf("f1\n");
	f(f2);
}

void g4(void)
{
	printf("g4\n");
}

void (*g3(void))(void)
{
	printf("g3\n");
	return g4;
}

void (*(*g2(void))(void))(void)
{
	printf("g2\n");
	return g3;
}

void (*(*(*g1(void))(void))(void))(void)
{
	printf("g1\n");
	return g2;
}
