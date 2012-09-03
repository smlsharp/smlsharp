/**
 * toplevel.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: toplevel.h,v 1.1 2007/12/17 12:11:16 katsu Exp $
 */
#ifndef SMLSHARP__TOPLEVEL_H__
#define SMLSHARP__TOPLEVEL_H__

#include <stdio.h>
#include <setjmp.h>

enum msg_type {
	MSG_ERROR,
	MSG_WARN,
	MSG_NOTICE,
	MSG_DEBUG
};

extern const char *program_name;

extern unsigned int error_count;
extern unsigned int verbose_level;
extern FILE *error_out;
extern void (*msg_start)(enum msg_type msg_type);
extern void (*msg_end)(enum msg_type msg_type);
extern jmp_buf abort_jmpbuf;

#endif /* SMLSHARP__TOPLEVEL_H__ */
