#!/bin/bash

# a script for cases where a program behaves differently when there is no /dev/tty
# will allocate a pseudo terminal to make them behave

function print_usage {
    echo "Usage: $(basename $0) [-h] COMMAND"
    echo ""
    echo "Allocates a pseudo-terminal (pty) for programs that behave incorrectly when /dev/tty is not available"
}

if getopts "h" arg; then
    print_usage
    exit 0
fi

setsid script /dev/null -qc "$@"
