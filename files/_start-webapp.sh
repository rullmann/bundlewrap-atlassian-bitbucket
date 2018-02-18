#!/usr/bin/env bash

if [ -z "$BIN_DIR" ] || [ -z "$INST_DIR" ] || [ -z "$BITBUCKET_HOME" ]; then
    echo "$0 is not intended to be run directly. Run start-bitbucket.sh instead"
    echo "To start the Bitbucket webapp without starting search, run start-bitbucket.sh --no-search"
    exit 1
fi

# Occasionally Atlassian Support may recommend that you set some specific JVM arguments.  You can use this
# variable to do that. Simply uncomment the below line and add any required arguments. Note however, if this
# environment variable has been set in the environment of the user running this script, uncommenting the below
# will override that.
#
% if node.metadata.get('atlassian-bitbucket', {}).get('jvm_args', False):
JVM_SUPPORT_RECOMMENDED_ARGS="${node.metadata.get('atlassian-bitbucket', {}).get('jvm_args')}"
% endif

# The following 2 settings control the minimum and maximum memory allocated to the Java virtual machine.
# For larger instances, the maximum amount will need to be increased.
#
<%text>if [ -z "${JVM_MINIMUM_MEMORY}" ]; then</%text>
    JVM_MINIMUM_MEMORY="${node.metadata.get('atlassian-bitbucket', {}).get('jvm_min_memory', "1024m")}"
fi
<%text>if [ -z "${JVM_MAXIMUM_MEMORY}" ]; then</%text>
    JVM_MAXIMUM_MEMORY="${node.metadata.get('atlassian-bitbucket', {}).get('jvm_max_mamory', "1024m")}"
fi
<%text>
# Uncommenting the following will set the umask for the webapp. It can be used to override the default
# settings for the service user if they are not sufficiently secure.
#
# umask 0027

UMASK=$(umask)
UMASK_SYMBOLIC=$(umask -S)
if echo $UMASK | grep -qv '0[2367]7$'; then
    FORCE_EXIT=false

    echo -e "\nBitbucket is being run with a umask that contains potentially unsafe settings."
    echo "The following issues were found with the mask \"$UMASK_SYMBOLIC\" ($UMASK):"
    if echo $UMASK | grep -qv '7$'; then
        echo " - Access is allowed to 'others'. It is recommended that 'others' be denied"
        echo "   all access for security reasons."
    fi
    if echo $UMASK | grep -qv '[2367][0-9]$'; then
        echo " - Write access is allowed to 'group'. It is recommend that 'group' be"
        echo "   denied write access. Read access to a restricted group is recommended"
        echo "   to allow access to the logs."
    fi
    if echo $UMASK | grep -qv '0[0-9][0-9]$'; then
        echo " - Full access has been denied to 'user'. Bitbucket cannot be run without full"
        echo "   access being allowed."
        FORCE_EXIT=true
    fi
    echo "The recommended umask for Bitbucket is \"u=,g=w,o=rwx\" (0027) and can be"
    echo "configured in _start-webapp.sh"

    if [ "x${FORCE_EXIT}" = "xtrue" ]; then
        exit 1;
    fi
fi

MAX_OPEN_FILES=4096
if [ $(ulimit -n) -lt ${MAX_OPEN_FILES} ]; then
    echo -e "\nThe current open files limit is set to less than $MAX_OPEN_FILES\nAttempting to increase limit..."
    if ulimit -n $MAX_OPEN_FILES; then
        echo -e "\tLimit increased to $MAX_OPEN_FILES open files"
    else
        echo -e "Warning: Open file limit could not be increased. You may experience problems under heavy load"
    fi
fi

if [ ! -d "$BITBUCKET_HOME/log" ]; then
    mkdir -p "$BITBUCKET_HOME/log"
    if [ $? -ne 0 ]; then
        echo "$BITBUCKET_HOME/log could not be created. Permissions issue?"
        echo "The Bitbucket webapp was not started"
        exit 1
    fi
fi

source $BIN_DIR/set-jmx-opts.sh
if [ $? -ne 0 ]; then
    exit 1
fi

JVM_LIBRARY_PATH="$INST_DIR/lib/native;$BITBUCKET_HOME/lib/native"

BITBUCKET_ARGS="-Datlassian.standalone=BITBUCKET -Dbitbucket.home=$BITBUCKET_HOME -Dbitbucket.install=$INST_DIR"
JVM_FILE_ENCODING_ARGS="-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"
JVM_JAVA_ARGS="-Djava.io.tmpdir=$BITBUCKET_HOME/tmp -Djava.library.path=$JVM_LIBRARY_PATH"
JVM_MEMORY_ARGS="-Xms$JVM_MINIMUM_MEMORY -Xmx$JVM_MAXIMUM_MEMORY -XX:+UseG1GC"
JVM_REQUIRED_ARGS="$JVM_MEMORY_ARGS $JVM_FILE_ENCODING_ARGS $JVM_JAVA_ARGS"

JAVA_OPTS="-classpath $INST_DIR/app $JAVA_OPTS $BITBUCKET_ARGS $JMX_OPTS $JVM_REQUIRED_ARGS $JVM_SUPPORT_RECOMMENDED_ARGS"
LAUNCHER="com.atlassian.bitbucket.internal.launcher.BitbucketServerLauncher"

echo -e "\nStarting Bitbucket webapp at http://localhost:7990"
if [ "$1" == "run" ]; then
    $JAVA_BINARY $JAVA_OPTS $LAUNCHER start --logging.console=true
else
    nohup $JAVA_BINARY $JAVA_OPTS $LAUNCHER start >> $BITBUCKET_HOME/log/launcher.log 2>&1 &
    echo $! > "$BITBUCKET_HOME/log/bitbucket.pid"

    if [ $? -eq 0 ]; then
        echo -e "The Bitbucket webapp has been started.\n"
        echo "If you cannot access Bitbucket within 3 minutes, or encounter other issues, check the troubleshooting guide at:"
        echo "https://confluence.atlassian.com/display/BitbucketServerKB/Troubleshooting+Installation"
    else
        if [ -f "$BITBUCKET_HOME/log/bitbucket.pid" ]; then
            # If the application failed to start, remove the PID file
            rm "$BITBUCKET_HOME/log/bitbucket.pid"
        fi

        echo "There was a problem starting the Bitbucket webapp"
    fi
fi
</%text>