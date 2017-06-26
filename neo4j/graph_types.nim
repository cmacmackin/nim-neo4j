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

import tables, sets, hashes, strutils
import wrapper, basic_types

type
  Subgraph* = ref object of RootObj
    nodes: HashSet[Node]
    relationships: HashSet[Relationship]

  Node* = ref object of Subgraph
    labels: HashSet[string]
    properties: TableRef[string, Neo4jObject]
    localId: int
    remoteId: Neo4jValue
    bound: bool
    changed: bool

  Relationship* = ref object of Subgraph
    reltype: string
    properties: TableRef[string, Neo4jObject]
    startNode: Node
    endNode: Node
    localId: int
    remoteId: Neo4jValue
    bound: bool
    changed: bool

converter toTable*(obj: Node): TableRef[string, Neo4jObject] =
  result = obj.properties

converter toTable*(obj: Relationship): TableRef[string, Neo4jObject] =
  result = obj.properties


# Routines for building Subgraphs

proc newSubgraph*(nodes: openarray[Node] = [],
                  relationships: openarray[Relationship] = []): Subgraph =
  result = Subgraph(nodes: nodes.toSet,
                    relationships: relationships.toSet)
  for r in result.relationships:
    result.nodes.incl(r.startNode)
    result.nodes.incl(r.endNode)

proc `+`*(s1, s2: Subgraph): Subgraph =
  ## Union of two subgraphs, consisting of all nodes and relationships
  ## from the argument. Common nodes and relationships are included
  ## only once.
  result = Subgraph(nodes: s1.nodes + s2.nodes,
                    relationships: s1.relationships + s2.relationships)

proc `*`*(s1, s2: Subgraph): Subgraph =
  ## Intersection of two subgraphs, consiting of all nodes and
  ## relationships common to both arguments.
  result = Subgraph(nodes: s1.nodes * s2.nodes,
                    relationships: s1.relationships * s2.relationships)

proc `-`*(s1, s2: Subgraph): Subgraph =
  ## Difference of two subgraphs, consiting of nodes and relationships
  ## present in the first argument, but not in the
  ## second. Additionally, all nodes that are connected by the
  ## relationships in the result are present, regardless of whether
  ## they were present in the second argument.
  result = Subgraph(nodes: s1.nodes - s2.nodes,
                    relationships: s1.relationships - s2.relationships)
  for r in result.relationships:
    result.nodes.incl(r.startNode)
    result.nodes.incl(r.endNode)

proc `-+-`*(s1, s2: Subgraph): Subgraph =
  ## Symmetric difference of two subgraphs, consiting of of all nodes
  ## and relationships that exist in only one of the arguments, but
  ## not both. Additionally, all nodes that are connected by the
  ## relationships in the result are present, regardless of whether
  ## they were present in both of the argument.
  result = Subgraph(nodes: s1.nodes -+- s2.nodes,
                    relationships: s1.relationships -+- s2.relationships)
  for r in result.relationships:
    result.nodes.incl(r.startNode)
    result.nodes.incl(r.endNode)


# Routines for working with Subgraph properties

proc nodes*(obj: Subgraph): HashSet[Node] =
  result = obj.nodes

proc relationships*(obj: Subgraph): HashSet[Relationship] =
  result = obj.relationships

iterator keys*(obj: Subgraph): string =
  ## Yields each property key present in the nodes and relationships
  ## in this subgraph. Individual keys are yielded only once.
  var allKeys = initSet[string]()
  for n in obj.nodes:
    for k in n.toTable.keys:
      if not allKeys.containsOrIncl(k): yield k
  for r in obj.relationships:
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
  for r in obj.relationships:
    if not allTypes.containsOrIncl(r.reltype): yield r.reltype


# Routines for building Nodes and Relationships

proc newNode*(labels: openArray[string],
              properties = initTable[string, Neo4jObject](1)): Node =
  new(result)
  result.labels = labels.toSet
  new(result.properties)
  result.properties[] = properties
  result.nodes.init(1)
  result.nodes.incl(result)
  result.relationships.init(1)
  result.bound = false
  result.changed = true
  result.localId = 1 #FIXME need some way to assign ID numbers

proc newNode*(label: string,
              properties = initTable[string, Neo4jObject](1)): Node =
  result = newNode([label], properties)

const defaultReltype = "TO"
  
proc newRelationship*(startNode: Node, reltype: string, endNode: Node,
                      properties = initTable[string,
                      Neo4jObject](1)): Relationship =
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
  result.relationships.init(1)
  result.relationships.incl(result)
  result.startNode = startNode
  result.endNode = endNode
  result.bound = false
  result.changed = true
  result.localId = 1 #FIXME need some way to assign ID numbers

proc newRelationship*(startNode: Node, endNode: Node, properties =
                      initTable[string, Neo4jObject](1)): Relationship =
  result = newRelationship(startNode, defaultReltype, endNode,
                           properties)

proc newRelationship*(node: Node, reltype: string, properties =
                      initTable[string, Neo4jObject](1)): Relationship =
  result = newRelationship(node, reltype, node, properties)

proc newRelationship*(node: Node, properties =
                      initTable[string, Neo4jObject](1)): Relationship =
  result = newRelationship(node, defaultReltype, node, properties)


# Routines to produce hashes for the graph elements, used when testing
# equality

proc hash(obj: Neo4jValue): Hash =
  result = (obj.vtOff.hash !& obj.`type`.hash !& obj.pad1.hash !&
            obj.pad2.hash !& obj.vdata.`int`.hash !&
            obj.vdata.`ptr`.hash !& obj.vdata.dbl.hash)
  result = !$result

proc hash*(obj: Node): Hash =
  result = obj.bound.hash
  if obj.bound:
    result = result !& obj.remoteId.hash
  else:
    result = result !& obj.localId.hash
  result = !$result

proc hash*(obj: Relationship): Hash =
  result = obj.bound.hash
  if obj.bound:
    result = result !& obj.remoteId.hash
  else:
    result = result !& obj.localId.hash
  result = !$result


# Equality tests

proc `==`*(x, y: Node): bool =
  result = x.hash == y.hash

proc `==`*(x, y: Relationship): bool =
  result = x.hash == y.hash


# Routines for working with Node properties

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

proc hasLabel*(obj: Node, label: string): bool {.inline.} =
  result = label in obj.labels


# Routines for working with Relationship properties

proc reltype*(obj: Relationship): string {.inline.} =
  result = obj.reltype

