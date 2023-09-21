#!/bin/sh

# different current directory when the script is double click from Finder
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${DIR}"

sh ./run-tasks.sh   $1

exit 0