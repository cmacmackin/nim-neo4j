#
#  tests/wrapper/error_handling.nim
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

import unittest, posix
import neo4j.wrapper

suite "Tests results of Neo4j strerror procedure.":
  test "Test delegates for standard errnums.":
    var buf1: array[1024, char]
    let neo4j_err = strerror(EINVAL, buf1, buf1.sizeof)
    let std_err = strerror(EINVAL)
    check:
      not neo4j_err.isNil
      neo4j_err == std_err
      neo4j_err != strerror(EPERM)

  test "Test invalid arguments.":
    check:
      strerror(-1, nil, 10).isNil
      errno == EINVAL
