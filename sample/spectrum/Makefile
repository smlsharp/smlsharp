SMLSHARP = smlsharp
LIBS = -lgsl -Wl,-framework,OpenGL -Wl,-framework,GLUT  # for Mac OS X
#LIBS = -lgsl -L/usr/X11R6/lib -lgl -lglu -lglut

all: spectrum sine

sine: sine.c
	$(CC) $(CFLAGS) -o $@ sine.c -lm

spectrum: load.smi load.o ../glut/libglut.o libm.o libgsl.o spectrum.o \
          libc.o input_plain.o display_glut.o
	$(SMLSHARP) -o $@ load.smi $(LIBS)
clean:
	-rm -f spectrum load.o ../glut/libglut.o libm.o libgsl.o spectrum.o \
	       libc.o input_plain.o display_glut.o
	-rm -f sine

.SUFFIXES: .o .c .sml

.sml.o:
	$(SMLSHARP) -c -o $@ $<

display_curses.o: display_curses.sml libc.smi libcurses.smi input.sig \
  input_plain.smi libm.smi libgsl.smi spectrum.smi display.sig \
  display_curses.smi
display_glut.o: display_glut.sml ../glut/libglut.smi libm.smi libgsl.smi \
  spectrum.smi libc.smi input.sig input_plain.smi display.sig display_glut.smi
display_text.o: display_text.sml libc.smi input.sig input_plain.smi libm.smi \
  libgsl.smi spectrum.smi display.sig display_text.smi
input_plain.o: input_plain.sml libc.smi input.sig input_plain.smi
libc.o: libc.sml libc.smi
libcurses.o: libcurses.sml libcurses.smi
libgsl.o: libgsl.sml libgsl.smi
libm.o: libm.sml libm.smi
load.o: load.sml ../glut/libglut.smi libm.smi libgsl.smi spectrum.smi \
  libc.smi input.sig input_plain.smi display.sig display_glut.smi load.smi
spectrum.o: spectrum.sml libm.smi libgsl.smi spectrum.smi
../glut/libglut.o: ../glut/libglut.sml ../glut/libglut.smi
