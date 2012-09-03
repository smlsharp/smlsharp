/*
 * interact.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: interact.c,v 1.2 2008/01/23 08:20:07 katsu Exp $
 */

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#undef ALIGN
#include <errno.h>
#include "memory.h"
#include "error.h"
#include "value.h"
#include "file.h"
#include "exe.h"
#include "runtime.h"
#include "interact.h"

#define MESSAGE_TYPE_INITIALIZATION_RESULT     0
#define MESSAGE_TYPE_EXIT_REQUEST              1
#define MESSAGE_TYPE_EXECUTION_REQUEST         2
#define MESSAGE_TYPE_EXECUTION_RESULT          3
#define MESSAGE_TYPE_OUTPUT_REQUEST            4
#define MESSAGE_TYPE_OUTPUT_RESULT             5
#define MESSAGE_TYPE_INPUT_REQUEST             6
#define MESSAGE_TYPE_INPUT_RESULT              7
#define MESSAGE_TYPE_CHANGE_DIRECTORY_REQUEST  8

#define MAJOR_CODE_SUCCESS    0
#define MAJOR_CODE_FAILURE    1
#define MAJOR_CODE_FATAL      2

struct message {
	int msg;
	union {
		struct {
			int major, minor;
		} result;
		int status;
		struct {
			void *data;
			size_t len;
		} array;
		file_t *file;
	} body;
};

static FILE *session_input;
static FILE *session_output;
int interactive_mode;

/*
 * Protocol:
 *
 * (1) invoke backend process by frontend.
 *
 * (2) send InitializationResult from backend to frontend.
 *
 * (3) send requests between frontend and backend.
 *
 *   InitializationResult (frontend <- backend)
 *     Backend is now ready. No corresponding request.
 *
 *       int8    msg = 0;
 *       int8    major_code;
 *       int8    minor_code;  (exist if major_code != SUCCESS)
 *
 *   ExitRequest (frontend <-> backend)
 *     Exit interactive session. Both frontend and backend begin to
 *     shutdown immediately after sending or receiving this request.
 *     No corresponding result.
 *
 *       int8    msg = 1;
 *       int32   exit_code;
 *
 *   ExecutionRequest (frontend -> backend)
 *     Execute code. Other requests may be sent by backend before
 *     ExecutionResult is sent.
 *
 *       int8    msg = 2;
 *       uint32  length > 0;
 *       int8    code[length];
 *       uint32  length > 0;
 *       int8    code[length];
 *       ...
 *       uint32  length = 0;
 *
 *   ExecutionResult (frontend <- backend)
 *     The execution is finished and return to user prompt.
 *
 *       int8    msg = 3;
 *       int8    major_code;
 *       int8    minor_code;  (exist if major_code != SUCCESS)
 *
 *   OutputRequest (frontend <- backend)
 *     Write data to specified file descriptor.
 *
 *       int8    msg = 4;
 *       uint32  fd;      (1 = stdout, 2 = stderr. any other are never here.)
 *       uint32  length;
 *       int8    data[length];
 *
 *   OutputResult (frontend -> backend)
 *     Writing is finished and continue the execution.
 *
 *       int8    msg = 5;
 *       int8    major_code;
 *       int8    minor_code;  (exist if major_code != SUCCESS)
 *
 *   InputRequest (frontend <- backend)
 *     Read data from terminal.
 *
 *       int8    msg = 6;
 *       uint32  length;
 *
 *   IntputResult (frontend -> backend)
 *     Reading is finished and continue the execution.
 *
 *       int8    msg = 7;
 *       int8    major_code;
 *       int8    minor_code;    (exist if major_code != SUCCESS)
 *       uint32  length;        (exist if major_code == SUCCESS)
 *       int8    data[length];  (exist if major_code == SUCCESS)
 *
 *   ChangeDirectoryRequest (frontend <- backend)
 *     Change current directory. No corresponding result.
 *
 *       int8    msg = 8;
 *       uint32  length;
 *       int8    dirname[length];
 */

static status_t
recv_data(void *dst, size_t len)
{
	size_t n;

	DBG(("receiving %u bytes", (unsigned int)len));

	n = fread(dst, 1, len, session_input);
	if (n < len)
		return ferror(session_input) ? errno : ERR_TRUNCATED;

	DBG(("received %u bytes", (unsigned int)len));

	return 0;
}

static status_t
send_data(const void *src, size_t len)
{
	size_t n;

	DBG(("writing %u bytes", (unsigned int)len));

	n = fwrite(src, 1, len, session_output);
	if (n < len)
		return ferror(session_output) ? errno : ERR_TRUNCATED;
	fflush(session_output);

	DBG(("wrote %u bytes", (unsigned int)len));
	return 0;
}

static status_t
recv_byte(int *value_ret)
{
	unsigned char c;
	status_t err;
	err = recv_data(&c, sizeof(c));
	if (err)
		return err;
	*value_ret = c;
	return 0;
}

static status_t
send_byte(int value)
{
	unsigned char c = value;
	return send_data(&c, sizeof(c));
}

static status_t
recv_word(uint32_t *value_ret)
{
	uint32_t value;
	status_t err;

	err = recv_data(&value, sizeof(value));
	if (err)
		return err;
	*value_ret = ntohl(value);
	return 0;
}

static status_t
send_word(uint32_t value)
{
	value = htonl(value);
	return send_data(&value, sizeof(uint32_t));
}

static status_t
recv_result(int *major_ret, int *minor_ret)
{
	status_t err;

	err = recv_byte(major_ret);
	if (err)
		return err;
	if (*major_ret == MAJOR_CODE_SUCCESS) {
		*minor_ret = 0;
		return 0;
	}
	return recv_byte(minor_ret);
}

static status_t
send_result(int major, int minor)
{
	status_t err;

	err = send_byte(major);
	if (err)
		return err;
	if (major == MAJOR_CODE_SUCCESS)
		return 0;
	return send_byte(minor);
}

static status_t
recv_array(void **data_ret, size_t *len_ret)
{
	uint32_t len;
	void *p;
	status_t err;

	err = recv_word(&len);
	if (err)
		return err;

	DBG(("length = %u", (unsigned int)len));

	p = xmalloc(len);
	err = recv_data(p, len);
	if (err)
		return err;

	*len_ret = len;
	*data_ret = p;
	return 0;
}

static status_t
send_array(const void *data, size_t len)
{
	status_t err;
	err = send_word(len);
	if (err)
		return err;
	return send_data(data, len);
}

static status_t
send_initialization_result(int major, int minor)
{
	status_t err;

	DBG(("send INITIALIZATION_RESULT"));
	err = send_byte(MESSAGE_TYPE_INITIALIZATION_RESULT);
	if (err)
		return err;
	return send_result(major, minor);
}

static status_t
send_exit_request(int status)
{
	status_t err;

	DBG(("send EXIT_REQUEST"));
	err = send_byte(MESSAGE_TYPE_EXIT_REQUEST);
	if (err)
		return err;
	return send_word((unsigned int)status);
}

static status_t
recv_exit_request(int *status_ret)
{
	uint32_t word;
	status_t err;

	err = recv_word(&word);
	if (err)
		return err;
	*status_ret = word;
	return 0;
}

static status_t
recv_execution_request(file_t **file_ret)
{
	size_t len, datalen;
	void *p, *data;
	status_t err;

	datalen = 0;
	data = NULL;

	for (;;) {
		err = recv_array(&p, &len);
		if (err)
			return err;

		if (len == 0) {
			free(p);
			break;
		}
		data = xrealloc(data, datalen + len);
		memcpy(data + datalen, p, len);
		datalen += len;
		free(p);
	}

	*file_ret = file_mem_open(data, datalen, 1);
	return 0;
}

static status_t
send_execution_result(int major, int minor)
{
	status_t err;

	DBG(("send EXECUTION_RESULT"));
	err = send_byte(MESSAGE_TYPE_EXECUTION_RESULT);
	if (err)
		return err;
	return send_result(major, minor);
}

static status_t
send_output_request(int fd, const void *data, size_t len)
{
	status_t err;

	ASSERT(fd == 1 || fd == 2);
	DBG(("send OUTPUT_REQUEST"));

	err = send_byte(MESSAGE_TYPE_OUTPUT_REQUEST);
	if (err)
		return err;
	err = send_word(fd);
	if (err)
		return err;
	return send_array(data, len);
}

static status_t
recv_output_result(int *major_ret, int *minor_ret)
{
	return recv_result(major_ret, minor_ret);
}

static status_t
send_input_request(size_t len)
{
	status_t err;

	DBG(("send INPUT_REQUEST"));
	err = send_byte(MESSAGE_TYPE_INPUT_REQUEST);
	if (err)
		return err;
	return send_word(len);
}

static status_t
recv_input_result(void **data_ret, size_t *len_ret)
{
	int major, minor;
	status_t err;

	err = recv_result(&major, &minor);
	if (err)
		return err;
	if (major != MAJOR_CODE_SUCCESS)
		return ERR_FAILED;

	return recv_array(data_ret, len_ret);
}

static status_t
send_change_directory_request(const char *dirname)
{
	status_t err;

	DBG(("send CHANGE_DIRECTORY_REQUEST"));
	err = send_byte(MESSAGE_TYPE_CHANGE_DIRECTORY_REQUEST);
	if (err)
		return err;
	return send_array(dirname, strlen(dirname));
}

static status_t
recv_msg(struct message *msg)
{
	status_t err;

	err = recv_byte(&msg->msg);
	if (err)
		return err;

	switch (msg->msg) {
	case MESSAGE_TYPE_EXIT_REQUEST:
		DBG(("receive EXIT_REQUEST"));
		return recv_exit_request(&msg->body.status);
	case MESSAGE_TYPE_EXECUTION_REQUEST:
		DBG(("receive EXECUTION_REQUEST"));
		return recv_execution_request(&msg->body.file);
	case MESSAGE_TYPE_OUTPUT_RESULT:
		DBG(("receive OUTPUT_RESULT"));
		return recv_output_result(&msg->body.result.major,
					  &msg->body.result.minor);
	case MESSAGE_TYPE_INPUT_RESULT:
		DBG(("receive INPUT_RESULT"));
		return recv_input_result(&msg->body.array.data,
					 &msg->body.array.len);
	default:
		fatal(0, "invalid message : %u", (unsigned int)msg->msg);
	}

	return err;
}

static status_t
interact_input(void **data_ret, size_t *len)
{
	struct message msg;
	status_t err;

	err = send_input_request(*len);
	if (err)
		return err;

	err = recv_msg(&msg);
	if (err)
		return err;
	if (msg.msg != MESSAGE_TYPE_INPUT_RESULT)
		fatal(0, "INPUT_RESULT expected");

	*data_ret = msg.body.array.data;
	*len = msg.body.array.len;
	return 0;
}

static status_t
interact_output(int fd, const void *data, size_t len)
{
	struct message msg;
	status_t err;

	err = send_output_request(fd, data, len);
	if (err)
		return err;

	err = recv_msg(&msg);
	if (err)
		return err;
	if (msg.msg != MESSAGE_TYPE_OUTPUT_RESULT)
		fatal(0, "OUTPUT_RESULT expected");

	if (msg.body.result.major == MAJOR_CODE_SUCCESS)
		return 0;
	else
		return ERR_FAILED;
}

static status_t
interact_chdir(const char *dirname)
{
	status_t err;

	err = send_change_directory_request(dirname);
	if (err)
		return err;

	if (chdir(dirname) != 0)
		return errno;

	return 0;
}

static void
interact_exit(int status)
{
	status_t err;

	err = send_exit_request(status);
	if (err)
		fatal(err, "send EXIT_REQUEST failed");

	/* FIXME: finalization is needed? */
	exit(status);
}

/*
 * prim ya_GenericOS_read : (int, byteArray, word, word) -> int : has_effect
 */
ml_int_t
interact_prim_read(ml_int_t fd, void *buf, ml_uint_t offset, ml_uint_t len)
{
	void *data;
	size_t size;
	status_t err;

	ASSERT(OBJ_TYPE(buf) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(offset + len <= OBJ_SIZE(buf));

	size = len;
	err = interact_input(&data, &size);
	if (err) {
		errno = EIO;
		return -1;
	}
	memcpy(buf + offset, data, size);
	free(data);
	return size;
}

/*
 * prim ya_GenericOS_write : (int, byteArray, word, word) -> int : has_effect
 */
ml_int_t
interact_prim_write(ml_int_t fd, void *buf, ml_uint_t offset, ml_uint_t len)
{
	ASSERT(OBJ_TYPE(buf) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(buf) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(offset + len <= OBJ_SIZE(buf));

	interact_output(fd, buf + offset, len);
	return len;
}

/*
 * prim print : string -> () : has_effect
 */
ml_int_t
interact_prim_print(void *arg)
{
	ASSERT(OBJ_TYPE(arg) == OBJTYPE_UNBOXED_VECTOR);
	interact_output(1, arg, string_size(arg));
	return 0;
}

/*
 * prim printerr : string -> () : has_effect
 */
/* for debug */
ml_int_t
interact_prim_printerr(void *arg)
{
	ASSERT(OBJ_TYPE(arg) == OBJTYPE_UNBOXED_VECTOR);
	interact_output(2, arg, string_size(arg));
	return 0;
}

/*
 * prim ya_GenericOS_chdir : string -> int : has_effect
 */
ml_int_t
interact_prim_chdir(void *dirname)
{
	status_t err;
	ASSERT(OBJ_TYPE(dirname) == OBJTYPE_UNBOXED_VECTOR);
	err = interact_chdir(dirname);
	if (err) {
		errno = err;
		return -1;
	}
	chdir(dirname);
	return 0;
}

/*
 * prim GenericOS_exit : int -> () : has_effect
 */
ml_int_t
interact_prim_exit(ml_int_t status)
{
	interact_exit(status);
	return 0;
}

status_t
interact_start(runtime_t *rt, FILE *in, FILE *out, int *status_ret)
{
	struct message msg;
	status_t err;
	executable_t *exe;

	session_input = in;
	session_output = out;
	interactive_mode = 1;

	send_initialization_result(MAJOR_CODE_SUCCESS, 0);

	DBG(("start interactive session"));

	for (;;) {
		err = recv_msg(&msg);
		if (err)
			return err;

		if (msg.msg == MESSAGE_TYPE_EXIT_REQUEST) {
			*status_ret = msg.body.status;
			break;
		}
		else if (msg.msg == MESSAGE_TYPE_EXECUTION_REQUEST) {
			err = runtime_load(rt, msg.body.file, &exe);
			if (err)
				fatal(err, "could not load executable");

			err = runtime_exec(rt, exe);
			if (err)
				fatal(err, "execution failed");

			err = send_execution_result(MAJOR_CODE_SUCCESS, 0);
			if (err)
				fatal(err, "send EXECUTION_RESULT failed");

			DBG(("interact: execution finished."));
		}
		else {
			fatal(0, "unexpected message : %u",
			      (unsigned int)msg.msg);
		}
	}

	return 0;
}
