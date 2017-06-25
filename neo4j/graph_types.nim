#
#  neo4j/graph_types.nim
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

## The set of core graph data types for use with Neo4j. They can also
## be used independently.

import tables, sets
import wrapper, errors

type
  Neo4jKinds* = enum
    n4kBool
    n4kInt
    n4kFloat
    n4kString
    n4kList
    n4kMap

  Neo4jObject* = object
    case kind: Neo4jKinds
    of n4kBool: boolVal: bool
    of n4kInt: intVal: int
    of n4kFloat: floatVal: float
    of n4kString: stringVal: string
    of n4kList: listVal: seq[Neo4jObject]
    of n4kMap: mapVal: Table[string, Neo4jObject]

  Neo4jScalar* = bool or int or float or string

  Neo4jConvertible* = Neo4jScalar or seq[Neo4jScalar]


proc toNeo4jObject*(value: Neo4jValue): Neo4jObject =
  if value.`type` == NEO4J_BOOL:
    result = Neo4jObject(kind: n4kBool, boolVal: value.toBool)
  elif value.`type` == NEO4J_INT:
    result = Neo4jObject(kind: n4kInt, intVal: value.toInt.int)
  elif value.`type` == NEO4J_FLOAT:
    result = Neo4jObject(kind: n4kFloat, floatVal: value.toFloat.float)
  elif value.`type` == NEO4J_STRING:
    result = Neo4jObject(kind: n4kString, stringVal: $value.toUstring)
  elif value.`type` == NEO4J_LIST:
    let n = value.listLen
    var contents = newSeq[Neo4jObject](n)
    for i in 0..<n:
      contents[i.int] = value[i].toNeo4jObject
    result = Neo4jObject(kind: n4kList, listVal: contents)
  elif value.`type` == NEO4J_MAP:
    let n = value.mapLen
    var contents = initTable[string,Neo4jObject](tables.rightsize(n))
    var obj: ptr MapEntry
    for i in 0..<n:
      obj = value.mapGetEntry(i)
      contents[$obj.key] = obj.value.toNeo4jObject
    result = Neo4jObject(kind: n4kMap, mapVal: contents)
  else:
    raise newException(Neo4jTypeError, "Value type is not basic")

converter toBool*(value: Neo4jObject): bool =
  if value.kind != n4kBool:
    raise newException(Neo4jTypeError, "Value not of kind n4kBool")
  result = value.boolVal

converter toInt*(value: Neo4jObject): int =
  if value.kind != n4kInt:
    raise newException(Neo4jTypeError, "Value not of type n4kInt")
  result = value.intVal

converter toFloat*(value: Neo4jObject): float =
  if value.kind != n4kFloat:
    raise newException(Neo4jTypeError, "Value not of type n4kFloat")
  result = value.floatVal

converter toString*(value: Neo4jObject): string =
  if value.kind != n4kString:
    raise newException(Neo4jTypeError, "Value not of type n4kString")
  result = value.stringVal

converter toSeq*(value: Neo4jObject): seq[Neo4jObject] =
  if value.kind != n4kList:
    raise newException(Neo4jTypeError, "Value not of type n4kList")
  result = value.listVal

converter toTable*(value: Neo4jObject): Table[string, Neo4jObject] =
  if value.kind != n4kMap:
    raise newException(Neo4jTypeError, "Value not of type n4kMap")
  result = value.mapVal

converter toBoolSeq*(value: Neo4jObject): seq[bool] =
  if value.`type` != NEO4J_LIST:
    raise newException(Neo4jTypeError, "Value not of type NEO4J_LIST")
  result = newSeq[bool](value.len)
  for i, obj in value.listVal.pairs:
    result[i] = obj

converter toIntSeq*(value: Neo4jObject): seq[int] =
  if value.`type` != NEO4J_LIST:
    raise newException(Neo4jTypeError, "Value not of type NEO4J_LIST")
  result = newSeq[int](value.len)
  for i, obj in value.listVal.pairs:
    result[i] = obj

converter toFloatSeq*(value: Neo4jObject): seq[float] =
  if value.`type` != NEO4J_LIST:
    raise newException(Neo4jTypeError, "Value not of type NEO4J_LIST")
  result = newSeq[float](value.len)
  for i, obj in value.listVal.pairs:
    result[i] = obj

converter toStringSeq*(value: Neo4jObject): seq[string] =
  if value.`type` != NEO4J_LIST:
    raise newException(Neo4jTypeError, "Value not of type NEO4J_LIST")
  result = newSeq[string](value.len)
  for i, obj in value.listVal.pairs:
    result[i] = obj

proc toNeo4j*(value: Neo4jConvertible): Neo4jObject =
  case type(value)
  of bool: result = Neo4jObject(kind: n4kBool, boolVal: value)
  of int: result = Neo4jObject(kind: n4kInt, intVal: value)
  of float: result = Neo4jObject(kind: n4kFloat, floatVal: value)
  of string: result = Neo4jObject(kind: n4kString, stringVal: value)
  of seq:
    var contents = newSeq[Neo4jObject](value.len)
    for i, obj in value.pairs:
      contents[i] = obj.toNeo4j
    result = Neo4jObject(kind: n4kList, listVal: contents)


type
  Node* = object
    labels: HashSet[string]
    properties: Table[string, Neo4jObject]
    localId: int
    remoteId: Neo4jValue
    changed: bool

  Relationship* = object
    reltype: string
    properties: Table[string, Neo4jObject]
    startNode: Node
    endNode: Node
    localId: int
    remoteId: Neo4jValue
    changed: bool

  Subgraph* = object
    relationships: seq[Relationship]
    nodes: HashSet[Node]

  PropertyDict = concept x
    x.properties is Table[string, Neo4jObject]
    x.changed is bool
    x.change = true


# Routines for working with Node and Relationship properties

proc `[]`*(obj: PropertyDict, key: string): Neo4jObject =
  result = obj.properties[key]

proc `[]=`*(obj: var PropertyDict, key: string, value: Neo4jObject) =
  obj.properties[key] = value
  obj.changed = true

proc contains*(obj: PropertyDict, key: string): bool =
  result = key in obj.properties

proc len*(obj: PropertyDict): int =
  result = obj.properties.len

proc del*(obj: var PropertyDict, key: string) =
  obj.properties.del(key)
  obj.changed = true

proc clear*(obj: var PropertyDict) =
  obj.properties.clear()
  obj.changed = true
  
iterator keys*(obj: PropertyDict): string =
  for k in obj.properties.keys:
    yield k

iterator items*(obj: PropertyDict): string =
  for k in obj.properties.keys:
    yield k

iterator values*(obj: PropertyDict): Neo4jObject =
  for v in obj.properties.values:
    yield v

iterator pairs*(obj: PropertyDict): (string, Neo4jObject) =
  for k, v in obj.properties.pairs:
    yield (k, v)
    
proc toTable*(obj: PropertyDict): Table[string, Neo4jObject] =
  result = obj.properties

# Routines for working with Node labels

proc labels*(obj: Node): HashSet[string] =
  result = obj.labels

proc addLabel*(obj: var Node, label: string) =
  obj.labels.incl(label)
  obj.changed = true

proc addLabels*(obj: var Node, labels: HashSet[string]) =
  obj.labels.incl(labels)
  obj.changed = true

proc removeLabel*(obj: var Node, label: string) =
  obj.labels.excl(label)
  obj.changed = true

proc clearLabels*(obj: var Node) =
  obj.labels.clear()
  obj.changed = true

proc hasLabel*(obj: Node, label: string): bool =
  result = label in obj.labels
