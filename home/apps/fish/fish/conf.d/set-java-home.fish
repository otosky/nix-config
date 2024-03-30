#! /usr/bin/fish

function set-java-home
    set --local java_path (which java)
    if test -n "$java_path"
        set --local full_path (builtin realpath "$java_path")

        # `builtin realpath` returns $JAVA_HOME/bin/java, so we need two `dirname` calls
        # in order to get the correct JAVA_HOME directory
        set -gx JAVA_HOME (dirname (dirname "$full_path"))
        set -gx JDK_HOME "$JAVA_HOME"
    end
end
