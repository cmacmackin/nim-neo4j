#
#  neo4j/basic_types.nim
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

## The basic data types for holding Neo4j values. They can also be
## used independently.

import tables
import private/wrapper, errors

type
  Neo4jKinds* = enum
    n4kBool
    n4kInt
    n4kFloat
    n4kString
    n4kList
    n4kMap

  Neo4jObject* = object
    ## The basic type of value returned by Neo4j queries. It can
    ## represent boolean, integer, float, string values, or lists of
    ## any of these. It can also represent a map from strings to other
    ## Neo4jObjects.
    case kind: Neo4jKinds
    of n4kBool: boolVal: bool
    of n4kInt: intVal: int
    of n4kFloat: floatVal: float
    of n4kString: stringVal: string
    of n4kList: listVal: seq[Neo4jObject]
    of n4kMap: mapVal: Table[string, Neo4jObject]

  Neo4jScalar* = bool or int or float or string
    ## Nim data types corresponding to the basic Neo4j types.

  Neo4jConvertible* = (Neo4jScalar or
                       seq[Neo4jScalar] or
                       Table[string, Neo4jScalar])
    ## Nim data types which can be converted into Neo4jObjects.

proc toNeo4jObject*(value: Neo4jValue): Neo4jObject =
  ## Convert the low-level Neo4jValue used by the C library into a
  ## Neo4jObject designed to work with more idiomatic Nim.
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
    raise newException(Neo4jTypeError, "Value not of basic kind")

converter toBool*(value: Neo4jObject): bool =
  ## Convert the object into a boolean value, raising a Neo4jTypeError
  ## if this is not the type of value held.
  if value.kind != n4kBool:
    raise newException(Neo4jTypeError, "Value not of kind n4kBool")
  result = value.boolVal

converter toInt*(value: Neo4jObject): int =
  ## Convert the object into an integer value, raising a Neo4jTypeError
  ## if this is not the type of value held.
  if value.kind != n4kInt:
    raise newException(Neo4jTypeError, "Value not of type n4kInt")
  result = value.intVal

converter toFloat*(value: Neo4jObject): float =
  ## Convert the object into a float value, raising a Neo4jTypeError
  ## if this is not the type of value held.
  if value.kind != n4kFloat:
    raise newException(Neo4jTypeError, "Value not of type n4kFloat")
  result = value.floatVal

converter toString*(value: Neo4jObject): string =
  ## Convert the object into a string value, raising a Neo4jTypeError
  ## if this is not the type of value held.
  if value.kind != n4kString:
    raise newException(Neo4jTypeError, "Value not of type n4kString")
  result = value.stringVal

converter toSeq*(value: Neo4jObject): seq[Neo4jObject] =
  ## Convert the object into a sequence of objects, raising a
  ## Neo4jTypeError if this is not the type of value held.
  if value.kind != n4kList:
    raise newException(Neo4jTypeError, "Value not of type n4kList")
  result = value.listVal

converter toTable*(value: Neo4jObject): Table[string, Neo4jObject] =
  ## Convert the object into a table, raising a Neo4jTypeError if this
  ## is not the type of value held.
  if value.kind != n4kMap:
    raise newException(Neo4jTypeError, "Value not of type n4kMap")
  result = value.mapVal

converter toBoolSeq*(value: Neo4jObject): seq[bool] =
  ## Convert the object into a sequence of booleans, raising a
  ## Neo4jTypeError if this is not the type of value held.
  if value.kind != n4kList:
    raise newException(Neo4jTypeError, "Value not of type NEO4J_LIST")
  result = newSeq[bool](value.len)
  for i, obj in value.listVal.pairs:
    result[i] = obj

converter toIntSeq*(value: Neo4jObject): seq[int] =
  ## Convert the object into a sequence of integers, raising a
  ## Neo4jTypeError if this is not the type of value held.
  if value.kind != n4kList:
    raise newException(Neo4jTypeError, "Value not of type NEO4J_LIST")
  result = newSeq[int](value.len)
  for i, obj in value.listVal.pairs:
    result[i] = obj

converter toFloatSeq*(value: Neo4jObject): seq[float] =
  ## Convert the object into a sequence of floats, raising a
  ## Neo4jTypeError if this is not the type of value held.
  if value.kind != n4kList:
    raise newException(Neo4jTypeError, "Value not of type NEO4J_LIST")
  result = newSeq[float](value.len)
  for i, obj in value.listVal.pairs:
    result[i] = obj

converter toStringSeq*(value: Neo4jObject): seq[string] =
  ## Convert the object into a sequence of strings, raising a
  ## Neo4jTypeError if this is not the type of value held.
  if value.kind != n4kList:
    raise newException(Neo4jTypeError, "Value not of type NEO4J_LIST")
  result = newSeq[string](value.len)
  for i, obj in value.listVal.pairs:
    result[i] = obj

proc toNeo4j*(value: Neo4jConvertible): Neo4jObject =
  ## Convert compatible intrinsic Nim types into a Neo4jObject.
  case type(value)
  of bool: result = Neo4jObject(kind: n4kBool, boolVal: value)
  of int: result = Neo4jObject(kind: n4kInt, intVal: value)
  of float: result = Neo4jObject(kind: n4kFloat, floatVal: value)
  of string: result = Neo4jObject(kind: n4kString, stringVal: value)
  of seq:
    var contents = newSeq[Neo4jObject](value.len)
    for i, v in value.pairs:
      contents[i] = v.toNeo4j
    result = Neo4jObject(kind: n4kList, listVal: contents)
  of Table:
    var contents = initTable[string, Neo4jObject](value.len.rightSize)
    for k, v in value.pairs:
      contents[k] = v.toNeo4j
    result = Neo4jObject(kind: n4kMap, mapVal: contents)

proc `$`*(value: Neo4jObject): string =
  ## Converts the Neo4j object to a string representation. The same
  ## representation is used as would be for this value in Cypher.
  case value.kind
  of n4kBool:
    result = $value.boolVal
  of n4kInt:
    result = $value.intVal
  of n4kFloat:
    result = $value.floatVal
  of n4kString:
    result = '\'' & value.stringVal & '\''
  of n4kList:
    result = "["
    var i = 0
    for val in value.listVal:
      if i != 0: result &= ','
      result &= $val
      inc i
    result &= ']'
  of n4kMap:
    result = "{ "
    var i = 0
    for k, v in value.mapVal:
      if i != 0: result &= ','
      result &= k & ": " & $v
      inc i
    result &= " }"
