# nim-neo4j

A Nim driver for the Neo4j graph database. Currently it just provides
a wrapper to
[libeneo4j-client](https://github.com/cleishm/libneo4j-client), but a
more sophisticated interface, modelled after
[Py2neo](http://py2neo.org/v3/index.html) will be developed on top of
this. 

## To Do

- [x] Clean up documentation in the wrapper to fit `nimdoc`
- [x] Refactor wrapped objects so no longer end in `T` suffix
- [ ] Write tests for the wrapper, based on those in [libneo4j-client](https://github.com/cleishm/libneo4j-client/tree/master/tests)
- [ ] Write basic equivalent of Py2neo [types](http://py2neo.org/v3/types.html) and [datbase](http://py2neo.org/v3/database.html) modules
- [ ] Write interface equivalent to that used in Nim for SQL databases
- [ ] Think whether there might be a more idiomatic way to implement this in Nim
- [ ] Write an OGM module, if possible in a compiled langauge
- [ ] Consider how a DSL could be used for queries
