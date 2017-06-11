# Package
version       = "0.1.0"
author        = "Chris MacMackin"
description   = "A Nim driver for the Neo4j graph database."
license       = "LGPL"


# Dependencies
requires "nim >= 0.15.2"

import ospaths

# Configurations
const bdir = "bin/"
const tdir = "tests/"

--nimcache: "./nimcache"
#skipDirs = @[tdir&"wrapper"]
installDirs = @["neo4j"]

proc runTest(name: string) =
  mkDir $bdir
  switch("define","TDIR=" & tdir[0..^2])
  --run
  switch("out", (bdir & name.extractFilename))
  setCommand "c", tdir & name & ".nim"

task tests, "Run specified unit tests. Defaults to running all.":
  if paramCount() > 1:
    runTest paramStr(2)
  else:
    runTest "all_tests"
