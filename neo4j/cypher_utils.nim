#
#  neo4j/cypher_utils.nim
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

## Routines for working with Cypher queries.

import tables, strutils
import basic_types

proc labelList(labels: openArray[string]): string =
  ## Converts an array of labels into the Cypher representation of
  ## multiple labels. Lables are capitalised.
  if labels.len == 0:
    result = ":"
  else:
    result = ""
  for lab in labels:
    result &= ":" & lab.toLowerAscii.capitalizeAscii

proc propertyTable(properties: TableRef[string, Neo4jObject]): string =
  ## Converts a table of properties into the Cypher representation of
  ## a property map. A space is prepended. However, if the table is
  ## empty then an empty string is returned.
  if properties.len == 0:
    result = ""
  else:
    var i = 0
    result = " {"
    for k, v in properties:
      if i != 0:
        result &= ','
      result &= k & ": " & $v
      inc i

proc typeFormat(reltype: string): string =
  ## Formats a relationship type to be all upper case and preceded by
  ## a colon, if the argument is a non-empty string.
  if reltype.len > 0:
    result = ':' & reltype.toUpperAscii
  else:
    result = ""
      
proc cypherNode*(labels: openArray[string], properties =
                 newTable[string, Neo4jObject](1), identifier = ""): string =
  ## Constructs a Cypher representation of a node with the specified
  ## properties. The optional ``identifier`` argument is the Cypher
  ## variable name for the node.
  let labs = labelList(labels)
  let props = propertyTable(properties)
  result = '(' & identifier & labs & props & ')'

proc cypherRelationship*(reltype = "", properties =
                         newTable[string, Neo4jObject](1),
                         identifier = ""): string =
  ## Constructs a Cypher representation of a relationship (independent
  ## from its start and end nodes) with the specified properties. The
  ## optional ``identifier`` argument is the Cypher variable name for
  ## the relationship.
  let rtype = reltype.typeFormat
  let props = propertyTable(properties)
  result = '[' & identifier & rtype & props & ']'
