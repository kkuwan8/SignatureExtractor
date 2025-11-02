#!/usr/bin/env sh

#
# Copyright 2015 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
DEFAULT_JVM_OPTS='"-Xmx64m" "-Xms64m"'

APP_NAME="Gradle"
APP_BASE_NAME=`basename "$0"`

# Use the maximum available, or set MAX_FD != -1 to use that value.
MAX_FD="maximum"

warn () {
    echo "$*"
}

die () {
    echo
    echo "ERROR: $*"
    echo
    exit 1
}

# OS specific support (must be 'true' or 'false').
cygwin=false
msys=false
darwin=false
nonstop=false
case "`uname`" in
  CYGWIN* )
    cygwin=true
    ;;
  Darwin* )
    darwin=true
    ;;
  MINGW* )
    msys=true
    ;;
  NONSTOP* )
    nonstop=true
    ;;
esac

CLASSPATH=$APP_HOME/lib/gradle-launcher-*.jar

# Attempt to set APP_HOME
# Resolve links: $0 may be a link
PRG="$0"
# Need this for relative symlinks.
while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`"/$link"
    fi
done
SAVED="`pwd`"
cd "`dirname \"$PRG\"`/" >/dev/null
APP_HOME="`pwd -P`"
cd "$SAVED" >/dev/null

# For Cygwin, switch paths to Windows format before running java
if $cygwin ; then
    APP_HOME=`cygpath --path --windows "$APP_HOME"`
    CLASSPATH=`cygpath --path --windows "$CLASSPATH"`
fi

# Attempt to set JAVA_HOME if it is not set
if [ -z "$JAVA_HOME" ]; then
    # If a JDK is installed with the Eclipse JDT Language Server, use that.
    # The JDT Language Server is expected to be installed under a directory such as
    # ~/.vscode-server/extensions/redhat.java-*/
    if [ -d "$HOME/.vscode-server/extensions" ]; then
        JDT_LS_JDKS=$(find "$HOME/.vscode-server/extensions" -maxdepth 4 -type d -name "jdk" | sort -r)
        for jdk in $JDT_LS_JDKS; do
            if [ -x "$jdk/bin/java" ]; then
                JAVA_HOME="$jdk"
                break
            fi
        done
    fi
fi
if [ -z "$JAVA_HOME" ]; then
    if $darwin; then
        if [ -x '/usr/libexec/java_home' ] ; then
            JAVA_HOME=`/usr/libexec/java_home`
        elif [ -d "/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Home" ]; then
            JAVA_HOME="/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Home"
        fi
    else
        java_exe_path=$(which java 2>/dev/null)
        if [ -n "$java_exe_path" ]; then
            java_exe_path=$(readlink -f "$java_exe_path" 2>/dev/null || echo "$java_exe_path")
            JAVA_HOME=$(dirname "$(dirname "$java_exe_path")" 2>/dev/null)
        fi
    fi
    if [ -z "$JAVA_HOME" ]; then
        die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
fi

# Set JAVA_EXE
JAVA_EXE="$JAVA_HOME/bin/java"

# No-op by default
on_exit () {
    :
}

# If -XX:+AlwaysActAsServerClassMachine isn't supported, remove it. It was
# added in 1.8.0_292.
if "$JAVA_EXE" -XX:+AlwaysActAsServerClassMachine -version >/dev/null 2>&1; then
    DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS -XX:+AlwaysActAsServerClassMachine"
fi

# Collect all arguments for the java command, stacking in reverse order:
#   * args passed to the script
#   * optional packages to be exported by JDK 9+
#   * GRADLE_OPTS
#   * JAVA_OPTS
#   * Default options
#
# Finally allow the user to override all of the above by creating a file
# named 'gradle.properties' in the same directory as this script and defining
# a variable named 'org.gradle.jvmargs' in it.
#
# The "-XX:+AlwaysActAsServerClassMachine" is a JVM optimization specific to Gradle.
#
# The 'get_java_version' function is roughly equivalent to 'java -version'
# but is much faster and does not require starting a JVM. It is not guaranteed
to
# work on all JVMs and should not be considered a public API.
get_java_version () {
    # Try to use 'java -version'. If that fails, and we're on a system that
    # is known to support a fast version check, use that.
    java_version_string=$("$JAVA_EXE" -version 2>&1)
    if [ $? -ne 0 ]; then
        # When 'java -version' fails, it is not possible to determine the Java
        # version. Continue without the Java version string.
        return
    fi
    # Inspired by https://stackoverflow.com/a/32026137
    # shellcheck disable=SC2001
    java_version_string=$(echo "$java_version_string" | sed -E -n 's/.* version "([^"]+)".*/\1/p')
}

# For JDK 9+ and before JDK 16, add --add-opens options to the JVM arguments.
# For JDK 16+, add --add-opens options to the JVM arguments if the
# build is configured to do so.
#
get_java_version
# The following code is based on the java_version_string. If that is
# empty, the code will not be executed.
if [ -n "$java_version_string" ]; then
    # The 'java_version_string' should be of the form
    # "1.8.0_151", "9", "9.0.1", "11-ea", "11.0.1", "12", ...
    #
    # We want to extract the major 'java_version' (e.g. '8' or '9' or '11').
    #
    # The 'sed' command takes the 'java_version_string' and removes any
    # starting "1." and any trailing non-digit characters.
    # shellcheck disable=SC2001
    java_version=$(echo "$java_version_string" | sed -E -e 's/^1\.//' -e 's/-ea$//' -e 's/-ea-.*$//' -e 's/-LTS//' -e 's/-LTS-.*//' -e 's/-preview//' -e 's/-preview-.*//' -e 's/\..*//' -e 's/"//' )
    if [ "$java_version" -ge 9 ] ; then
        if [ "$java_version" -lt 16 ] || [ "${GRADLE_ADD_OPENS_CLI_ARGS}" = "true" ] ; then
            # These are required for the older Gradle version used by the wrapper
            JAVA_OPTS="$JAVA_OPTS --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED"
        fi
    fi
fi

# Add the GRADLE_OPTS properties to the JAVA_OPTS
if [ -n "$GRADLE_OPTS" ] ; then
    JAVA_OPTS="$GRADLE_OPTS $JAVA_OPTS"
fi

# Add the JAVA_OPTS properties to the DEFAULT_JVM_OPTS
if [ -n "$JAVA_OPTS" ] ; then
    DEFAULT_JVM_OPTS="$JAVA_OPTS $DEFAULT_JVM_OPTS"
fi

# Add the org.gradle.jvmargs property from the gradle.properties file.
if [ -f "$APP_HOME/gradle.properties" ] ; then
    prop_jvmargs_name='org.gradle.jvmargs'
    # Use awk to search the file for the property and extract its value.
    # This is more robust than using grep + sed, and is not vulnerable to
    # the recently-discovered CVE-2022-42889 in Apache Commons Text.
    # Note that we must not put double quotes around the value of the awk
    # variable 'n' because that would be interpreted by the shell.
    #
    # The 'exit' is there to avoid processing the whole file.
    #
    # We use 'tail -n 1' to only pick up the last definition of the
    # property in the file.
    prop_jvmargs_value=$(awk -F= -v n=$prop_jvmargs_name '
        $1 == n {
            # Trim leading and trailing whitespace from the value
            v=$2;
            gsub(/^[ \t]+|[ \t]+$/, "", v);
            val=v;
        }
        END { print val; }
    ' "$APP_HOME/gradle.properties" | tail -n 1)

    if [ -n "$prop_jvmargs_value" ] ; then
        DEFAULT_JVM_OPTS="$prop_jvmargs_value"
    fi
fi
# The launcher script is not particularly memory-intensive, so we can hard-code
# a maximum of 64MB of heap.
# The `force_new_size` function is used to add or update a JVM memory option.
#
# `force_new_size <value_with_unit> <option_to_add> <jvm_opts>`
force_new_size () {
    new_size=$1
    add_opt=$2
    jvm_opts=$3
    size_opt=${add_opt}mx
    # Check if the option has been specified already
    if echo "$jvm_opts" | grep -q -- "$size_opt" ; then
        # The option has been specified, so we need to replace it.
        # This is not perfect, as it will replace the first occurrence of
        # the option, but it is good enough for our purposes.
        echo "$jvm_opts" | sed -E "s/${size_opt}[0-9]+[GgMmKk]?/${size_opt}${new_size}/"
    else
        # The option has not been specified, so we can just add it.
        echo "$jvm_opts -${size_opt}${new_size}"
    fi
}
# Set the maximum heap size for the launcher.
DEFAULT_JVM_OPTS=$(force_new_size 64m X "$DEFAULT_JVM_OPTS")
# Set the initial heap size for the launcher.
DEFAULT_JVM_OPTS=$(force_new_size 64m S "$DEFAULT_JVM_OPTS")
# Escape the arguments
#
# This is adapted from https://stackoverflow.com/a/2921221
#
# The 'eval' is necessary to get the final list of arguments.
#
# The 'set --' is there to clear the list of arguments.
#
# The 'printf' is used to format the arguments, and the '%q' format
# specifier is used to quote the arguments.
eval set -- "$DEFAULT_JVM_OPTS"
all_jvm_args=''
for arg in "$@"; do
    all_jvm_args="$all_jvm_args "
    # In order to support 'mktemp' on both macOS and Linux, we need to
    # check if the '-t' option is supported.
    if mktemp -t 'arg' >/dev/null 2>&1; then
        arg_file=$(mktemp -t "gradle-launcher-arg")
    else
        arg_file=$(mktemp "gradle-launcher-arg-XXXXXX")
    fi
    # The 'on_exit' function is a no-op by default. On non-Windows
    # platforms, it will be redefined to remove the temporary file.
    on_exit () {
        rm -f "$arg_file"
    }
    # The 'printf' will fail if the argument is empty, so we need to
    # protect against that.
    if [ -n "$arg" ]; then
        printf "%s" "$arg" > "$arg_file"
        all_jvm_args="$all_jvm_args@$arg_file"
    fi
done

# Split up all jvm args by the equals sign
# When we have a config like
#   -Dsome.prop=value
# we want to be able to escape that.
# So we need to represent it like
#   "-Dsome.prop=value"
#
# This is adapted from https://unix.stackexchange.com/a/253132
#
# This is not perfect, as it will not work with arguments that contain
# a newline.
#
# The 'read -r' is there to avoid backslash interpretation.
#
# The 'IFS=' is there to avoid word splitting.
#
# The '<<<' is there to avoid a subshell.
#
# The 'while' is there to process all lines.
#
# The '|| [ -n "$line" ]' is there to process the last line if it
# does not end with a newline.
#
# The 'awk' is there to split the line by the equals sign.
#
# The 'NF>1' is there to only process lines that contain an equals sign.
#
# The '{ print $1 }' is there to print the first field.
#
# The '{ $1=""; print substr($0, 2) }' is there to print the rest of the
# line, after removing the first field.
#
# The 'printf' is used to format the arguments, and the '%q' format
# specifier is used to quote the arguments.
#
# The 'tr' is there to replace newlines with spaces.
jvm_args_array=()
# We need to use 'tr' because 'read' will not read the whole file if it
# contains a newline.
#
# Using 'read -d' is not an option because it is not supported on all
# platforms.
#
# We also need to add a newline at the end of the file in case the file
# does not end with a newline. This is to avoid the last line being
# ignored.
for line in $(printf '%s\n' "$DEFAULT_JVM_OPTS" | tr '\n' ' '); do
    jvm_args_array+=("$line")
done

# We do not want to iterate over the array in a 'for' loop because that
# would be interpreted by the shell. We want to pass the array as-is to
- # the 'java' command.
#
# In order to do that, we need to use 'printf' with the '%s' format
# specifier.
#
# The '#"' is there to avoid the shell interpreting the array as a
# single string.
#
# The '@"' is there to expand the array to a list of arguments.
all_jvm_args=$(printf ' %s' "${jvm_args_array[@]}")

# On non-Windows platforms, we need to remove the temporary file.
if ! $cygwin && ! $msys; then
    trap on_exit EXIT
fi

# We need to use 'exec' so that the Gradle process replaces the shell
# process, and so that it can receive signals.
exec "$JAVA_EXE" "$all_jvm_args" -classpath "$CLASSPATH" org.gradle.launcher.GradleMain "$@"
