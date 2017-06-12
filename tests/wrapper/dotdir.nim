#
#  tests/wrapper/dotdir.nim
#  This file is part of nim-neo4j.
#
#  Copyright 2017 Chris MacMackin <cmacmackin@gmail.com>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#

import unittest, os, posix
import neo4j.wrapper

const fakeHome = unixToNativePath("/path/to/home")

suite "Tests paths in the Neo4j dotdir.":
  setup:
    let oldHome = getEnv("HOME")
    var buffer: array[1024, char]
    putEnv("HOME", fakeHome)

  teardown:
    putEnv("HOME", oldHome)

  test "dotDir returns default directory.":
    let n = dotDir(buffer, buffer.sizeof, nil)
    check:
      n == 20
      buffer == fakeHome/".neo4j"
      dotDir(nil, 0, nil) == 20

  test "dotDir appends directory.":
    let n = dotDir(buffer, buffer.sizeof, "foo.bar")
    check:
      n == 28
      buffer == fakeHome/".neo4j"/"foo.bar"
      dotDir(nil, 0, "foo.bar") == 28
