JAVAC=javac
JAVA2SML=/usr/local/bin/java2sml.sh

JAVA_SOURCES= \
	CSVJDBCTest.java \


SOURCES = \
	$(JAVA_SOURCES) \


OBJECTS = \
	$(JAVA_SOURCES:.java=.class) \


CLASSES= \
	java.sql.Array \
	java.sql.Blob \
	java.sql.CallableStatement \
	java.sql.Clob \
	java.sql.Connection \
	java.sql.DatabaseMetaData \
	java.sql.Driver \
	java.sql.ParameterMetaData \
	java.sql.PreparedStatement \
	java.sql.Ref \
	java.sql.ResultSet \
	java.sql.ResultSetMetaData \
	java.sql.Savepoint \
	java.sql.SQLData \
	java.sql.SQLInput \
	java.sql.SQLOutput \
	java.sql.Statement \
	java.sql.Struct \
	java.sql.Date \
	java.sql.DriverManager \
	java.sql.DriverPropertyInfo \
	java.sql.SQLPermission \
	java.sql.Time \
	java.sql.Timestamp \
	java.sql.Types \
	java.sql.BatchUpdateException \
	java.sql.DataTruncation \
	java.sql.SQLException \
	java.sql.SQLWarning \
	java.sql.Connection \
	java.sql.ResultSet \
	java.sql.Statement \
	java.sql.DriverManager \
	java.io.BufferedReader \
	java.io.InputStream \
	java.io.InputStreamReader \
	java.io.IOException \
	java.lang.Class \
	java.lang.ClassLoader \
	java.lang.Exception \
	java.lang.String \
	java.lang.Throwable \
	java.net.URL \
	java.net.URLConnection \


TARGETS = \
	JDBC.sml \


.SUFFIXES:
.SUFFIXES: .java .class .sml

all: $(TARGETS)

clean:
	-rm -f $(OBJECTS) $(TARGETS)

JDBC.sml:
	$(JAVA2SML) --namespace JDBC -o $@ $(CLASSES)

.java.class:
	$(JAVAC) $(JAVA_SOURCES)

