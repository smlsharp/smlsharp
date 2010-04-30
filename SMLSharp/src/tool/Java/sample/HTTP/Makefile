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
	java.lang.Throwable \
	java.lang.Exception \
	java.lang.String \
	java.net.URL \
	java.net.URLConnection \


TARGETS = \
	HTTP.sml \


.SUFFIXES:
.SUFFIXES: .java .class .sml

all: $(TARGETS)

clean:
	-rm -f $(OBJECTS) $(TARGETS)

HTTP.sml:
	$(JAVA2SML) --namespace HTTP -o $@ $(CLASSES)

.java.class:
	$(JAVAC) $(JAVA_SOURCES)

