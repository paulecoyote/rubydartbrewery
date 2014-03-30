rubydartbrewery
===============

Dart script to generate ruby homebrew formula tracking the latest versions.

Requirements
============
Recent version of Dart.

Usage
=====
Use the shell scripts on Mac / Linux... or on Windows you could just use dart.

pub update
dart bin/rubydartbrewery.dart --output-path "../somewhere_else"

Notes
=====

This is all really very rough and there is plenty of room for improvement. But it does the job so far.

Links
=====
* Output of this is here: https://github.com/PaulECoyote/homebrew-paulecoyote
* For Homebrew info see http://brew.sh
* For the Google Dart language see https://www.dartlang.org/
* For the scripts that generate these homebrew formula see https://github.com/PaulECoyote/rubydartbrewery
* Scripts produced are based on work originally done by Kevin Moore. This alternative wraps up the content shell and is manually maintained.  See: 
    * http://work.j832.com/2013/11/if-you-do-any-open-source-development.html
    * https://github.com/kevmoo/homebrew-kevmoo
    