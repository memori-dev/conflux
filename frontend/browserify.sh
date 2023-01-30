#!/bin/bash

for var in "$@"
do
  browserify $var/main.js -o $var/main.bundle.js
done
