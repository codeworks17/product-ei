#!/bin/bash
# ---------------------------------------------------------------------------
#  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# ----------------------------------------------------------------------------
# Startup Script for Integrator
#
# Environment Variable Prerequisites
#
#   JAVA_HOME           Must point at your Java Development Kit installation.
#
#   JAVA_OPTS           (Optional) Java runtime options used when the commands
#                       is executed.
#
# NOTE: Borrowed generously from Apache Tomcat startup scripts.
# -----------------------------------------------------------------------------

# OS specific support.  $var _must_ be set to either true or false.
#ulimit -n 100000
BASE_DIR=$PWD
cygwin=false;
darwin=false;
os400=false;
mingw=false;
case "`uname`" in
CYGWIN*) cygwin=true;;
MINGW*) mingw=true;;
OS400*) os400=true;;
Darwin*) darwin=true
        if [ -z "$JAVA_HOME" ] ; then
		   if [ -z "$JAVA_VERSION" ] ; then
			 JAVA_HOME=$(/usr/libexec/java_home)
           else
             echo "Using Java version: $JAVA_VERSION"
			 JAVA_HOME=$(/usr/libexec/java_home -v $JAVA_VERSION)
		   fi
	    fi
        ;;
esac

# resolve links - $0 may be a softlink
PRG="$0"

while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '.*/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done

# Get standard environment variables
PRGDIR=`dirname "$PRG"`


echo "$PRGDIR"

# set BALLERINA_HOME
BALLERINA_HOME=`cd "$PRGDIR/../wso2/ballerina" ; pwd`

echo "$BALLERINA_HOME"

# For Cygwin, ensure paths are in UNIX format before anything is touched
if $cygwin; then
  [ -n "$JAVA_HOME" ] && JAVA_HOME=`cygpath --unix "$JAVA_HOME"`
  [ -n "$BALLERINA_HOME" ] && BALLERINA_HOME=`cygpath --unix "$BALLERINA_HOME"`
fi

# For OS400
if $os400; then
  # Set job priority to standard for interactive (interactive - 6) by using
  # the interactive priority - 6, the helper threads that respond to requests
  # will be running at the same priority as interactive jobs.
  COMMAND='chgjob job('$JOBNAME') runpty(6)'
  system $COMMAND

  # Enable multi threading
  QIBM_MULTI_THREADED=Y
  export QIBM_MULTI_THREADED
fi

# For Migwn, ensure paths are in UNIX format before anything is touched
if $mingw ; then
  [ -n "$BALLERINA_HOME" ] &&
    BALLERINA_HOME="`(cd "$BALLERINA_HOME"; pwd)`"
  [ -n "$JAVA_HOME" ] &&
    JAVA_HOME="`(cd "$JAVA_HOME"; pwd)`"
fi

if [ -z "$JAVACMD" ] ; then
  if [ -n "$JAVA_HOME"  ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
      # IBM's JDK on AIX uses strange locations for the executables
      JAVACMD="$JAVA_HOME/jre/sh/java"
    else
      JAVACMD="$JAVA_HOME/bin/java"
    fi
  else
    JAVACMD=java
  fi
fi

if [ ! -x "$JAVACMD" ] ; then
  echo "Error: JAVA_HOME is not defined correctly."
  exit 1
fi

# if JAVA_HOME is not set we're not happy
if [ -z "$JAVA_HOME" ]; then
  echo "You must set the JAVA_HOME variable before running Ballerina."
  exit 1
fi

# ----- Process the input command ----------------------------------------------

for c in "$@"
do
    if [ "$c" = "--debug" ] || [ "$c" = "-debug" ] || [ "$c" = "debug" ]; then
          CMD="--debug"
    elif [ "$CMD" = "--debug" ] && [ -z "$PORT" ]; then
          PORT=$c
    elif [ "$c" = "--build" ] || [ "$c" = "-build" ] || [ "$c" = "build" ]; then
         CMD="--build"
    elif [ "$CMD" = "--build" ] && [ -z "$LOCATION" ]; then
          LOCATION=$c
    else
          LOCATION=$c
    fi
done

if [ -z "$LOCATION" ]; then
    echo "Please specify the directory which contains program files or the location of compiled ballerina program"
    exit 1
fi

if [ "$CMD" = "--debug" ]; then
  if [ "$PORT" = "" ]; then
    echo "Please specify the debug port after the --debug option"
    exit 1
  fi
  if [ -n "$JAVA_OPTS" ]; then
    echo "Warning !!!. User specified JAVA_OPTS will be ignored, once you give the --debug option."
  fi
  JAVA_OPTS="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=$PORT"
  echo "Please start the remote debugging client to continue..."
  COMMANDLINE = "$LOCATION"
elif [ "$CMD" = "--build" ]; then
  # TODO: Modify after feature it is available in ballerina
  echo "Building the source is currently not available, will be available when it is available in ballerina distribution"
  exit 1
  if [ "$LOCATION" = "" ]; then
    echo "Please specify the directory which contains source program files after --build option"
    exit 1
  fi
  COMMANDLINE = "build $LOCATION"
  echo "Building source files located at $LOCATION"
else
  COMMANDLINE="run $LOCATION"
fi

BALLERINA_XBOOTCLASSPATH=""
for f in "$BALLERINA_HOME"/bre/lib/bootstrap/xboot/*.jar
do
    if [ "$f" != "$BALLERINA_HOME/bre/lib/bootstrap/xboot/*.jar" ];then
        BALLERINA_XBOOTCLASSPATH="$BALLERINA_XBOOTCLASSPATH":$f
    fi
done

JAVA_ENDORSED_DIRS="$BALLERINA_HOME/bin/bootstrap/endorsed":"$JAVA_HOME/jre/lib/endorsed":"$JAVA_HOME/lib/endorsed"

BALLERINA_CLASSPATH=""
if [ -e "$BALLERINA_HOME/bre/lib/bootstrap/tools.jar" ]; then
    BALLERINA_CLASSPATH="$JAVA_HOME/lib/tools.jar"
fi

for f in "$BALLERINA_HOME"/bre/lib/bootstrap/*.jar
do
    if [ "$f" != "$BALLERINA_HOME/bre/lib/bootstrap/*.jar" ];then
        BALLERINA_CLASSPATH="$BALLERINA_CLASSPATH":$f
    fi
done

for j in "$BALLERINA_HOME"/bre/lib/*.jar
do
    BALLERINA_CLASSPATH="$BALLERINA_CLASSPATH":$j
done

# For Cygwin, switch paths to Windows format before running java
if $cygwin; then
  JAVA_HOME=`cygpath --absolute --windows "$JAVA_HOME"`
  BALLERINA_HOME=`cygpath --absolute --windows "$BALLERINA_HOME"`
  CLASSPATH=`cygpath --path --windows "$CLASSPATH"`
  JAVA_ENDORSED_DIRS=`cygpath --path --windows "$JAVA_ENDORSED_DIRS"`
  BALLERINA_CLASSPATH=`cygpath --path --windows "$BALLERINA_CLASSPATH"`
  BALLERINA_XBOOTCLASSPATH=`cygpath --path --windows "$BALLERINA_XBOOTCLASSPATH"`
fi

# ----- Execute The Requested Command -----------------------------------------
$JAVACMD \
	-Xbootclasspath/a:"$BALLERINA_XBOOTCLASSPATH" \
	-Xms256m -Xmx1024m \
	-XX:+HeapDumpOnOutOfMemoryError \
	-XX:HeapDumpPath="$BALLERINA_HOME/heap-dump.hprof" \
	$JAVA_OPTS \
	-classpath "$BALLERINA_CLASSPATH" \
	-Djava.endorsed.dirs="$JAVA_ENDORSED_DIRS" \
	-Dballerina.home=$BALLERINA_HOME \
	-Dballerina.version=0.95.1 \
	-Djava.util.logging.config.file="$BALLERINA_HOME/bre/conf/logging.properties" \
	-Djava.util.logging.manager="org.ballerinalang.logging.BLogManager" \
	-Dtransports.netty.conf="$BALLERINA_HOME/bre/conf/netty-transports.yml" \
	-Djava.io.tmpdir="$BALLERINA_HOME/tmp" \
	-Denable.nonblocking=false \
	-Djava.security.egd=file:/dev/./urandom \
	-Dfile.encoding=UTF8 \
	org.ballerinalang.launcher.Main $COMMANDLINE
