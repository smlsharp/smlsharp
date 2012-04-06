SMLSHARP = smlsharp
LIBS = -Wl,-framework,OpenGL -Wl,-framework,GLUT  # for Mac OS X
#LIBS = -L/usr/X11R6/lib -lgl -lglu -lglut

cube: cube.smi cube.o libglut.o
	$(SMLSHARP) -o $@ cube.smi $(LIBS)
cube.o: cube.sml cube.smi libglut.smi
	$(SMLSHARP) -c -o $@ cube.sml
libglut.o: libglut.sml libglut.smi
	$(SMLSHARP) -c -o $@ libglut.sml

clean:
	-rm -f cube cube.o libglut.o
