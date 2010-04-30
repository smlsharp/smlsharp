/**
 * file.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: file.h,v 1.2 2008/01/10 04:43:13 katsu Exp $
 */
#ifndef SMLSHARP__FILE_H__
#define SMLSHARP__FILE_H__

#include "cdecl.h"
#include "error.h"

struct file {
	const char *filename;
	status_t (*read)(struct file *file, size_t offset, 
			 size_t size, void *buf);
	void (*close)(struct file *file);
};
typedef struct file file_t;

status_t file_open(const char *filename, file_t **file_ret);
file_t *file_mem_open(const void *data, size_t len, int need_free);

#endif /* SMLSHARP__FILE_H__ */
