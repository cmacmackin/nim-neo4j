#
#  neo4j/errors.nim
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

## Provides exception classes for the Neo4j library.

type
  Neo4jError* = object of Exception
    ## Abstract exception class

  Neo4jConfigError* = object of Neo4jError
    ## Exception raised when unable to set a configuration property

  Neo4jTypeError* = object of Neo4jError
    ## Exception raised when Neo4jValue of inappropriate type is
    ## passed.
