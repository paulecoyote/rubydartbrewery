#!/bin/bash

PWD=`pwd`
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
outputPath="$DIR/../homebrew-paulecoyote"
PATH=$PATH:~/usr/local/bin

if [ $# -gt 0 ]
then
    outputPath=$1
fi

# Update this script if available
cd "$DIR"
git stash || true
git fetch origin
git reset --hard origin/master

# Reset output path to whatever is at origin
cd "$outputPath"
git stash || true
git fetch origin
git reset --hard origin/master

# Change back to script directory and update ruby files
cd "$DIR"
pub update
if dart bin/rubydartbrewery.dart --output-path "$outputPath/"; then
    # Commit any changes made to the generated ruby files
    cd "$outputPath"
    cat README-template.md dart_versions.txt > README.md
    git commit -a -F "dart_versions.txt"
    git push origin master
fi

# Finish off wherever we started
cd "$pwd" 
