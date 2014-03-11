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

if [ $# -gt 0 ]
then
    outputPath=$1
fi

cd "$DIR"
pub update
dart bin/rubydartbrewery.dart --output-path "$outputPath/"

cd "$outputPath"
git commit -a -F "dart_versions.txt"
git push origin master

cd "$pwd" 
