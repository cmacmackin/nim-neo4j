#
#  util.nim
#  This file is part of nim-neo4j
#  
#  Copyright 2017 Chris MacMackin <cmacmackin@gmail.com>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
#

import strutils, sequtils

type
  ServerVersion = object
    product: string
    version: seq[int]
    tags: seq[string]

proc atLeastVersion(vers: ServerVersion, major, minor: int): bool =
  result = (vers.version[0] > major) or (vers.version[0] == major and
                                         vers.version[1] > minor)

proc newServerVersion(fullVersion: string): ServerVersion =
  if fullVersion == "":
    result = ServerVersion(product: "Neo4j", version: @[3, 0], tags: @[])
  else:
    let
      splitVersion = fullVersion.split('/', 1)
      tags = splitVersion[1].split('-')
      vers = map(tags[0].split('.'), parseInt)
    result = ServerVersion(product: splitVersion[0], version: vers,
                           tags: tags[1..^1])

