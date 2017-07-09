#
#  neo4j/private/low_level.nim
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

## Provides simple routines working directly with the `libneo4j-client
## <https://github.com/cleishm/libneo4j-client>`_ wrapper.

import strutils
import wrapper, ../errors

const cypherGetById = """
MATCH (s)
WHERE ID(s) = $1
RETURN s
"""

proc getNode*(connection: ptr Connection, id: uint64): Neo4jValue =
  # FIXME: use a more appropriate error type 
  var results = connection.run(cypherGetById % $id, null)
  if results.isNil:
    raise newException(Neo4jError, "Failed to run Cypher query.")
  var res = results.fetchNext
  if res.isNil:
    raise newException(Neo4jError, "No results were produced by Cypher query.")
  result = res[0]
  if result == null:
    raise newException(Neo4jError, "No results were produced by Cypher query.")
