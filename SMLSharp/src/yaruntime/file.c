/**
 * file.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: file.c,v 1.2 2008/01/10 04:43:13 katsu Exp $
 */

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include "error.h"
#include "memory.h"
#include "file.h"

struct file_file {
	struct file base;  /* must be first member */
	FILE *file;
};

static status_t
file_read(file_t *file, size_t offset, size_t size, void *buf)
{
	FILE *f = ((struct file_file *)file)->file;
	int err;
	size_t n;

	err = fseek(f, offset, SEEK_SET);
	if (err)
		return errno;

	n = fread(buf, size, 1, f);
	if (n > 0)
		return 0;

	return feof(f) ? ERR_TRUNCATED : errno;
}

static void
file_close(struct file *file)
{
	FILE *f = ((struct file_file *)file)->file;
	free(file);
	fclose(f);
}

status_t
file_open(const char *filename, file_t **file_ret)
{
	struct file_file *file;
	FILE *f;

	file = xmalloc(sizeof(struct file_file));

	f = fopen(filename, "rb");
	if (f == NULL) {
		free(file);
		return errno;
	}

	file->base.filename = filename;
	file->base.read = file_read;
	file->base.close = file_close;
	file->file = f;

	*file_ret = (file_t*)file;
	return 0;
}

struct file_mem {
	struct file base;  /* must be first member */
	void *data;
	size_t len;
	int need_free;
};

static status_t
file_mem_read(file_t *file, size_t offset, size_t size, void *buf)
{
	struct file_mem *m = (struct file_mem *)file;

	if (offset > m->len || size > m->len - offset)
		return ERR_TRUNCATED;

	memcpy(buf, (char*)m->data + offset, size);
	return 0;
}

static void
file_mem_close(file_t *file)
{
	struct file_mem *m = (struct file_mem *)file;

	if (m->need_free)
		free(m->data);
	free(file);
}

file_t *
file_mem_open(const void *data, size_t len, int need_free)
{
	struct file_mem *file;

	file = xmalloc(sizeof(struct file_mem));
	file->base.filename = "(mem)";
	file->base.read = file_mem_read;
	file->base.close = file_mem_close;
	file->data = (void*)data;
	file->len = len;
	file->need_free = need_free;

	return (struct file *)file;
}
