#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/wait.h>

int
sml_test_exec(const char *progname, const char *output, int *ret)
{
	pid_t pid;
	int fd0, fd1, err, stat;

	fd0 = open("/dev/null", O_WRONLY);
	if (fd0 < 0) {
		err = fd0;
		goto error0;
	}
	fd1 = open(output, O_WRONLY);
	if (fd1 < 0) {
		err = fd1;
		goto error1;
	}

	pid = fork();
	if (pid == 0) {
		dup2(fd0, STDIN_FILENO);
		dup2(fd1, STDOUT_FILENO);
		dup2(fd1, STDERR_FILENO);
		execl(progname, progname, (char *)NULL);
		abort();
	}
	if (pid < 0) {
		err = pid;
		goto error;
	}

	err = waitpid(pid, &stat, 0);
	if (err < 0)
		goto error;

	if (WIFEXITED(stat)) {
		ret[0] = 0;
		ret[1] = WEXITSTATUS(stat);
	} else if (WIFSIGNALED(stat)) {
		ret[0] = 1;
		ret[1] = WTERMSIG(stat);
	} else if (WCOREDUMP(stat)) {
		ret[0] = 2;
	} else {
		ret[0] = 3;
		ret[1] = stat;
	}
	err = 0;

error:
	close(fd1);
error1:
	close(fd0);
error0:
	return err;
}
