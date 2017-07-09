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

import tables, sets, hashes, strutils, sequtils, algorithm
import private/wrapper, private/low_level, basic_types, errors, cypher_utils

proc idNum(obj: Neo4jValue): uint64 =
  ## Converts a Neo4jValue of type ``NEO4J_IDENTITY`` to an unsigned
  ## in ID number.
  if obj.`type` != NEO4J_IDENTITY:
    raise newException(Neo4jTypeError,
                       "Value passed with kind other than NEO4J_IDENTITY")
  result = obj.vdata.`int`

type
  Subgraph* = ref object of RootObj
    ## A collection of nodes and relationships. The simplest way to
    ## construct a subgraph is by combining nodes and relationships
    ## using standard set operations.
    nodes: HashSet[Node]
    relations: HashSet[Relationship]

  Node* = ref object of Subgraph
    ## A node is the fundamental unit of dat astorage within a
    ## graph. It can contain a set of key-value pairs (properties) and
    ## can optionally be adorned with one or more textual labels.
    labels: HashSet[string]
    properties: TableRef[string, Neo4jObject]
    idNum: uint64
    bound: bool
    changed: bool
    connection: ptr Connection

  Relationship* = ref object of Subgraph
    ## A relationship is a typed, directe connection between a pair of
    ## nodes (or a loop on a single node). Like nodes, relationships
    ## may contain a set of properties.
    reltype: string
    properties: TableRef[string, Neo4jObject]
    startNode: Node
    endNode: Node
    idNum: uint64
    bound: bool
    changed: bool
    connection: ptr Connection

converter toTable*(obj: Node): TableRef[string, Neo4jObject] {.inline.} =
  result = obj.properties

converter toTable*(obj: Relationship): TableRef[string, Neo4jObject] {.inline.} =
  result = obj.properties


# Routines to produce hashes for the graph elements, used when testing
# equality

proc hash*(obj: Node): Hash =
  ## Produces a hash for a node based on its ID number and whether it
  ## is bound.
  result = obj.bound.hash !& obj.idNum.hash
  result = !$result

proc hash*(obj: Relationship): Hash =
  ## Produces a hash for a relationship based on its ID number and
  ## whether it is bound.
  result = obj.bound.hash !& obj.idNum.hash
  result = !$result

proc hash*(obj: Subgraph): Hash =
  ## Produces a hash for a subgraph based on the hashes of its
  ## constituent nodes and relationships.
  for r in obj.relations:
    result = result !& r.hash
  for n in obj.nodes:
    result = result !& n.hash
  result = !$result


# Routines to convert subgraphs to strings

proc `$`*(obj: Node): string =
  ## Represents the Node using Cypher.
  var
    labs = newSeq[string](obj.labels.len)
    i = 0
  for la in obj.labels:
    # For some reason the sequtils.toSeq() template isn't working.
    labs[i] = la
    inc i
  result = cypherNode(labs, obj.properties)

proc `$`*(obj: Relationship): string =
  ## Represents the Relationship using Cypher.
  result = $obj.startNode & cypherRelationship(obj.reltype,
                                               obj.properties) & $obj.endNode


# Routines for building Subgraphs

proc newSubgraph*(nodes: openarray[Node] = [],
                  relationships: openarray[Relationship] = []): Subgraph =
  result = Subgraph(nodes: nodes.toSet,
                    relations: relationships.toSet)
  for r in result.relations:
    result.nodes.incl(r.startNode)
    result.nodes.incl(r.endNode)

proc `+`*(s1, s2: Subgraph): Subgraph =
  ## Union of two subgraphs, consisting of all nodes and relationships
  ## from the argument. Common nodes and relationships are included
  ## only once.
  result = Subgraph(nodes: s1.nodes + s2.nodes,
                    relations: s1.relations + s2.relations)

proc `*`*(s1, s2: Subgraph): Subgraph =
  ## Intersection of two subgraphs, consiting of all nodes and
  ## relationships common to both arguments.
  result = Subgraph(nodes: s1.nodes * s2.nodes,
                    relations: s1.relations * s2.relations)

proc `-`*(s1, s2: Subgraph): Subgraph =
  ## Difference of two subgraphs, consiting of nodes and relationships
  ## present in the first argument, but not in the
  ## second. Additionally, all nodes that are connected by the
  ## relationships in the result are present, regardless of whether
  ## they were present in the second argument.
  result = Subgraph(nodes: s1.nodes - s2.nodes,
                    relations: s1.relations - s2.relations)
  for r in result.relations:
    result.nodes.incl(r.startNode)
    result.nodes.incl(r.endNode)

proc `-+-`*(s1, s2: Subgraph): Subgraph =
  ## Symmetric difference of two subgraphs, consiting of of all nodes
  ## and relationships that exist in only one of the arguments, but
  ## not both. Additionally, all nodes that are connected by the
  ## relationships in the result are present, regardless of whether
  ## they were present in both of the argument.
  result = Subgraph(nodes: s1.nodes -+- s2.nodes,
                    relations: s1.relations -+- s2.relations)
  for r in result.relations:
    result.nodes.incl(r.startNode)
    result.nodes.incl(r.endNode)


# Routines for working with Subgraph properties

proc nodes*(obj: Subgraph): seq[Node] =
  ## Gets the set of nodes contained in this subgraph.
  result.newSeq(obj.nodes.len)
  var i = 0
  for node in obj.nodes:
    result[i] = node
    i.inc

proc relationships*(obj: Subgraph): seq[Relationship] =
  ## Gets the set of relationships contained in this subgraph
  result.newSeq(obj.relations.len)
  var i = 0
  for rel in obj.relations:
    result[i] = rel
    i.inc

proc order*(obj: Subgraph): int =
  ## Returns the number of nodes in a subgraph.
  result = obj.nodes.len

proc size*(obj: Subgraph): int =
  ## Returns the number of relationships in a subgraph.
  result = obj.relations.len

iterator keys*(obj: Subgraph): string =
  ## Yields each property key present in the nodes and relationships
  ## in this subgraph. Individual keys are yielded only once.
  var allKeys = initSet[string]()
  for n in obj.nodes:
    for k in n.toTable.keys:
      if not allKeys.containsOrIncl(k): yield k
  for r in obj.relations:
    for k in r.toTable.keys:
      if not allKeys.containsOrIncl(k): yield k

iterator labels*(obj: Subgraph): string =
  ## Yields each node label for the nodes in the subgraph. Individual
  ## label are yielded only once.
  var allLabels = initSet[string]()
  for n in obj.nodes:
    for lab in n.labels:
      if not allLabels.containsOrIncl(lab): yield lab

iterator reltypes*(obj: Subgraph): string =
  ## Yields each relationship type present in the subgraph. Individual
  ## types are yielded only once.
  var allTypes = initSet[string]()
  for r in obj.relations:
    if not allTypes.containsOrIncl(r.reltype): yield r.reltype


# Routines for building Nodes and Relationships

proc newNode*(labels: openArray[string],
              properties = initTable[string, Neo4jObject](1)): Node =
  ## Constructs a new node object with the labels and properties
  ## specified. In its initial state, a node is _unbound_. This means
  ## that it exists only on the client and does not reference a
  ## corresponding server node.
  new(result)
  result.labels = labels.toSet
  new(result.properties)
  result.properties[] = properties
  result.nodes.init(1)
  result.nodes.incl(result)
  result.relations.init(1)
  result.bound = false
  result.changed = true
  result.idNum = 1 #FIXME need some way to assign ID numbers

proc newNode*(label: string, properties = initTable[string,
              Neo4jObject](1)): Node =
  ## Equivalent to ``newNode([label], properties)``.
  result = newNode([label], properties)

proc newNode*(node: Neo4jValue, connection: ptr Connection): Node =
  ## Constructs a new node from a Neo4jValue object returned from a
  ## query made over the provided connection. This node will be bound
  ## to a corresponding server node.
  if node.`type` != NEO4J_NODE:
    raise newException(Neo4jTypeError, "Value not of type NEO4J_NODE")
  new(result)
  result.labels = node.nodeLabels.toNeo4jObject.toStringSeq.toSet
  new(result.properties)
  result.properties[] = node.nodeProperties.toNeo4jObject
  result.nodes.init(1)
  result.nodes.incl(result)
  result.relations.init(1)
  result.bound = true
  result.changed = false
  result.idNum = node.nodeIdentity.idNum
  result.connection = connection
  
const defaultReltype = "TO"
  
proc newRelationship*(startNode: Node, reltype: string, endNode: Node,
                      properties = initTable[string, Neo4jObject](1)): Relationship =
  ## Constructs a relationship of the specified type between a pair of
  ## nodes, with the specified properties.  In its initial state, a
  ## relationship is _unbound_. This means that it exists only on the
  ## client and does not reference a corresponding server
  ## relationship.
  new(result)
  result.reltype = reltype.toUpperAscii
  new(result.properties)
  result.properties[] = properties
  if startNode == endNode:
    result.nodes.init(1)
  else:
    result.nodes.init(2)
    result.nodes.incl(startNode)
  result.nodes.incl(endNode)
  result.relations.init(1)
  result.relations.incl(result)
  result.startNode = startNode
  result.endNode = endNode
  result.bound = false
  result.changed = true
  result.idNum = 1 #FIXME need some way to assign ID numbers

proc newRelationship*(startNode: Node, endNode: Node, properties =
                      initTable[string, Neo4jObject](1)): Relationship =
  ## Equivalent to ``newRelationship(startNode, 'TO', endNode, properties)``
  result = newRelationship(startNode, defaultReltype, endNode,
                           properties)

proc newRelationship*(node: Node, reltype: string, properties =
                      initTable[string, Neo4jObject](1)): Relationship =
  ## Constructs a loop relationship of the specfied type for the passed node
  ## nodes, with the specified properties.  In its initial state, a
  ## relationship is _unbound_. This means that it exists only on the
  ## client and does not reference a corresponding server
  ## relationship.
  result = newRelationship(node, reltype, node, properties)

proc newRelationship*(node: Node, properties =
                      initTable[string, Neo4jObject](1)): Relationship =
  ## Equivalent to ``newRelationship(startNode, 'TO', properties)``
  result = newRelationship(node, defaultReltype, node, properties)

proc newRelationship*(rel: Neo4jValue, connection: ptr Connection): Relationship =
  ## Constructs a new relationship from a Neo4jValue object returned
  ## from a query made over the provided connection. This relationship
  ## will be bound to a corresponding server relationship.
  if rel.`type` != NEO4J_RELATIONSHIP:
    raise newException(Neo4jTypeError, "Value not of type NEO4J_RELATIONSHIP")
  new(result)
  let
    reltype = rel.relationshipType
    startId = rel.relationshipStartNodeIdentity.idNum
    endId = rel.relationshipEndNodeIdentity.idNum
  var buf: array[256, char]
  result.reltype = $reltype.toString(buf, sizeof(buf))
  new(result.properties)
  result.properties[] = rel.relationshipProperties.toNeo4jObject
  if startId == endId:
    result.nodes.init(1)
  else:
    result.nodes.init(2)
    result.startNode = newNode(connection.getNode(startId), connection)
    result.nodes.incl(result.startNode)
  result.endNode = newNode(connection.getNode(startId), connection)
  result.nodes.incl(result.endNode)
  result.relations.init(1)
  result.relations.incl(result)
  result.bound = true
  result.changed = false
  result.idNum = rel.relationshipIdentity.idNum
  result.connection = connection


# Equality tests

proc `==`*(x, y: Node): bool =
  ## Tests for equality between two nodes based on whether they have
  ## the same hash. Node objects will only be equal if they are the
  ## same node; neither properties nor labels are considered.
  result = x.hash == y.hash

proc `==`*(x, y: Relationship): bool =
  ## Tests for equality between two relationships based on whether
  ## they have the same hash. Relationship objects will only be equal
  ## if they are the same relationship; neither relationship type or
  ## properties are considere.
  result = x.hash == y.hash


# Routines for working with Node properties

proc addLabel*(obj: var Node, label: string) =
  ## Add the label _label_ to the node.
  if obj.labels.containsOrIncl(label): obj.changed = true

proc addLabels*(obj: var Node, labels: HashSet[string]) =
  ## Add the set of labels to the node.
  for lab in labels:
    obj.addLabel(lab)

proc removeLabel*(obj: var Node, label: string) =
  ## Remove the label _label_ from the node if it exists.
  if label in obj.labels:
    obj.labels.excl(label)
    obj.changed = true

proc clearLabels*(obj: var Node) =
  ## Remove all labels from the node.
  if obj.labels.len > 0:
    obj.labels.clear()
    obj.changed = true

proc hasLabel*(obj: Node, label: string): bool {.inline.} =
  ## Returns ``true`` if the node has the label _label_.
  result = label in obj.labels

proc startNode*(obj: Node): Node {.inline.} =
  ## Returns the first node encounteder on a ``walk()`` of this
  ## object.
  result = obj

proc endNode*(obj: Node): Node {.inline.} =
  ## Returns the last node encountered on a ``walk()`` of this object.
  result = obj


# Routines for working with Relationship properties

proc reltype*(obj: Relationship): string {.inline.} =
  ## Returns the type of this relationship.
  result = obj.reltype

proc startNode*(obj: Relationship): Node {.inline.} =
  ## Returns the first node encounteder on a ``walk()`` of this
  ## object.
  result = obj.startNode

proc endNode*(obj: Relationship): Node {.inline.} =
  ## Returns the last node encountered on a ``walk()`` of this object.
  result = obj.endNode


# Methods for walkable types

type
  WalkableSubgraph* = ref object of Subgraph
    ## A subgraph with added traversal information. It can be
    ## traversed returning pairs of nodes and paths. The final
    ## relationship will always be ``nil``.
    relSequence: seq[Relationship]

proc hash*(obj: WalkableSubgraph): Hash =
  ## Produces a hash for a walkable subgraph based on the hashes of its
  ## ordered relationships.
  result = obj.relSequence.hash
  result = !$result

proc `$`*(obj: WalkableSubgraph): string =
  ## Represents the Walkable using Cypher.
  if obj.relSequence.len > 0:
    result = ""
  else:
    result = $obj.relSequence[0]
    var endNode = obj.relSequence[0].endNode
    for rel in obj.relSequence[1..^1]:
      let relString = cypherRelationship(rel.reltype, rel.properties)
      if rel.startNode == endNode:
        endNode = rel.endNode
        result &= '-' & relString & "->" & $endNode
      else:
        assert rel.endNode == endNode
        endNode = rel.startNode
        result &= "<-" & relString & "-" & $endNode

proc startNode*(obj: WalkableSubgraph): Node {.inline.} =
  ## Returns the first node encounteder on a ``walk()`` of this
  ## object.
  result = obj.relSequence[0].startNode

proc endNode*(obj: WalkableSubgraph): Node {.inline.} =
  ## Returns the last node encountered on a ``walk()`` of this object.
  result = obj.relSequence[^1].endNode

proc nodes*(obj: WalkableSubgraph): seq[Node] =
  ## Returns all nodes traversed by the Walkable, in the order
  ## traversed.
  result.newSeq(obj.relSequence.len + 1)
  for i, v in obj.relSequence:
    result[i] = v.startNode
  result[^1] = obj.endNode

proc relationships*(obj: WalkableSubgraph): seq[Relationship] =
  ## Returns all relationships traversed by the Walkable, in the order
  ## traversed.
  result = obj.relSequence


# A general walkable type class.

type
  Walkable* = concept x
    ## A more general form of traversable subgraph which includes node
    ## and relationship types.  It can be traversed returning an
    ## alternating sequence of nodes and paths. It always starts and
    ## ends with a node.
    x of Subgraph
    x.startNode is Node
    x.endNode is Node
    x.nodes is seq[Node]
    x.relationships is seq[Relationship]
    for p in walk(x):
      p is (Node, Relationship)
    $x is string

iterator walk*(obj: Node): (Node, Relationship) =
  ## Yield _obj_ as the only item in a ``walk()``. The relationship
  ## value in the pair will be ``nil``.
  yield (obj, nil)

iterator walk*(obj: Relationship): (Node, Relationship) =
  ## Yield the start node, the relationship, and the end node as the
  ## only items in a ``walk()``. The relationship value in the second
  ## pair will be ``nil``.
  yield (obj.startNode, obj)
  yield (obj.endNode, nil)

iterator walk*(obj: WalkableSubgraph): (Node, Relationship) =
  ## Traverse and yield pairs of nodes and relationships in this
  ## subgraph in order. The relationship value in the final pair will
  ## be ``nil``.
  for rel in obj.relSequence:
    yield (rel.startNode, rel)
  yield (obj.endNode, nil)

iterator walk*(walkables: varargs[Walkable]): (Node, Relationship) =
  ## Traverses over the arguments supplied, in order, yielding pairs
  ## of nodes and relationships. The relationship value in the final
  ## pair will be ``nil``.
  var
    endNode: Node
  for pair in walk(walkables[0]):
    if pair[1].isnil:
      endNode = pair[0]
    else:
      yield pair
  endNode = walkables[0].endNode
  for i in 1..<walkables.len:
    var walkable = walkables[i]
    if endNode == walkable.startNode:
      for pair in walk(walkable):
        if pair[1].isnil:
          endNode = pair[0]
        else:
          yield pair
    elif endNode == walkable.startNode:
      for pair in walkable.walk.toSeq.reversed:
        if pair[1].isnil:
          endNode = pair[0]
        else:
          yield pair
    else:
      raise newException(Neo4jTypeError, "Can not append walkable " &
                         "$1 to node $2" % [$walkable, $endNode])
  yield (endNode, nil)

proc `&`*(w1, w2: Walkable): WalkableSubgraph =
  ## Concatenate two walkable objects. Returns a new WalkableSubgraph
  ## that represents a walk of w1 folloed by w2. This is only possible
  ## if the end node of w1 is the same as either the start node or the
  ## end node of w2. In the latter case, w2 will be walked in
  ## reverse. Nodes that overlap from one operand onto another are not
  ## duplicated in the returned WalkableSubgraph.
  if w2.isnil:
    result = w1
  else:
    let
      rels1 = w1.relationships
      rels2 = w2.relationships
      endNode = w1.relationships[^1].endNode
    if endNode == rels2[0].startNode:
      result.relationships = rels1 & rels2
    elif endNode == rels2[^1].endNode:
      result.relSequence = rels1 & rels2.reversed
    else:
      raise newException(Neo4jTypeError, "Can not append walkable " &
                         "$1 to node $2" % [$w2, $endNode])
    result.nodes = w1.nodes + w2.nodes
    result.relationships = w1.relationships + w2.relationships
