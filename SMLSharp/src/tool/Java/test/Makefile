JAVAC=javac
JAVA2SML=/usr/local/bin/java2sml.sh
SMLSHARP=smlsharp

JAVA_SOURCES= \
	ArrayTestee1.java \
	MemberAccessTestee1.java \
	ObjectBasicsTestee1.java \
	ClassBasicsTestee1.java \
	ClassBasicsTestee1_Child.java \
	ClassBasicsTestee1_NotChild.java \
	ExceptionTestee1.java \
	ExceptionTestee1Exception.java \
	MethodCallTestee1.java \
	MethodCallTestee1_Child.java \
	RenameKeywordTestee1.java \
	abstype/RenameKeywordTestee2.java \


SOURCES = \
	$(JAVA_SOURCES) \


JDK_CLASS_NAMES= \
	java.lang.Object \
	java.lang.String \


TARGETS = \
	$(OBJECTS) \
	$(JAVA_SOURCES:.java=.class) \
	$(JAVA_SOURCES:.java=.sml) \
	JDK.sml \


.SUFFIXES:
.SUFFIXES: .java .class .sml

all: $(TARGETS)

clean:
	-rm -f $(OBJECTS) $(TARGETS)

test:
	$(SMLSHARP) sources.sml

JDK.sml:
	$(JAVA2SML) --namespace JDK -o $@ $(JDK_CLASS_NAMES)

.java.class:
	$(JAVAC) $(JAVA_SOURCES)

# FQN of the Java class is obtained from the path of the Java source file.
# Ex. foo/bar/Baz.java ==> foo.bar.Baz
.java.sml:
	$(JAVA2SML) -o $@ $(subst /,.,$(<:.java=))
