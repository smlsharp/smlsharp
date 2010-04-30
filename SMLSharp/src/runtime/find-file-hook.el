(make-local-variable 'make-compile-command)
(setq make-compile-command
      "make BUILD_NAME=test ARCH_NAME=cygwin")

(make-local-variable 'make-test-command)
(setq make-test-command
      "make BUILD_NAME=test ARCH_NAME=cygwin")
