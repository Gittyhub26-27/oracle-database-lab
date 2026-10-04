#!/usr/bin/env bash
echo "== Java =="
java -version 2>&1
echo
echo "== JAVA_HOME =="
echo "$JAVA_HOME"
echo
echo "== SQLcl =="
sql -version
