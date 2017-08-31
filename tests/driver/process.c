#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/wait.h>

int
sml_test_exec(const char *progname, int *ret)
{
	pid_t pid;
	int fd, err, stat;

	fd = open("/dev/null", O_WRONLY);
	if (fd < 0)
		return -1;

	pid = fork();
	if (pid == 0) {
		dup2(fd, STDOUT_FILENO);
		dup2(fd, STDERR_FILENO);
		execl(progname, progname, (char *)NULL);
		abort();
	}
	if (pid < 0)
		return -1;

	err = waitpid(pid, &stat, 0);
	if (err < 0)
		return -1;

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
	return 0;
}
