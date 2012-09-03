JAVAC=javac
JAVA2SML=/usr/local/bin/java2sml.sh

JAVA_SOURCES= \
	HTTPGet.java \


SOURCES = \
	$(JAVA_SOURCES) \


OBJECTS = \
	$(JAVA_SOURCES:.java=.class) \


CLASSES= \
	java.io.BufferedReader \
	java.io.InputStream \
	java.io.InputStreamReader \
	java.io.IOException \
	java.io.PrintStream \
	java.lang.Throwable \
	java.lang.Exception \
	java.lang.String \
	java.lang.System \
	java.net.URL \
	java.net.URLConnection \


TARGETS = \
	JavaCorePackages.sml \
	$(OBJECTS) \


.SUFFIXES:
.SUFFIXES: .java .class .sml

all: $(TARGETS)

clean:
	-rm -f $(OBJECTS) $(TARGETS)

JavaCorePackages.sml:
	$(JAVA2SML) --namespace $(@:.sml=) -o $@ $(CLASSES)

.java.class:
	$(JAVAC) $<
