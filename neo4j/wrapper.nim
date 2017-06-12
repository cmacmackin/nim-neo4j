#
#  neo4j/wrapper.nim
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

## A wrapper around the `libneo4j-client
## <https://github.com/cleishm/libneo4j-client>`_ C driver for the
## `Neo4j graph database <https://neo4j.com/>`_. While the wrapper has
## been written to make it as idiomatic as possible, the routines are
## not memory safe and are still awkward to use. It is recommended
## that you use the more advanced interfaces instead.


import posix

import errors

{.deadCodeElim: on.}
when defined(windows):
  const
    libneo4j* = "libneo4j-client.dll"
elif defined(macosx):
  const
    libneo4j* = "libneo4j-client.dylib"
else:
  const
    libneo4j* = "libneo4j-client.so"

when defined(windows):
  type
    cssize* = cint
else:
  type
    cssize* = clonglong

type
  Config* {.final, pure.} = object ## Configuration for neo4j client.

  Connection* {.final, pure.} = object ## A connection to a neo4j server.

  ResultStream* {.final, pure.} = object ## A stream of results from a job.

  JobResult* {.final, pure.} = object ## A result from a job.

  Neo4jType* {.final, pure, bycopy.} = uint8 ## A neo4j value type.

type
  PasswordCallback* = proc (userdata: pointer; buf: cstring; len: csize): cssize {.cdecl.}
    ## Function type for callback when a passwords is required.
    ## 
    ## Should copy the password into the supplied buffer, and return the
    ## actual length of the password.
    ## 
    ## userdata
    ##   The user data for the callback.
    ##
    ## buf
    ##   The buffer to copy the password into.
    ##
    ## len
    ##   The length of the buffer.
    ##
    ## Returns the length of the password as copied into the buffer.

  BasicAuthCallback* = proc (userdata: pointer; host: cstring; username: cstring;
                           usize: csize; password: cstring; psize: csize): cint {.cdecl.}
    ## Function type for callback when username and/or password is required.
    ## 
    ## Should update the ``NULL`` terminated strings in the ``username`` and/or
    ## ``password`` buffers.
    ## 
    ## userdata
    ##   The user data for the callback.
    ##
    ## host
    ##   The host description (typically "<hostname>:<port>").
    ##
    ## username
    ##   A buffer of size ``usize``, possibly containing a ``NULL``
    ##
    ##         terminated default username.
    ## usize
    ##   The size of the username buffer.
    ##
    ## password
    ##   A buffer of size ``psize``, possibly containing a ``NULL``
    ##
    ##         terminated default password.
    ## psize
    ##   The size of the password buffer.
    ##
    ## Returns 0 on success, -1 on error (errno should be set).

 
# =====================================
# version
# =====================================

proc libneo4jClientVersion*(): cstring {.cdecl, importc: "libneo4j_client_version",
                                         dynlib: libneo4j.}
  ## The version string for libneo4j-client.

proc libneo4jClientId*(): cstring {.cdecl, importc: "libneo4j_client_id",
                                    dynlib: libneo4j.}
  ## The default client ID string for libneo4j-client.

# =====================================
# init
# =====================================

proc clientInit*(): cint {.cdecl, importc: "neo4j_client_init", dynlib: libneo4j.}
  ## Initialize the neo4j client library.
  ## 
  ## This function should be invoked once per application including the neo4j
  ## client library.
  ## 
  ## Returns 0 on success, or -1 on error (errno will be set).

proc clientCleanup*(): cint {.cdecl, importc: "neo4j_client_cleanup", dynlib: libneo4j.}
  ## Cleanup after use of the neo4j client library.
  ## 
  ## Whilst it is not necessary to call this function, it can be useful
  ## for clearing any allocated memory when testing with tools such as valgrind.
  ## 
  ## Returns 0 on success, or -1 on error (errno will be set).


# =====================================
# logging
# =====================================

const
  NEO4J_LOG_ERROR* = 0
  NEO4J_LOG_WARN* = 1
  NEO4J_LOG_INFO* = 2
  NEO4J_LOG_DEBUG* = 3
  NEO4J_LOG_TRACE* = 4


type
  Logger* {.final, pure.} = object
    ## A logger for neo4j client.
    ##
    ## retain
    ##   Retain a reference to this logger.
    ##
    ## release
    ##   Release a reference to this logger. If all references have
    ##   been released, the logger will be deallocated.
    ##
    ## log
    ##   Write an entry to the log.
    ##
    ## isEnabled
    ##    Determine if a logging level is enabled for this logger.
    ##
    ## setLevel
    ##   Change the logging level for this logger.
    retain*: proc (self: ptr Logger): ptr Logger {.cdecl.}
    release*: proc (self: ptr Logger) {.cdecl.}
    log*: proc (self: ptr Logger; level: uint8; format: cstring) {.cdecl, varargs.}
    isEnabled*: proc (self: ptr Logger; level: uint8): bool {.cdecl.}
    setLevel*: proc (self: ptr Logger; level: uint8) {.cdecl.}

  LoggerProvider* {.final, pure.} = object
    ## A provider for a neo4j logger.
    ## Get a new logger for the provided name.
    ## 
    ## self
    ##   This provider.
    ##
    ## name
    ##   The name for the new logger.
    ##
    ## Returns a ``neo4j_logger``, or ``NULL`` on error (errno will be set).
    getLogger*: proc (self: ptr LoggerProvider; name: cstring): ptr Logger {.cdecl.}


const
  NEO4J_STD_LOGGER_DEFAULT* = 0
  NEO4J_STD_LOGGER_NO_PREFIX* = (1 shl 0)

proc stdLoggerProvider*(stream: File; level: uint8; flags: uint32): ptr LoggerProvider {.
    cdecl, importc: "neo4j_std_logger_provider", dynlib: libneo4j.}
  ## Obtain a standard logger provider.
  ## 
  ## The logger will output to the provided ``FILE``.
  ## 
  ## A bitmask of flags may be supplied, which may include:
  ##
  ## - NEO4J_STD_LOGGER_NO_PREFIX - don't output a prefix on each logline
  ## 
  ## If no flags are required, pass 0 or ``NEO4J_STD_LOGGER_DEFAULT``.
  ## 
  ## stream
  ##   The stream to output to.
  ##
  ## level
  ##   The default level to log at.
  ##
  ## flags
  ##   A bitmask of flags for the standard logger output.
  ##
  ## Returns a ``neo4j_logger_provider``, or ``NULL`` on error (errno will be set).
  
proc stdLoggerProviderFree*(provider: ptr LoggerProvider) {.cdecl,
    importc: "neo4j_std_logger_provider_free", dynlib: libneo4j.}
  ## Free a standard logger provider.
  ## 
  ## Provider must have been obtained via neo4j_std_logger_provider().
  ## 
  ## provider
  ##   The provider to free.
  ##

proc logLevelStr*(level: uint8): cstring {.cdecl, importc: "neo4j_log_level_str",
                                       dynlib: libneo4j.}
  ## The name for the logging level.
  ## 
  ## level
  ##   The logging level.
  ##
  ## Returns a ``NULL`` terminated ASCII string describing the logging level.


# =====================================
# I/O
# =====================================

type
  Iostream* {.final, pure.} = object
    ## An I/O stream for neo4j client.
    ##
    ## read
    ## ----
    ##
    ## Read bytes from a stream into the supplied buffer.
    ##
    ## self
    ##   This stream.
    ##
    ## buf
    ##   A pointer to a memory buffer to read into.
    ##
    ## nbyte
    ##   The size of the memory buffer.
    ##
    ## Returns the bytes read, or -1 on error (errno will be set).
    ##
    ##
    ## readv
    ## -----
    ##
    ## Read bytes from a stream into the supplied I/O vector.
    ##
    ## self
    ##   This stream.
    ##
    ## iov
    ##   A pointer to the I/O vector.
    ##
    ## iovcnt
    ##   The length of the I/O vector.
    ##
    ## Return the bytes read, or -1 on error (errno will be set).
    ##
    ##
    ## write
    ## -----
    ##
    ## Write bytes to a stream from the supplied buffer.
    ##
    ## self
    ##   This stream.
    ##
    ## buf
    ##   A pointer to a memory buffer to read from.
    ##
    ## nbyte
    ##   The size of the memory buffer.
    ##
    ## Return the bytes written, or -1 on error (errno will be set).
    ##
    ##
    ## writev
    ## ------
    ##
    ## Write bytes to a stream ifrom the supplied I/O vector.
    ##
    ## self
    ##   This stream.
    ##
    ## iov
    ##   A pointer to the I/O vector.
    ##
    ## iovcnt
    ##   The length of the I/O vector.
    ##
    ## Return the bytes written, or -1 on error (errno will be set).
    ##
    ##
    ## flush
    ## -----
    ##
    ## Flush the output buffer of the iostream. For unbuffered streams,
    ## this is a no-op.
    ##
    ## self
    ##   This stream.
    ##
    ## Return 0 on success, or -1 on error (errno will be set).
    ##
    ##
    ## close
    ## -----
    ##
    ## Close the stream. This function should close the stream and
    ## deallocate memory associated with it.
    ## 
    ## self
    ##   This stream.
    ##
    ## Return 0 on success, or -1 on error (errno will be set).
    ##
    read*: proc (self: ptr Iostream; buf: pointer; nbyte: csize): cssize {.cdecl.}
    readv*: proc (self: ptr Iostream; iov: ptr Iovec; iovcnt: cuint): cssize {.cdecl.}
    write*: proc (self: ptr Iostream; buf: pointer; nbyte: csize): cssize {.cdecl.}
    writev*: proc (self: ptr Iostream; iov: ptr Iovec; iovcnt: cuint): cssize {.cdecl.}
    flush*: proc (self: ptr Iostream): cint {.cdecl.}
    close*: proc (self: ptr Iostream): cint {.cdecl.}

  ConnectionFactory* {.final, pure.} = object
    ## A factory for establishing communications with neo4j.
    ##
    ## Establish a TCP connection.
    ## 
    ## self
    ##   This factory.
    ##
    ## hostname
    ##   The hostname to connect to.
    ##
    ## port
    ##   The TCP port number to connect to.
    ##
    ## config
    ##   The client configuration.
    ##
    ## flags
    ##   A bitmask of flags to control connections.
    ##
    ## logger
    ##   A logger that may be used for status logging.
    ##
    ## Returns a new `Iostream`, or ``NULL`` on error (errno will be set).
    ## 
    tcpConnect*: proc (self: ptr ConnectionFactory; hostname: cstring; port: cuint;
                     config: ptr Config; flags: uint32; logger: ptr Logger): ptr Iostream {.
                       cdecl.}
  

# =====================================
# error handling
# =====================================
const
  NEO4J_UNEXPECTED_ERROR* = - 10
  NEO4J_INVALID_URI* = - 11
  NEO4J_UNKNOWN_URI_SCHEME* = - 12
  NEO4J_UNKNOWN_HOST* = - 13
  NEO4J_PROTOCOL_NEGOTIATION_FAILED* = - 14
  NEO4J_INVALID_CREDENTIALS* = - 15
  NEO4J_CONNECTION_CLOSED* = - 16
  NEO4J_SESSION_FAILED* = - 19
  NEO4J_SESSION_ENDED* = - 20
  NEO4J_UNCLOSED_RESULT_STREAM* = - 21
  NEO4J_STATEMENT_EVALUATION_FAILED* = - 22
  NEO4J_STATEMENT_PREVIOUS_FAILURE* = - 23
  NEO4J_TLS_NOT_SUPPORTED* = - 24
  NEO4J_TLS_VERIFICATION_FAILED* = - 25
  NEO4J_NO_SERVER_TLS_SUPPORT* = - 26
  NEO4J_SERVER_REQUIRES_SECURE_CONNECTION* = - 27
  NEO4J_INVALID_MAP_KEY_TYPE* = - 28
  NEO4J_INVALID_LABEL_TYPE* = - 29
  NEO4J_INVALID_PATH_NODE_TYPE* = - 30
  NEO4J_INVALID_PATH_RELATIONSHIP_TYPE* = - 31
  NEO4J_INVALID_PATH_SEQUENCE_LENGTH* = - 32
  NEO4J_INVALID_PATH_SEQUENCE_IDX_TYPE* = - 33
  NEO4J_INVALID_PATH_SEQUENCE_IDX_RANGE* = - 34
  NEO4J_NO_PLAN_AVAILABLE* = - 35
  NEO4J_AUTH_RATE_LIMIT* = - 36
  NEO4J_TLS_MALFORMED_CERTIFICATE* = - 37
  NEO4J_SESSION_RESET* = - 38
  NEO4J_SESSION_BUSY* = - 39

proc perror*(stream: File; errnum: cint; message: cstring) {.cdecl,
    importc: "neo4j_perror", dynlib: libneo4j.}
  ## Print the error message corresponding to an error number.
  ## 
  ## stream
  ##   The stream to write to.
  ##
  ## errnum
  ##   The error number.
  ##
  ## message
  ##   ``NULL``, or a pointer to a message string which will
  ##   be prepend to the error message, separated by a colon and space.
  
proc strerror*(errnum: cint; buf: cstring; buflen: csize): cstring {.cdecl,
    importc: "neo4j_strerror", dynlib: libneo4j.}
  ## Look up the error message corresponding to an error number.
  ## 
  ## errnum
  ##   The error number.
  ##
  ## buf
  ##   A character buffer that may be used to hold the message.
  ##
  ## buflen
  ##   The length of the provided buffer.
  ##
  ## Returns a pointer to a character string containing the error message.


# =====================================
# memory
# =====================================

type
  MemoryAllocator* {.final, pure.} = object
    ## A memory allocator for neo4j client.
    ## 
    ## This will be used to allocate regions of memory as required by
    ## a connection, for buffers, etc.
    ##
    ## alloc
    ## -----
    ##
    ## Allocate memory from this allocator.
    ## 
    ## self
    ##   This allocator.
    ##
    ## context
    ##   An opaque 'context' for the allocation, which an
    ##   allocator may use to try an optimize storage as memory allocated
    ##   with the same context is likely (but not guaranteed) to be all
    ##   deallocated at the same time. Context may be ``NULL``, in which
    ##   case it does not offer any guidance on deallocation.
    ##
    ## size
    ##   The amount of memory (in bytes) to allocate.
    ##
    ## Returns a pointer to the allocated memory, or ``NULL`` on error
    ## (errno will be set).
    ##
    ##
    ## calloc
    ## ------
    ##
    ## Allocates contiguous space for multiple objects of the specified size,
    ## and fills the space with bytes of value zero.
    ## 
    ## self
    ##   This allocator.
    ##
    ## context
    ##   An opaque 'context' for the allocation, which an
    ##   allocator may use to try an optimize storage as memory allocated
    ##   with the same context is likely (but not guaranteed) to be all
    ##   deallocated at the same time. Context may be ``NULL``, in which
    ##   case it does not offer any guidance on deallocation.
    ##
    ## count
    ##   The number of objects to allocate.
    ##
    ## size
    ##   The size (in bytes) of each object.
    ##
    ## Returns a pointer to the allocated memory, or ``NULL`` on error
    ## (errno will be set).
    ## 
    ##
    ## free
    ## ----
    ##
    ## Return memory to this allocator.
    ## 
    ## self
    ##   This allocator.
    ##
    ## ptr
    ##   A pointer to the memory being returned.
    ##
    ##
    ## vfree
    ## -----
    ##
    ## Return multiple memory regions to this allocator.
    ## 
    ## self
    ##   This allocator.
    ##
    ## ptrs
    ##   An array of pointers to memory for returning.
    ##
    ## n
    ##   The length of the pointer array.
    ##
    alloc*: proc (self: ptr MemoryAllocator; context: pointer; size: csize): pointer {.
        cdecl.}
    calloc*: proc (self: ptr MemoryAllocator; context: pointer; count: csize;
                   size: csize): pointer {.cdecl.}
    free*: proc (self: ptr MemoryAllocator; `ptr`: pointer) {.cdecl.}
    vfree*: proc (self: ptr MemoryAllocator; ptrs: ptr pointer; n: csize) {.cdecl.}


# =====================================
# values
# =====================================

var NEO4J_NULL* {.importc: "NEO4J_NULL", dynlib: libneo4j.}: Neo4jType ## The neo4j null value type.

var NEO4J_BOOL* {.importc: "NEO4J_BOOL", dynlib: libneo4j.}: Neo4jType ## The neo4j boolean value type.

var NEO4J_INT* {.importc: "NEO4J_INT", dynlib: libneo4j.}: Neo4jType ## The neo4j integer value type.

var NEO4J_FLOAT* {.importc: "NEO4J_FLOAT", dynlib: libneo4j.}: Neo4jType ## The neo4j float value type.

var NEO4J_STRING* {.importc: "NEO4J_STRING", dynlib: libneo4j.}: Neo4jType ## The neo4j string value type.

var NEO4J_LIST* {.importc: "NEO4J_LIST", dynlib: libneo4j.}: Neo4jType ## The neo4j list value type.

var NEO4J_MAP* {.importc: "NEO4J_MAP", dynlib: libneo4j.}: Neo4jType ## The neo4j map value type.

var NEO4J_NODE* {.importc: "NEO4J_NODE", dynlib: libneo4j.}: Neo4jType ## The neo4j node value type.

var NEO4J_RELATIONSHIP* {.importc: "NEO4J_RELATIONSHIP", dynlib: libneo4j.}: Neo4jType ## The neo4j relationship value type.

var NEO4J_PATH* {.importc: "NEO4J_PATH", dynlib: libneo4j.}: Neo4jType ## The neo4j path value type.


var NEO4J_IDENTITY* {.importc: "NEO4J_IDENTITY", dynlib: libneo4j.}: Neo4jType ## The neo4j identity value type.

var NEO4J_STRUCT* {.importc: "NEO4J_STRUCT", dynlib: libneo4j.}: Neo4jType

type
  Neo4jValueData* {.union, final, pure.} = object
    int*: uint64
    `ptr`*: pointer
    dbl*: cdouble

  Neo4jValue* {.final, pure, bycopy.} = object
    vtOff*: uint8
    `type`*: uint8
    pad1*: uint16
    pad2*: uint32
    vdata*: Neo4jValueData


type
  MapEntry* {.final, pure.} = object
    ## An entry in a neo4j map.
    key*: Neo4jValue
    value*: Neo4jValue


#template `type`*(v: Neo4jValue): uint8 =
#  ## Get the type of a neo4j value.
#  ## 
#  ## value
#  ##   The neo4j v.
#  ##
#  ## Returns the type of the value.
#  v.`type`

proc instanceof*(value: Neo4jValue; `type`: Neo4jType): bool {.cdecl,
    importc: "neo4j_instanceof", dynlib: libneo4j.}
  ## Check the type of a neo4j value.
  ## 
  ## value
  ##   The neo4j value.
  ##
  ## type
  ##   The neo4j type.
  ##
  ## Returns ``true`` if the node is of the specified type and ``false`` otherwise.

proc typestr*(t: Neo4jType): cstring {.cdecl, importc: "neo4j_typestr", dynlib: libneo4j.}
  ## Get a string description of the neo4j type.
  ## 
  ## t
  ##   The neo4j type.
  ##
  ## Returns a pointer to a ``NULL`` terminated string containing the type name.

proc tostring*(value: Neo4jValue; strbuf: cstring; n: csize): cstring {.cdecl,
    importc: "neo4j_tostring", dynlib: libneo4j.}
  ## Get a string representation of a neo4j value.
  ## 
  ## Writes as much of the representation as possible into the buffer,
  ## ensuring it is always ``NULL`` terminated.
  ## 
  ## value
  ##   The neo4j value.
  ##
  ## strbuf
  ##   A buffer to write the string representation into.
  ##
  ## n
  ##   The length of the buffer.
  ##
  ## Returns a pointer to the provided buffer.

proc ntostring*(value: Neo4jValue; strbuf: cstring; n: csize): csize {.cdecl,
    importc: "neo4j_ntostring", dynlib: libneo4j.}
  ## Get a UTF-8 string representation of a neo4j value.
  ## 
  ## Writes as much of the representation as possible into the buffer,
  ## ensuring it is always ``NULL`` terminated.
  ## 
  ## value
  ##   The neo4j value.
  ##
  ## strbuf
  ##   A buffer to write the string representation into.
  ##
  ## n
  ##   The length of the buffer.
  ##
  ## Returns the number of bytes that would have been written into the buffer
  ##         had the buffer been large enough.

proc fprint*(value: Neo4jValue; stream: File): cssize {.cdecl, importc: "neo4j_fprint",
    dynlib: libneo4j.}
  ## Print a UTF-8 string representation of a neo4j value to a stream.
  ## 
  ## value
  ##   The neo4j value.
  ##
  ## stream
  ##   The stream to print to.
  ##
  ## Returns the number of bytes written to the stream, or -1 on error
  ##         (errno will be set).

proc `==`*(value1: Neo4jValue; value2: Neo4jValue): bool {.cdecl, importc: "neo4j_eq",
    dynlib: libneo4j.}
  ## Compare two neo4j values for equality.
  ## 
  ## value1
  ##   The first neo4j value.
  ##
  ## value2
  ##   The second neo4j value.
  ##
  ## Returns ``true`` if the two values are equivalent, ``false`` otherwise.

template isNull*(v: Neo4jValue): bool=
  ## Check if a neo4j value is the null value.
  ## 
  ## v
  ##   The neo4j value.
  ##
  ## Returns ``true`` if the value is the null value.
  (`type`(v) == NEO4J_NULL)

var null* {.importc: "neo4j_null", dynlib: libneo4j.}: Neo4jValue ## The neo4j null value.

proc newBool*(value: bool): Neo4jValue {.cdecl, importc: "neo4j_bool", dynlib: libneo4j.}
  ## Construct a neo4j value encoding a boolean.
  ## 
  ## value
  ##   A boolean value.
  ##
  ## Returns a neo4j value encoding the Bool.

proc toBool*(value: Neo4jValue): bool {.cdecl, importc: "neo4j_bool_value",
                                        dynlib: libneo4j.}
  ## Return the native boolean value from a neo4j boolean.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_BOOL.
  ## 
  ## value
  ##   The neo4j value
  ##
  ## Returns the native boolean true or false

proc newInt*(value: clonglong): Neo4jValue {.cdecl, importc: "neo4j_int", dynlib: libneo4j.}
  ## Construct a neo4j value encoding an integer.
  ## 
  ## value
  ##   A signed integer. This must be in the range INT64_MIN to
  ##
  ##         INT64_MAX, or it will be capped to the closest value.
  ## Returns a neo4j value encoding the Int.

proc toInt*(value: Neo4jValue): clonglong {.cdecl, importc: "neo4j_int_value",
                                               dynlib: libneo4j.}
  ## Return the native integer value from a neo4j int.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_INT.
  ## 
  ## value
  ##   The neo4j value
  ##
  ## Returns the native integer value
  
proc newFloat*(value: cdouble): Neo4jValue {.cdecl, importc: "neo4j_float",
                                             dynlib: libneo4j.}
  ## Construct a neo4j value encoding a double.
  ## 
  ## value
  ##   A double precision floating point value.
  ##
  ## Returns a neo4j value encoding the Float.
  
proc toFloat*(value: Neo4jValue): cdouble {.cdecl, importc: "neo4j_float_value",
                                               dynlib: libneo4j.}
  ## Return the native double value from a neo4j float.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_FLOAT.
  ## 
  ## value
  ##   The neo4j value
  ##
  ## Returns the native double value
  
template newString*(s: cstring): Neo4jValue =
  ## Construct a neo4j value encoding a string.
  ## 
  ## s
  ##   A pointer to a ``NULL`` terminated ASCII string. The pointer
  ##   must remain valid, and the content unchanged, for the lifetime of
  ##   the neo4j value.
  ##
  ## Returns a neo4j value encoding the String.
  ustring(s, s.len)

proc ustring*(u: cstring; n: cuint): Neo4jValue {.cdecl, importc: "neo4j_ustring",
                                                  dynlib: libneo4j.}
  ## Construct a neo4j value encoding a string.
  ## 
  ## u
  ##   A pointer to a UTF-8 string. The pointer must remain valid, and
  ##   the content unchanged, for the lifetime of the neo4j value.
  ##
  ## n
  ##   The length of the UTF-8 string. This must be less than
  ##   UINT32_MAX in length (and will be truncated otherwise).
  ##
  ## Returns a neo4j value encoding the String.

proc stringLength*(value: Neo4jValue): cuint {.cdecl, importc: "neo4j_string_length",
                                               dynlib: libneo4j.}
  ## Return the length of a neo4j UTF-8 string.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_STRING.
  ## 
  ## value
  ##   The neo4j string.
  ##
  ## Returns the length of the string in bytes.

proc toUstring*(value: Neo4jValue): cstring {.cdecl, importc: "neo4j_ustring_value",
                                              dynlib: libneo4j.}
  ## Return a pointer to a UTF-8 string.
  ## 
  ## The pointer will be to a UTF-8 string, and will NOT be `NULL` terminated.
  ## The length of the string, in bytes, can be obtained using
  ## neo4j_ustring_length(value).
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_STRING.
  ## 
  ## value
  ##   The neo4j string.
  ##
  ## Returns a pointer to a UTF-8 string, which will not be terminated.

proc toString*(value: Neo4jValue; buffer: cstring; length: csize): cstring {.cdecl,
    importc: "neo4j_string_value", dynlib: libneo4j.}
  ## Copy a neo4j string to a ``NULL`` terminated buffer.
  ## 
  ## As much of the string will be copied to the buffer as possible, and
  ## the result will be ``NULL`` terminated.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_STRING.
  ## 
  ## -- ATTENTION::
  ##    The content copied to the buffer may contain UTF-8 multi-byte
  ##    characters.
  ## 
  ## value
  ##   The neo4j string.
  ##
  ## buffer
  ##   A pointer to a buffer for storing the string. The pointer
  ##   must remain valid, and the content unchanged, for the lifetime of
  ##   the neo4j value.
  ##
  ## length
  ##   The length of the buffer.
  ##
  ## Returns a pointer to the supplied buffer.

proc newList*(items: ptr Neo4jValue; n: cuint): Neo4jValue {.cdecl, importc: "neo4j_list",
    dynlib: libneo4j.}
  ## Construct a neo4j value encoding a list.
  ## 
  ## items
  ##   An array of neo4j values. The pointer to the items must
  ##   remain valid, and the content unchanged, for the lifetime of the
  ##   neo4j value.
  ##
  ## n
  ##   The length of the array of items. This must be less than
  ##   UINT32_MAX (or the list will be truncated).
  ##
  ## Returns a neo4j value encoding the List.

proc listLen*(value: Neo4jValue): cuint {.cdecl, importc: "neo4j_list_length",
                                          dynlib: libneo4j.}
  ## Return the length of a neo4j list (number of entries).
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_LIST.
  ## 
  ## value
  ##   The neo4j list.
  ##
  ## Returns the number of entries.

proc `[]`*(value: Neo4jValue; index: cuint): Neo4jValue {.cdecl,
                                                          importc: "neo4j_list_get",
                                                          dynlib: libneo4j.}
  ## Return an element from a neo4j list.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_LIST.
  ## 
  ## value
  ##   The neo4j list.
  ##
  ## index
  ##   The index of the element to return.
  ##
  ## Returns a pointer to a ``neo4j_value_t`` element, or ``NULL`` if
  ## the index is beyond the end of the list.

proc newMap*(entries: ptr MapEntry; n: cuint): Neo4jValue {.cdecl, importc: "neo4j_map",
                                                          dynlib: libneo4j.}
  ## Construct a neo4j value encoding a map.
  ## 
  ## entries
  ##   An array of neo4j map entries. This pointer must remain
  ##   valid, and the content unchanged, for the lifetime of the neo4j
  ##   value.
  ##
  ## n
  ##   The length of the array of entries. This must be less than
  ##   UINT32_MAX (or the list of entries will be truncated).
  ##
  ## Returns a neo4j value encoding the Map.

proc mapLen*(value: Neo4jValue): cuint {.cdecl, importc: "neo4j_map_size",
                                      dynlib: libneo4j.}
  ## Return the size of a neo4j map (number of entries).
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_MAP.
  ## 
  ## value
  ##   The neo4j map.
  ##
  ## Returns the number of entries.

proc mapGetentry*(value: Neo4jValue; index: cuint): ptr MapEntry {.cdecl,
    importc: "neo4j_map_getentry", dynlib: libneo4j.}
  ## Return an entry from a neo4j map.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_MAP.
  ## 
  ## value
  ##   The neo4j map.
  ##
  ## index
  ##   The index of the entry to return.
  ##
  ## Returns the entry at the specified index, or ``NULL`` if the index
  ## is too large.


template `[]`*(value: Neo4jValue, key: cstring): Neo4jValue =
  ## Return a value from a neo4j map.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_MAP.
  ## 
  ## value
  ##   The neo4j map.
  ##
  ## key
  ##   The null terminated string key for the entry.
  ##
  ## Returns the value stored under the specified key, or ``NULL`` if the key is
  ## not known.
  mapKget(value, newString(key))

proc `[]`*(value: Neo4jValue; key: Neo4jValue): Neo4jValue {.cdecl,
                                                             importc: "neo4j_map_kget",
                                                             dynlib: libneo4j.}
  ## Return a value from a neo4j map.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_MAP.
  ## 
  ## value
  ##   The neo4j map.
  ##
  ## key
  ##   The map key.
  ##
  ## Returns the value stored under the specified key, or ``NULL`` if the key is
  ## not known.

template newMapEntry*(key: cstring, value: Neo4jValue): MapEntry =
  ## Constrct a neo4j map entry.
  ## 
  ## key
  ##   The null terminated string key for the entry.
  ##
  ## value
  ##   The value for the entry.
  ##
  ## Returns a neo4j map entry.
  mapKentry(newString(key), value)

proc mapKentry*(key: Neo4jValue; value: Neo4jValue): MapEntry {.cdecl,
    importc: "neo4j_map_kentry", dynlib: libneo4j.}
  ## Constrct a neo4j map entry using a value key.
  ## 
  ## The value key must be of type NEO4J_STRING.
  ## 
  ## key
  ##   The key for the entry.
  ##
  ## value
  ##   The value for the entry.
  ##
  ## Returns a neo4j map entry.

proc nodeLabels*(value: Neo4jValue): Neo4jValue {.cdecl, importc: "neo4j_node_labels",
                                                  dynlib: libneo4j.}
  ## Return the label list of a neo4j node.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_NODE.
  ## 
  ## value
  ##   The neo4j node.
  ##
  ## Returns a neo4j value encoding the List of labels.

proc nodeProperties*(value: Neo4jValue): Neo4jValue {.cdecl,
    importc: "neo4j_node_properties", dynlib: libneo4j.}
  ## Return the property map of a neo4j node.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_NODE.
  ## 
  ## value
  ##   The neo4j node.
  ##
  ## Returns a neo4j value encoding the Map of properties.

proc nodeIdentity*(value: Neo4jValue): Neo4jValue {.cdecl, importc: "neo4j_node_identity",
                                                    dynlib: libneo4j.}
  ## Return the identity of a neo4j node.
  ## 
  ## value
  ##   The neo4j node.
  ##
  ## Returns a neo4j value encoding the Identity of the node.

proc relationshipType*(value: Neo4jValue): Neo4jValue {.cdecl,
                                                        importc: "neo4j_relationship_type",
                                                        dynlib: libneo4j.}
  ## Return the type of a neo4j relationship.
  ## 
  ## Note that the result is undefined if the value is not of type
  ## NEO4J_RELATIONSHIP.
  ## 
  ## value
  ##   The neo4j node.
  ##
  ## Returns a neo4j value encoding the type as a String.

proc relationshipProperties*(value: Neo4jValue): Neo4jValue {.cdecl,
    importc: "neo4j_relationship_properties", dynlib: libneo4j.}
  ## Return the property map of a neo4j relationship.
  ## 
  ## Note that the result is undefined if the value is not of type
  ## NEO4J_RELATIONSHIP.
  ## 
  ## value
  ##   The neo4j relationship.
  ##
  ## Returns a neo4j value encoding the Map of properties.

proc relationshipIdentity*(value: Neo4jValue): Neo4jValue {.cdecl,
    importc: "neo4j_relationship_identity", dynlib: libneo4j.}
  ## Return the identity of a neo4j relationship.
  ## 
  ## value
  ##   The neo4j relationship.
  ##
  ## Returns a neo4j value encoding the Identity of the relationship.

proc relationshipStartNodeIdentity*(value: Neo4jValue): Neo4jValue {.cdecl,
    importc: "neo4j_relationship_start_node_identity", dynlib: libneo4j.}
  ## Return the start node identity for a neo4j relationship.
  ## 
  ## value
  ##   The neo4j relationship.
  ##
  ## Returns a neo4j value encoding the Identity of the start node.

proc relationshipEndNodeIdentity*(value: Neo4jValue): Neo4jValue {.cdecl,
    importc: "neo4j_relationship_end_node_identity", dynlib: libneo4j.}
  ## Return the end node identity for a neo4j relationship.
  ## 
  ## value
  ##   The neo4j relationship.
  ##
  ## Returns a neo4j value encoding the Identity of the end node.

proc pathLen*(value: Neo4jValue): cuint {.cdecl, importc: "neo4j_path_length",
                                          dynlib: libneo4j.}
  ## Return the length of a neo4j path.
  ## 
  ## The length of a path is defined by the number of relationships included in
  ## it.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_PATH.
  ## 
  ## value
  ##   The neo4j path.
  ##
  ## Returns the length of the path

proc pathGetNode*(value: Neo4jValue; hops: cuint): Neo4jValue {.cdecl,
    importc: "neo4j_path_get_node", dynlib: libneo4j.}
  ## Return the node at a given distance into the path.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_PATH.
  ## 
  ## value
  ##   The neo4j path.
  ##
  ## hops
  ##   The number of hops (distance).
  ##
  ## Returns a neo4j value enconding the Node.

proc pathGetRelationship*(value: Neo4jValue; hops: cuint;
                          forward: ptr bool): Neo4jValue {.cdecl,
    importc: "neo4j_path_get_relationship", dynlib: libneo4j.}
  ## Return the relationship for the given hop in the path.
  ## 
  ## Note that the result is undefined if the value is not of type NEO4J_PATH.
  ## 
  ## value
  ##   The neo4j path.
  ##
  ## hops
  ##   The number of hops (distance).
  ##
  ## forward
  ##   ``NULL``, or a pointer to a boolean which will be set to
  ##   ``true`` if the relationship was traversed in its natural direction
  ##   and ``false`` if it was traversed backward.
  ##
  ## Returns a neo4j value enconding the Relationship.

# =====================================
# config
# =====================================

proc newConfig*(): ptr Config {.cdecl, importc: "neo4j_new_config", dynlib: libneo4j.}
  ## Generate a new neo4j client configuration.
  ## 
  ## The returned configuration must be later released using
  ## neo4j_config_free().
  ## 
  ## Returns a pointer to a new neo4j client configuration, or ``NULL`` on error
  ## (errno will be set).

proc configFree*(config: ptr Config) {.cdecl, importc: "neo4j_config_free",
                                    dynlib: libneo4j.}
  ## Release a neo4j client configuration.
  ## 
  ## config
  ##   A pointer to a neo4j client configuration. This pointer will
  ##   be invalid after the function returns.

proc copy*(config: ptr Config): ptr Config {.cdecl, importc: "neo4j_config_dup",
    dynlib: libneo4j.}
  ## Duplicate a neo4j client configuration.
  ## 
  ## The returned configuration must be later released using
  ## neo4j_config_free().
  ## 
  ## config
  ##   A pointer to a neo4j client configuration.
  ##
  ## Returns a duplicate configuration.

proc `clientId=`*(config: ptr Config; clientId: cstring) {.cdecl,
    importc: "neo4j_config_set_client_id", dynlib: libneo4j.}
  ## Set the client ID.
  ## 
  ## The client ID will be used when identifying the client to neo4j.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## client_id
  ##   The client ID string. This string should remain allocated
  ##   whilst the config is allocated _or if any connections opened with
  ##   the config remain active_.

proc clientId*(config: ptr Config): cstring {.cdecl,
    importc: "neo4j_config_get_client_id", dynlib: libneo4j.}
  ## Get the client ID in the neo4j client configuration.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns a pointer to the client ID, or `NULL` if one is not set.
  
const
  NEO4J_MAXUSERNAMELEN* = 1023

proc setUsername(config: ptr Config; username: cstring): cint {.cdecl,
    importc: "neo4j_config_set_username", dynlib: libneo4j.}
  ## Set the username in the neo4j client configuration.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## username
  ##   The username to authenticate with. The string will be
  ##   duplicated, and thus may point to temporary memory.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc `username=`*(config: ptr Config; username: string) =
  ## Set the username in the neo4j client configuration.
  let err = setUsername(config, username)
  if err == -1:
    var buf: array[1024, char]
    raise newException(Neo4jConfigError, $strerror(errno, buf, sizeof(buf)))

proc username*(config: ptr Config): cstring {.cdecl,
    importc: "neo4j_config_get_username", dynlib: libneo4j.}
  ## Get the username in the neo4j client configuration.
  ## 
  ## The returned username will only be valid whilst the configuration is
  ## unchanged.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns a pointer to the username, or `NULL` if one is not set.

const
  NEO4J_MAXPASSWORDLEN* = 1023

proc setPassword(config: ptr Config; password: cstring): cint {.cdecl,
    importc: "neo4j_config_set_password", dynlib: libneo4j.}
  ## Set the password in the neo4j client configuration.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## password
  ##   The password to authenticate with. The string will be
  ##   duplicated, and thus may point to temporary memory.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc `password=`*(config: ptr Config; password: string) =
  ## Set the password in the neo4j client configuration.
  let err = setPassword(config, password)
  if err == -1:
    var buf: array[1024, char]
    raise newException(Neo4jConfigError, $strerror(errno, buf, sizeof(buf)))

proc setBasicAuthCallback*(config: ptr Config; callback: BasicAuthCallback;
                                userdata: pointer): cint {.cdecl,
    importc: "neo4j_config_set_basic_auth_callback", dynlib: libneo4j.}
  ## Set the basic authentication callback.
  ## 
  ## If a username and/or password is required for basic authentication and
  ## isn't available in the configuration or connection URI, then this callback
  ## will be invoked to obtain the username and/or password.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## callback
  ##   The callback to be invoked.
  ##
  ## userdata
  ##   User data that will be supplied to the callback.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc setTlsPrivateKey(config: ptr Config; path: cstring): cint {.cdecl,
    importc: "neo4j_config_set_TLS_private_key", dynlib: libneo4j.}
  ## Set the location of a TLS private key and certificate chain.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## path
  ##   The path to the PEM file containing the private key
  ##   and certificate chain. This string should remain allocated whilst
  ##   the config is allocated *or if any connections opened with the
  ##   config remain active*.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc `tlsPrivateKey=`*(config: ptr Config; path: string) =
  ## Set the location of a TLS private key and certificate chain.
  ## This string should remain allocated whilst the config is
  ## allocated *or if any connections opened with the config remain
  ## active*.
  let err = setTlsPrivateKey(config, path)
  if err == -1:
    var buf: array[1024, char]
    raise newException(Neo4jConfigError, $strerror(errno, buf, sizeof(buf)))

proc tlsPrivateKey*(config: ptr Config): cstring {.cdecl,
    importc: "neo4j_config_get_TLS_private_key", dynlib: libneo4j.}
  ## Obtain the path to the TLS private key and certificate chain.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns the path set in the config, or `NULL` if none.

proc setTlsPrivateKeyPasswordCallback*(config: ptr Config;
    callback: PasswordCallback; userdata: pointer): cint {.cdecl,
    importc: "neo4j_config_set_TLS_private_key_password_callback",
    dynlib: libneo4j.}
  ## Set the password callback for the TLS private key file.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## callback
  ##   The callback to be invoked whenever a password for
  ##   the certificate file is required.
  ##
  ## userdata
  ##   User data that will be supplied to the callback.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc setTlsPrivateKeyPassword(config: ptr Config; password: cstring): cint {.
    cdecl, importc: "neo4j_config_set_TLS_private_key_password", dynlib: libneo4j.}
  ## Set the password for the TLS private key file.
  ## 
  ## This is a simpler alternative to using
  ## setTlsPrivateKeyPasswordCallback()
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## password
  ##   The password for the certificate file. This string should
  ##   remain allocated whilst the config is allocated *or if any
  ##   connections opened with the config remain active*.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc `tlsPrivateKeyPassword=`*(config: ptr Config; password: string) =
  ## Set the password for the TLS private key file. This is a simpler
  ## alternative to using setTlsPrivateKeyPasswordCallback(). This
  ## string should remain allocated whilst the config is allocated *or
  ## if any connections opened with the config remain active*.
  let err = setTlsPrivateKeyPassword(config, password)
  if err == -1:
    var buf: array[1024, char]
    raise newException(Neo4jConfigError, $strerror(errno, buf, sizeof(buf)))

proc setTlsCaFile(config: ptr Config; path: cstring): cint {.cdecl,
    importc: "neo4j_config_set_TLS_ca_file", dynlib: libneo4j.}
  ## Set the location of a file containing TLS certificate authorities (and CRLs).
  ## 
  ## The file should contain the certificates of the trusted CAs and CRLs. The
  ## file must be in base64 privacy enhanced mail (PEM) format.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## path
  ##   The path to the PEM file containing the trusted CAs and CRLs.
  ##   This string should remain allocated whilst the config is allocated
  ##   *or if any connections opened with the config remain active*.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc `tlsCaFile=`*(config: ptr Config; path: string) =
  ## Set the location of a file containing TLS certificate authorities
  ## (and CRLs).  The file should contain the certificates of the
  ## trusted CAs and CRLs. The file must be in base64 privacy enhanced
  ## mail (PEM) format. This string should remain allocated whilst the
  ## config is allocated *or if any connections opened with the config
  ## remain active*.
  let err = setTlsCaFile(config, path)
  if err == -1:
    var buf: array[1024, char]
    raise newException(Neo4jConfigError, $strerror(errno, buf, sizeof(buf)))

proc tlsCaFile*(config: ptr Config): cstring {.cdecl,
    importc: "neo4j_config_get_TLS_ca_file", dynlib: libneo4j.}
  ## Obtain the path to the TLS certificate authority file.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns the path set in the config, or ``NULL`` if none.

proc setTlsCaDir(config: ptr Config; path: cstring): cint {.cdecl,
    importc: "neo4j_config_set_TLS_ca_dir", dynlib: libneo4j.}
  ## Set the location of a directory of TLS certificate authorities (and CRLs).
  ## 
  ## The specified directory should contain the certificates of the trusted CAs
  ## and CRLs, named by hash according to the ``c_rehash`` tool.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## path
  ##   The path to the directory of CAs and CRLs. This string should
  ##   remain allocated whilst the config is allocated *or if any
  ##   connections opened with the config remain active*.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc `tlsCaDir=`*(config: ptr Config; path: string) =
  ## Set the location of a directory of TLS certificate authorities
  ## (and CRLs).  The specified directory should contain the
  ## certificates of the trusted CAs and CRLs, named by hash according
  ## to the ``c_rehash`` tool.  This string should remain allocated
  ## whilst the config is allocated *or if any connections opened with
  ## the config remain active*.
  let err = setTlsCaDir(config, path)
  if err == -1:
    var buf: array[1024, char]
    raise newException(Neo4jConfigError, $strerror(errno, buf, sizeof(buf)))

proc tlsCaDir*(config: ptr Config): cstring {.cdecl,
    importc: "neo4j_config_get_TLS_ca_dir", dynlib: libneo4j.}
  ## Obtain the path to the TLS certificate authority directory.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns the path set in the config, or ``NULL`` if none.

proc setTrustKnownHosts(config: ptr Config; enable: bool): cint {.cdecl,
    importc: "neo4j_config_set_trust_known_hosts", dynlib: libneo4j.}
  ## Enable or disable trusting of known hosts.
  ## 
  ## When enabled, the neo4j client will check if a host has been previously
  ## trusted and stored into the "known hosts" file, and that the host
  ## fingerprint still matches the previously accepted value. This is enabled by
  ## default.
  ## 
  ## If verification fails, the callback set with
  ## neo4j_config_set_unverified_host_callback() will be invoked.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## enable
  ##   ``true`` to enable trusting of known hosts, and ``false`` to
  ##   disable this behaviour.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc `trustKnownHosts=`*(config: ptr Config; enable: bool) =
  ## Enable or disable trusting of known hosts.  When enabled, the
  ## neo4j client will check if a host has been previously trusted and
  ## stored into the "known hosts" file, and that the host fingerprint
  ## still matches the previously accepted value. This is enabled by
  ## default.
  let err = setTrustKnownHosts(config, enable)
  if err == -1:
    var buf: array[1024, char]
    raise newException(Neo4jConfigError, $strerror(errno, buf, sizeof(buf)))

proc trustKnownHosts*(config: ptr Config): bool {.cdecl,
    importc: "neo4j_config_get_trust_known_hosts", dynlib: libneo4j.}
  ## Check if trusting of known hosts is enabled.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns ``true`` if enabled and ``false`` otherwise.

proc setKnownHostsFile(config: ptr Config; path: cstring): cint {.cdecl,
    importc: "neo4j_config_set_known_hosts_file", dynlib: libneo4j.}
  ## Set the location of the known hosts file for TLS certificates.
  ## 
  ## The file, which will be created and maintained by neo4j client,
  ## will be used for storing trust information when using "Trust On First Use".
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## path
  ##   The path to known hosts file. This string should
  ##   remain allocated whilst the config is allocated *or if any
  ##   connections opened with the config remain active*.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc `knownHostsFile=`*(config: ptr Config; path: string) =
  ## Set the location of the known hosts file for TLS certificates.
  ## 
  ## The file, which will be created and maintained by neo4j client,
  ## will be used for storing trust information when using "Trust On
  ## First Use". This string should remain allocated whilst the
  ## config is allocated *or if any connections opened with the config
  ## remain active*.
  let err = setKnownHostsFile(config, path)
  if err == -1:
    var buf: array[1024, char]
    raise newException(Neo4jConfigError, $strerror(errno, buf, sizeof(buf)))

proc knownHostsFile*(config: ptr Config): cstring {.cdecl,
    importc: "neo4j_config_get_known_hosts_file", dynlib: libneo4j.}
  ## Obtain the path to the known hosts file.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns the path set in the config, or `NULL` if none.

type
  UnverifiedHostReason* {.size: sizeof(cint).} = enum
    NEO4J_HOST_VERIFICATION_UNRECOGNIZED, NEO4J_HOST_VERIFICATION_MISMATCH

const
  NEO4J_HOST_VERIFICATION_REJECT* = 0
  NEO4J_HOST_VERIFICATION_ACCEPT_ONCE* = 1
  NEO4J_HOST_VERIFICATION_TRUST* = 2

type
  ## Function type for callback when host verification has failed.
  ## 
  ## userdata
  ##   The user data for the callback.
  ##
  ## host
  ##   The host description (typically "<hostname>:<port>").
  ##
  ## fingerprint
  ##   The fingerprint for the host.
  ##
  ## reason
  ##   The reason for the verification failure, which will be
  ##   either ``NEO4J_HOST_VERIFICATION_UNRECOGNIZED`` or
  ##   ``NEO4J_HOST_VERIFICATION_MISMATCH``.
  ##
  ## Returns ``NEO4J_HOST_VERIFICATION_REJECT`` if the host should be
  ## rejected, ``NEO4J_HOST_VERIFICATION_ACCEPT_ONCE`` if the host should
  ## be accepted for just the one connection,
  ## ``NEO4J_HOST_VERIFICATION_TRUST`` if the fingerprint should be stored
  ## in the "known hosts" file and thus trusted for future connections,
  ## or -1 on error (errno should be set).
  UnverifiedHostCallback* = proc (userdata: pointer; host: cstring;
                                fingerprint: cstring;
                                reason: UnverifiedHostReason): cint {.cdecl.}

proc setUnverifiedHostCallback*(config: ptr Config;
                                callback: UnverifiedHostCallback;
                                userdata: pointer): cint {.cdecl,
    importc: "neo4j_config_set_unverified_host_callback", dynlib: libneo4j.}
  ## Set the unverified host callback.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## callback
  ##   The callback to be invoked whenever a host verification fails.
  ##
  ## userdata
  ##   User data that will be supplied to the callback.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc setSndbufSize(config: ptr Config; size: csize): cint {.cdecl,
    importc: "neo4j_config_set_sndbuf_size", dynlib: libneo4j.}
  ## Set the I/O output buffer size.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## size
  ##   The I/O output buffer size.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc `sndbufSize=`*(config: ptr Config; size: csize) =
  ## Set the I/O output buffer size.
  let err = setSndbufSize(config, size)
  if err == -1:
    var buf: array[1024, char]
    raise newException(Neo4jConfigError, $strerror(errno, buf, sizeof(buf)))

proc sndbufSize*(config: ptr Config): csize {.cdecl,
    importc: "neo4j_config_get_sndbuf_size", dynlib: libneo4j.}
  ## Get the size for the I/O output buffer.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns the sndbuf size.

proc setRcvbufSize(config: ptr Config; size: csize): cint {.cdecl,
    importc: "neo4j_config_set_rcvbuf_size", dynlib: libneo4j.}
  ## Set the I/O input buffer size.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## size
  ##   The I/O input buffer size.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc `rcvbufSize=`*(config: ptr Config; size: csize) =
  ## Set the I/O input buffer size.
  let err = setRcvbufSize(config, size)
  if err == -1:
    var buf: array[1024, char]
    raise newException(Neo4jConfigError, $strerror(errno, buf, sizeof(buf)))

proc rcvbufSize*(config: ptr Config): csize {.cdecl,
    importc: "neo4j_config_get_rcvbuf_size", dynlib: libneo4j.}
  ## Get the size for the I/O input buffer.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns the rcvbuf size.

proc `loggerProvider=`*(config: ptr Config;
                             loggerProvider: ptr LoggerProvider) {.cdecl,
    importc: "neo4j_config_set_logger_provider", dynlib: libneo4j.}
  ## Set a logger provider in the neo4j client configuration.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## logger_provider
  ##   The logger provider function.
  ##

proc setSoSndbufSize(config: ptr Config; size: cuint): cint {.cdecl,
    importc: "neo4j_config_set_so_sndbuf_size", dynlib: libneo4j.}
  ## Set the socket send buffer size.
  ## 
  ## This is only applicable to the standard connection factory.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## size
  ##   The socket send buffer size, or 0 to use the system default.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc `soSndbufSize=`*(config: ptr Config; size: cuint) =
  ## Set the socket send buffer size. 0 indicates the system default.
  let err = setSoSndbufSize(config, size)
  if err == -1:
    var buf: array[1024, char]
    raise newException(Neo4jConfigError, $strerror(errno, buf, sizeof(buf)))

proc soSndbufSize*(config: ptr Config): cuint {.cdecl,
    importc: "neo4j_config_get_so_sndbuf_size", dynlib: libneo4j.}
  ## Get the size for the socket send buffer.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns the so_sndbuf size.

proc setSoRcvbufSize(config: ptr Config; size: cuint): cint {.cdecl,
    importc: "neo4j_config_set_so_rcvbuf_size", dynlib: libneo4j.}
  ## Set the socket receive buffer size.
  ## 
  ## This is only applicable to the standard connection factory.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## size
  ##   The socket receive buffer size, or 0 to use the system default.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc `soRcvbufSize=`*(config: ptr Config; size: cuint) =
  ## Set the socket receive buffer size. 0 indicates the system default.
  let err = setSoRcvbufSize(config, size)
  if err == -1:
    var buf: array[1024, char]
    raise newException(Neo4jConfigError, $strerror(errno, buf, sizeof(buf)))

proc soRcvbufSize*(config: ptr Config): cuint {.cdecl,
    importc: "neo4j_config_get_so_rcvbuf_size", dynlib: libneo4j.}
  ## Get the size for the socket receive buffer.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns the so_rcvbuf size.

proc `connectionFactory=`*(config: ptr Config; factory: ptr ConnectionFactory) {.
    cdecl, importc: "neo4j_config_set_connection_factory", dynlib: libneo4j.}
  ## Set a connection factory.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## factory
  ##   The connection factory.
  ##

var stdConnectionFactory* {.importc: "neo4j_std_connection_factory",
                          dynlib: libneo4j.}: ConnectionFactory
  ## The standard connection factory.

var stdMemoryAllocator* {.importc: "neo4j_std_memory_allocator", dynlib: libneo4j.}: MemoryAllocator ## The standard memory allocator. This memory allocator delegates to the system malloc/free functions.

proc `memoryAllocator=`*(config: ptr Config; allocator: ptr MemoryAllocator) {.
    cdecl, importc: "neo4j_config_set_memory_allocator", dynlib: libneo4j.}
  ## Set a memory allocator.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## allocator
  ##   The memory allocator.
  ##

proc memoryAllocator*(config: ptr Config): ptr MemoryAllocator {.cdecl,
    importc: "neo4j_config_get_memory_allocator", dynlib: libneo4j.}
  ## Get the memory allocator.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns the memory allocator.

proc `maxPipelinedRequests=`*(config: ptr Config; n: cuint) {.cdecl,
    importc: "neo4j_config_set_max_pipelined_requests", dynlib: libneo4j.}
  ## Set the maximum number of requests that can be pipelined to the
  ## server.
  ## 
  ## .. ATTENTION::Setting this value too high could result in deadlocking within
  ##    the client, as the client will block when trying to send statements
  ##    to a server with a full queue, instead of reading results that would drain
  ##    the queue.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## n
  ##   The new maximum.
  ##

proc maxPipelinedRequests*(config: ptr Config): cuint {.cdecl,
    importc: "neo4j_config_get_max_pipelined_requests", dynlib: libneo4j.}
  ## Get the maximum number of requests that can be pipelined to the server.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns the number of requests that can be pipelined.

proc dotDir*(buffer: cstring; n: csize; append: cstring): cssize {.cdecl,
    importc: "neo4j_dot_dir", dynlib: libneo4j.}
  ## Return a path within the neo4j dot directory.
  ## 
  ## The neo4j dot directory is typically ".neo4j" within the users home
  ## directory. If append is ``NULL``, then an absoulte path to the home
  ## directory is placed into buffer.
  ## 
  ## buffer
  ##   The buffer in which to place the path, which will be
  ##   null terminated. If the buffer is ``NULL``, then the function
  ##   will still return the length of the path it would have placed
  ##   into the buffer.
  ##
  ## n
  ##   The size of the buffer. If the path is too large to place
  ##   into the buffer (including the terminating '\0' character),
  ##   an ``ERANGE`` error will result.
  ##
  ## append
  ##   The relative path to append to the dot directory, which
  ##   may be ``NULL``.
  ##
  ## Returns the length of the resulting path (not including the null
  ## terminating character), or -1 on error (errno will be set).

# =====================================
# connection
# =====================================

const
  NEO4J_DEFAULT_TCP_PORT* = 7687
  NEO4J_CONNECT_DEFAULT* = 0
  NEO4J_INSECURE* = (1 shl 0)
  NEO4J_NO_URI_CREDENTIALS* = (1 shl 1)
  NEO4J_NO_URI_PASSWORD* = (1 shl 2)

proc connect*(uri: cstring; config: ptr Config; flags: uint32): ptr Connection {.cdecl,
    importc: "neo4j_connect", dynlib: libneo4j.}
  ## Establish a connection to a neo4j server.
  ## 
  ## A bitmask of flags may be supplied, which may include:
  ## - NEO4J_INSECURE - do not attempt to establish a secure connection. If a
  ##   secure connection is required, then connect will fail with errno set to
  ##   ``NEO4J_SERVER_REQUIRES_SECURE_CONNECTION``.
  ## - NEO4J_NO_URI_CREDENTIALS - do not use credentials provided in the
  ##   server URI (use credentials from the configuration instead).
  ## - NEO4J_NO_URI_PASSWORD - do not use any password provided in the
  ##   server URI (obtain password from the configuration instead).
  ## 
  ## If no flags are required, pass 0 or ``NEO4J_CONNECT_DEFAULT``.
  ## 
  ## uri
  ##   A URI describing the server to connect to, which may also
  ##   include authentication data (which will override any provided
  ##   in the config).
  ##
  ## config
  ##   The neo4j client configuration to use for this connection.
  ##
  ## flags
  ##   A bitmask of flags to control connections.
  ##
  ## Returns a pointer to a ``neo4j_connection_t`` structure, or ``NULL`` on error
  ## (errno will be set).

proc tcpConnect*(hostname: cstring; port: cuint; config: ptr Config;
                 flags: uint32): ptr Connection {.cdecl,
                                                  importc: "neo4j_tcp_connect",
                                                  dynlib: libneo4j.}
  ## Establish a connection to a neo4j server.
  ## 
  ## A bitmask of flags may be supplied, which may include:
  ##
  ## - NEO4J_INSECURE - do not attempt to establish a secure connection. If a
  ##   secure connection is required, then connect will fail with errno set to
  ##   ``NEO4J_SERVER_REQUIRES_SECURE_CONNECTION``.
  ## 
  ## If no flags are required, pass 0 or ``NEO4J_CONNECT_DEFAULT``.
  ## 
  ## hostname
  ##   The hostname to connect to.
  ##
  ## port
  ##   The port to connect to.
  ##
  ## config
  ##   The neo4j client configuration to use for this connection.
  ##
  ## flags
  ##   A bitmask of flags to control connections.
  ##
  ## Returns a pointer to a ``neo4j_connection_t`` structure, or ``NULL``
  ## on error (errno will be set).

proc close*(connection: ptr Connection): cint {.cdecl, importc: "neo4j_close",
    dynlib: libneo4j.}
  ## Close a connection to a neo4j server.
  ## 
  ## connection
  ##   The connection to close. This pointer will be invalid
  ##   after the function returns.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc hostname*(connection: ptr Connection): cstring {.cdecl,
    importc: "neo4j_connection_hostname", dynlib: libneo4j.}
  ## Get the hostname for a connection.
  ## 
  ## connection
  ##   The neo4j connection.
  ##
  ## Returns a pointer to a hostname string, which will remain valid
  ## only whilst the connection remains open.

proc port*(connection: ptr Connection): cuint {.cdecl,
    importc: "neo4j_connection_port", dynlib: libneo4j.}
  ## Get the port for a connection.
  ## 
  ## connection
  ##   The neo4j connection.
  ##
  ## Returns the port of the connection.

proc username*(connection: ptr Connection): cstring {.cdecl,
    importc: "neo4j_connection_username", dynlib: libneo4j.}
  ## Get the username for a connection.
  ## 
  ## connection
  ##   The neo4j connection.
  ##
  ## Returns a pointer to a username string, which will remain valid
  ## only whilst the connection remains open, or ``NULL`` if no username
  ## was associated with the connection.

proc connectionIsSecure*(connection: ptr Connection): bool {.cdecl,
    importc: "neo4j_connection_is_secure", dynlib: libneo4j.}
  ## Check if a given connection uses TLS.
  ## 
  ## connection
  ##   The neo4j connection.
  ##
  ## Returns ``true`` if the connection was established over TLS, and ``false``
  ## otherwise.

# =====================================
# session
# =====================================

proc reset*(connection: ptr Connection): cint {.cdecl, importc: "neo4j_reset",
    dynlib: libneo4j.}
  ## Reset a session.
  ## 
  ## Invoking this function causes all server-held state for the connection to be
  ## cleared, including rolling back any open transactions, and causes any
  ## existing result stream to be terminated.
  ## 
  ## connection
  ##   The connection to reset.
  ##
  ## Returns 0 on sucess, or -1 on error (errno will be set).

proc credentialsExpired*(connection: ptr Connection): bool {.cdecl,
    importc: "neo4j_credentials_expired", dynlib: libneo4j.}
  ## Check if the server indicated that credentials have expired.
  ## 
  ## connection
  ##   The connection.
  ##
  ## Returns ``true`` if the server indicated that credentials have expired,
  ## and ``false`` otherwise.

proc serverId*(connection: ptr Connection): cstring {.cdecl,
    importc: "neo4j_server_id", dynlib: libneo4j.}
  ## Get the server ID string.
  ## 
  ## connection
  ##   The connection.
  ##
  ## Returns the server ID string, or ``NULL`` if none was available.

# =====================================
# job
# =====================================

proc run*(connection: ptr Connection; statement: cstring;
          params: Neo4jValue): ptr ResultStream {.cdecl,
                                                  importc: "neo4j_run",
                                                  dynlib: libneo4j.}
  ## Evaluate a statement.
  ## 
  ## .. attention:: The statement and the params must remain valid until the returned
  ##    result stream is closed.
  ## 
  ## connection
  ##   The connection.
  ##
  ## statement
  ##   The statement to be evaluated. This must be a ``NULL``
  ##   terminated string and may contain UTF-8 multi-byte characters.
  ##
  ## params
  ##   The parameters for the statement, which must be a value of
  ##   type NEO4J_MAP or #neo4j_null.
  ##
  ## Returns a ``neo4j_result_stream_t``, or ``NULL`` on error (errno will be set).

proc send*(connection: ptr Connection; statement: cstring;
           params: Neo4jValue): ptr ResultStream {.cdecl,
                                                   importc: "neo4j_send",
                                                   dynlib: libneo4j.}
  ## Evaluate a statement, ignoring any results.
  ## 
  ## The ``neo4j_result_stream_t`` returned from this function will not
  ## provide any results. It can be used to check for evaluation errors using
  ## neo4j_check_failure().
  ## 
  ## connection
  ##   The connection.
  ##
  ## statement
  ##   The statement to be evaluated. This must be a ``NULL``
  ##   terminated string and may contain UTF-8 multi-byte characters.
  ##
  ## params
  ##   The parameters for the statement, which must be a value of
  ##   type NEO4J_MAP or #neo4j_null.
  ##
  ## Returns a ``neo4j_result_stream_t``, or ``NULL`` on error (errno will be set).

# =====================================
# result stream
# =====================================

proc checkFailure*(results: ptr ResultStream): cint {.cdecl,
    importc: "neo4j_check_failure", dynlib: libneo4j.}
  ## Check if a results stream has failed.
  ## 
  ## Note: if the error is ``NEO4J_STATEMENT_EVALUATION_FAILED``, then additional
  ## error information will be available via neo4j_error_message().
  ## 
  ## results
  ##   The result stream.
  ##
  ## Returns 0 if no failure has occurred, and an error number otherwise.

proc nfields*(results: ptr ResultStream): cuint {.cdecl, importc: "neo4j_nfields",
    dynlib: libneo4j.}
  ## Get the number of fields in a result stream.
  ## 
  ## results
  ##   The result stream.
  ##
  ## Returns the number of fields in the result, or 0 if no fields were available
  ## or on error (errno will be set).

proc fieldname*(results: ptr ResultStream; index: cuint): cstring {.cdecl,
    importc: "neo4j_fieldname", dynlib: libneo4j.}
  ## Get the name of a field in a result stream.
  ## 
  ## .. attention:: Note that the returned pointer is only valid whilst the result
  ##    stream has not been closed.
  ## 
  ## results
  ##   The result stream.
  ##
  ## index
  ##   The field index to get the name of.
  ##
  ## Returns the name of the field, or ``NULL`` on error (errno will be set).
  ## If returned, the name will be a ``NULL`` terminated string and may
  ## contain UTF-8 multi-byte characters.

proc fetchNext*(results: ptr ResultStream): ptr JobResult {.cdecl,
    importc: "neo4j_fetch_next", dynlib: libneo4j.}
  ## Fetch the next record from the result stream.
  ## 
  ## .. attention:: The pointer to the result will only remain valid until the
  ##    next call to neo4j_fetch_next() or until the result stream is closed. To
  ##    hold the result longer, use neo4j_retain() and neo4j_release().
  ## 
  ## results
  ##   The result stream.
  ##
  ## Returns the next result, or ``NULL`` if the stream is exahusted or an
  ## error has occurred (errno will be set).

proc peek*(results: ptr ResultStream; depth: cuint): ptr JobResult {.cdecl,
    importc: "neo4j_peek", dynlib: libneo4j.}
  ## Peek at a record in the result stream.
  ## 
  ## .. attention:: The pointer to the result will only remain valid until it is
  ##    retreived via neo4j_fetch_next() or until the result stream is closed. To
  ##    hold the result longer, use neo4j_retain() and neo4j_release().
  ## 
  ## .. attention:: All results up to the specified depth will be retrieved and
  ##    held in memory. Avoid using this method with large depths.
  ## 
  ## results
  ##   The result stream.
  ##
  ## depth
  ##   The depth to peek into the remaining records in the stream.
  ##
  ## Returns the result at the specified depth, or ``NULL`` if the stream is
  ## exahusted or an error has occurred (errno will be set).

proc closeResults*(results: ptr ResultStream): cint {.cdecl,
    importc: "neo4j_close_results", dynlib: libneo4j.}
  ## Close a result stream.
  ## 
  ## Closes the result stream and releases all memory held by it, including
  ## results and values obtained from it.
  ## 
  ## .. attention:: After this function is invoked, all ``neo4j_result_t`` objects
  ##    fetched from this stream, and any values obtained from them, will be invalid
  ##    and *must not be accessed*. Doing so will result in undetermined and
  ##    unstable behaviour. This is true even if this function returns an error.
  ## 
  ## results
  ##   The result stream. The pointer will be invalid after the function returns.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

# =====================================
# result metadata
# =====================================

proc errorCode*(results: ptr ResultStream): cstring {.cdecl,
    importc: "neo4j_error_code", dynlib: libneo4j.}
  ## Return the error code sent from neo4j.
  ## 
  ## When neo4j_check_failure() returns ``NEO4J_STATEMENT_EVALUATION_FAILED``,
  ## then this function can be used to get the error code sent from neo4j.
  ## 
  ## .. attention:: Note that the returned pointer is only valid whilst the result
  ##    stream has not been closed.
  ## 
  ## results
  ##   The result stream.
  ##
  ## Returns a ``NULL`` terminated string reprenting the error code, or
  ## ``NULL`` if the stream has not failed or the failure was not
  ## ``NEO4J_STATEMENT_EVALUATION_FAILED``.

proc errorMessage*(results: ptr ResultStream): cstring {.cdecl,
    importc: "neo4j_error_message", dynlib: libneo4j.}
  ## Return the error message sent from neo4j.
  ## 
  ## When neo4j_check_failure() returns ``NEO4J_STATEMENT_EVALUATION_FAILED``,
  ## then this function can be used to get the detailed error message sent
  ## from neo4j.
  ## 
  ## .. attention:: Note that the returned pointer is only valid whilst the result
  ##    stream has not been closed.
  ## 
  ## results
  ##   The result stream.
  ##
  ## Returns the error message, or ``NULL`` if the stream has not failed
  ## or the failure was not ``NEO4J_STATEMENT_EVALUATION_FAILED``. If
  ## returned, the message will be a ``NULL`` terminated string and may
  ## contain UTF-8 mutli-byte characters.

type
  FailureDetails* {.final, pure.} = object
    ## Failure details.
    ##
    ## code
    ##   The failure code.
    ##
    ## message
    ##   The complete failure message. This may contain UTF-8 multi-byte
    ##   characters.
    ##
    ## description
    ##   The human readable description of the failure. This may contain UTF-8
    ##   multi-byte characters.
    ##
    ## line
    ##   The line of statement text that the failure relates to. Will be 0 if
    ##   the failure was not related to a line of statement text.
    ##
    ## column
    ##   The column of statement text that the failure relates to. Will be
    ##   if the failure was not related to a line of statement text.
    ##
    ## offset
    ##   The character offset into the statement text that the failure relates to.
    ##   Will be 0 if the failure is related to the first character of the
    ##   statement text, or if the failure was not related to the statement text.
    ##
    ## context
    ##   A string providing context around where the failure occurred. This
    ##   may contain UTF-8 multi-byte characters. Will be `NULL` if the failure
    ##   was not related to the statement text.
    ##
    ## context
    ##   The offset into the context where the failure occurred. Will be 0 if
    ##   the failure was not related to a line of statement text.
    ##
    code*: cstring
    message*: cstring
    description*: cstring
    line*: cuint
    column*: cuint
    offset*: cuint
    context*: cstring
    contextOffset*: cuint


proc failureDetails*(results: ptr ResultStream): ptr FailureDetails {.cdecl,
    importc: "neo4j_failure_details", dynlib: libneo4j.}
  ## Return the details of a statement evaluation failure.
  ## 
  ## When neo4j_check_failure() returns ``NEO4J_STATEMENT_EVALUATION_FAILED``,
  ## then this function can be used to get the details of the failure.
  ## 
  ## .. attention:: Note that the returned pointer is only valid whilst the result
  ##    stream has not been closed.
  ## 
  ## results
  ##   The result stream.
  ##
  ## Returns a pointer to the failure details, or ``NULL`` if no failure details
  ## were available.

proc len*(results: ptr ResultStream): culonglong {.cdecl,
                                                   importc: "neo4j_result_count",
                                                   dynlib: libneo4j.}
  ## Return the number of records received in a result stream.
  ## 
  ## This value will continue to increase until all results have been fetched.
  ## 
  ## results
  ##   The result stream.
  ##
  ## Returns the number of results.

proc resultsAvailableAfter*(results: ptr ResultStream): culonglong {.cdecl,
    importc: "neo4j_results_available_after", dynlib: libneo4j.}
  ## Return the reported time until the first record was available.
  ## 
  ## results
  ##   The result stream.
  ##
  ## Returns the time, in milliseconds, or 0 if it was not available.
 
proc resultsConsumedAfter*(results: ptr ResultStream): culonglong {.cdecl,
    importc: "neo4j_results_consumed_after", dynlib: libneo4j.}
  ## Return the reported time until all records were consumed.
  ## 
  ## .. attention:: As the consumption time is only available at the end of the result
  ##    stream, invoking this function will will result in any unfetched results
  ##    being pulled from the server and held in memory. It is usually better to
  ##    exhaust the stream using neo4j_fetch_next() before invoking this
  ##    method.
  ## 
  ## results
  ##   The result stream.
  ##
  ## Returns the time, in milliseconds, or 0 if it was not available.

const
  NEO4J_READ_ONLY_STATEMENT* = 0
  NEO4J_WRITE_ONLY_STATEMENT* = 1
  NEO4J_READ_WRITE_STATEMENT* = 2
  NEO4J_SCHEMA_UPDATE_STATEMENT* = 3
  NEO4J_CONTROL_STATEMENT* = 4

proc statementType*(results: ptr ResultStream): cint {.cdecl,
    importc: "neo4j_statement_type", dynlib: libneo4j.}
  ## Return the statement type for the result stream.
  ## 
  ## The returned value will be one of the following:
  ##
  ## - NEO4J_READ_ONLY_STATEMENT
  ## - NEO4J_WRITE_ONLY_STATEMENT
  ## - NEO4J_READ_WRITE_STATEMENT
  ## - NEO4J_SCHEMA_UPDATE_STATEMENT
  ## - NEO4J_CONTROL_STATEMENT
  ## 
  ## .. attention:: As the statement type is only available at the end of the result
  ##    stream, invoking this function will will result in any unfetched results
  ##    being pulled from the server and held in memory. It is usually better to
  ##    exhaust the stream using neo4j_fetch_next() before invoking this
  ##   method.
  ## 
  ## results
  ##   The result stream.
  ##
  ## Returns the statement type, or -1 on error (errno will be set).

type
  UpdateCounts* {.final, pure.}  = object
    ## Update counts.
    ## 
    ## These are a count of all the updates that occurred as a result of
    ## the statement sent to neo4j.
    nodesCreated*: culonglong ## Nodes created.
    nodesDeleted*: culonglong ## Nodes deleted.
    relationshipsCreated*: culonglong ## Relationships created.
    relationshipsDeleted*: culonglong ## Relationships deleted.
    propertiesSet*: culonglong ## Properties set.
    labelsAdded*: culonglong ## Labels added.
    labelsRemoved*: culonglong  ## Labels removed.
    indexesAdded*: culonglong ## Indexes added.
    indexesRemoved*: culonglong ## Indexes removed.
    constraintsAdded*: culonglong ## Constraints added.
    constraintsRemoved*: culonglong ## Constraints removed.

proc updateCounts*(results: ptr ResultStream): UpdateCounts {.cdecl,
    importc: "neo4j_update_counts", dynlib: libneo4j.}
  ## Return the update counts for the result stream.
  ## 
  ## .. attention:: As the update counts are only available at the end of the result
  ##    stream, invoking this function will will result in any unfetched results
  ##    being pulled from the server and held in memory. It is usually better to
  ##    exhaust the stream using neo4j_fetch_next() before invoking this
  ##    method.
  ## 
  ## results
  ##   The result stream.
  ##
  ## Returns the update counts. If an error has occurred, all the counts will be
  ## zero.

type
  StatementPlan* {.final, pure.} = object
    ## The plan (or profile) for an evaluated statement.
    ## 
    ## Plans and profiles differ only in that execution steps do not contain row
    ## and db-hit data.
    version*: cstring ## The version of the compiler that produced the plan/profile.
    planner*: cstring ## The planner that was used to produce the plan/profile.
    runtime*: cstring ## The runtime that was or would be used for evaluating the statement.
    isProfile*: bool ## ``true`` if profile data is included in the execution steps.
    outputStep*: ptr StatementExecutionStep ## The output execution step.



  StatementExecutionStep* {.final, pure.} = object
    ## An execution step in a plan (or profile) for an evaluated statement.
    operatorType*: cstring ## The name of the operator type applied in this execution step.
    identifiers*: cstringArray ## An array of identifier names available in this step.
    nidentifiers*: cuint ## The number of identifiers.
    estimatedRows*: cdouble ## The estimated number of rows to be handled by this step.
    rows*: culonglong ## The number of rows handled by this step (for profiled plans only).
    dbHits*: culonglong ## The number of db_hits (for profiled plans only).
    pageCacheHits*: culonglong ## The number of page cache hits (for profiled plans only).
    pageCacheMisses*: culonglong ## The number of page cache misses (for profiled plans only).
    sources*: ptr ptr StatementExecutionStep ## An array containing the sources for this step.
    nsources*: cuint ## The number of sources.
    arguments*: Neo4jValue ## A NEO4J_MAP, containing all the arguments for this step as provided by the server.

proc statementPlan*(results: ptr ResultStream): ptr StatementPlan {.cdecl,
    importc: "neo4j_statement_plan", dynlib: libneo4j.}
  ## Return the statement plan for the result stream.
  ## 
  ## The returned statement plan, if not ``NULL``, must be later released using
  ## neo4j_statement_plan_release().
  ## 
  ## If the was no plan (or profile) in the server response, the result of this
  ## function will be ``NULL`` and errno will be set to NEO4J_NO_PLAN_AVAILABLE.
  ## Note that errno will not be modified when a plan is returned, so error
  ## checking MUST evaluate the return value first.
  ## 
  ## results
  ##   The result stream.
  ##
  ## Returns the statement plan/profile, or ``NULL`` if a plan/profile was not
  ## available or on error (errno will be set).

proc statementPlanRelease*(plan: ptr StatementPlan) {.cdecl,
    importc: "neo4j_statement_plan_release", dynlib: libneo4j.}
  ## Release a statement plan.
  ## 
  ## The pointer will be invalid and should not be used after this function
  ## is called.
  ## 
  ## plan
  ##   A statment plan.
  ##

# =====================================
# result
# =====================================

proc `[]`*(result: ptr JobResult; index: cuint): Neo4jValue {.cdecl,
    importc: "neo4j_result_field", dynlib: libneo4j.}
  ## Get a field from a result.
  ## 
  ## result
  ##   A result.
  ##
  ## index
  ##   The field index to get.
  ##
  ## Returns the field from the result, or #neo4j_null if index is out of bounds.

proc retain*(result: ptr JobResult): ptr JobResult {.cdecl, importc: "neo4j_retain",
    dynlib: libneo4j.}
  ## Retain a result.
  ## 
  ## This retains the result and all values contained within it, preventing
  ## them from being deallocated on the next call to neo4j_fetch_next()
  ## or when the result stream is closed via neo4j_close_results(). Once
  ## retained, the result _must_ be explicitly released via
  ## neo4j_release().
  ## 
  ## result
  ##   A result.
  ##
  ## Returns the result.

proc release*(result: ptr JobResult) {.cdecl, importc: "neo4j_release", dynlib: libneo4j.}
  ## Release a result.
  ## 
  ## result
  ##   A previously retained result.
  ##

# =====================================
# render results
# =====================================

const
  NEO4J_RENDER_DEFAULT* = 0
  NEO4J_RENDER_SHOW_NULLS* = (1 shl 0)
  NEO4J_RENDER_QUOTE_STRINGS* = (1 shl 1)
  NEO4J_RENDER_ASCII* = (1 shl 2)
  NEO4J_RENDER_ASCII_ART* = (1 shl 3)
  NEO4J_RENDER_ROWLINES* = (1 shl 4)
  NEO4J_RENDER_WRAP_VALUES* = (1 shl 5)
  NEO4J_RENDER_NO_WRAP_MARKERS* = (1 shl 6)
  NEO4J_RENDER_ANSI_COLOR* = (1 shl 7)

proc `renderNulls=`*(config: ptr Config; enable: bool) {.cdecl,
    importc: "neo4j_config_set_render_nulls", dynlib: libneo4j.}
  ## Enable or disable rendering NEO4J_NULL values.
  ## 
  ## If set to ``true``, then NEO4J_NULL values will be rendered using the
  ## string 'null'. Otherwise, they will be blank.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## enable
  ##   ``true`` to enable rendering of NEO4J_NULL values, and ``false``
  ##   to disable this behaviour.

proc renderNulls*(config: ptr Config): bool {.cdecl,
    importc: "neo4j_config_get_render_nulls", dynlib: libneo4j.}
  ## Check if rendering of NEO4J_NULL values is enabled.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns ``true`` if rendering of NEO4J_NULL values is enabled, and
  ## ``false`` otherwise.

proc `enderQuotedStrings=`*(config: ptr Config; enable: bool) {.cdecl,
    importc: "neo4j_config_set_render_quoted_strings", dynlib: libneo4j.}
  ## Enable or disable quoting of NEO4J_STRING values.
  ## 
  ## If set to ``true``, then NEO4J_STRING values will be rendered with
  ## surrounding quotes.
  ## 
  ## .. note:: This only applies when rendering to a table. In CSV output, strings
  ##    are always quoted.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## enable
  ##   ``true`` to enable rendering of NEO4J_STRING values with
  ##   quotes, and ``false`` to disable this behaviour.

proc renderQuotedStrings*(config: ptr Config): bool {.cdecl,
    importc: "neo4j_config_get_render_quoted_strings", dynlib: libneo4j.}
  ## Check if quoting of NEO4J_STRING values is enabled.
  ## 
  ## .. note:: This only applies when rendering to a table. In CSV output, strings
  ##    are always quoted.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns ``true`` if quoting of NEO4J_STRING values is enabled, and ``false``
  ## otherwise.

proc `renderAscii=`*(config: ptr Config; enable: bool) {.cdecl,
    importc: "neo4j_config_set_render_ascii", dynlib: libneo4j.}
  ## Enable or disable rendering in ASCII-only.
  ## 
  ## If set to ``true``, then render output will only use ASCII characters and
  ## any non-ASCII characters in values will be escaped. Otherwise, UTF-8
  ## characters will be used, including unicode border drawing characters.
  ## 
  ## .. note:: This does not effect CSV output.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## enable
  ##   ``true`` to enable rendering in only ASCII characters,
  ##   and ``false`` to disable this behaviour.

proc renderAscii*(config: ptr Config): bool {.cdecl,
    importc: "neo4j_config_get_render_ascii", dynlib: libneo4j.}
  ## Check if ASCII-only rendering is enabled.
  ## 
  ## .. note:: This does not effect CSV output.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns ``true`` if ASCII-only rendering is enabled, and ``false``
  ## otherwise.

proc `renderRowlines=`*(config: ptr Config; enable: bool) {.cdecl,
    importc: "neo4j_config_set_render_rowlines", dynlib: libneo4j.}
  ## Enable or disable rendering of rowlines in result tables.
  ## 
  ## If set to ``true``, then render output will separate each table row
  ## with a rowline.
  ## 
  ## .. note:: This only applies when rendering results to a table.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## enable
  ##   ``true`` to enable rowline rendering, and ``false`` to disable
  ##   this behaviour.

proc renderRowlines*(config: ptr Config): bool {.cdecl,
    importc: "neo4j_config_get_render_rowlines", dynlib: libneo4j.}
  ## Check if rendering of rowlines is enabled.
  ## 
  ## .. note:: This only applies when rendering results to a table.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns ``true`` if rowline rendering is enabled, and ``false``
  ##         otherwise.

proc `renderWrappedValues=`*(config: ptr Config; enable: bool) {.cdecl,
    importc: "neo4j_config_set_render_wrapped_values", dynlib: libneo4j.}
  ## Enable or disable wrapping of values in result tables.
  ## 
  ## If set to ``true``, then values will be wrapped when rendering tables.
  ## Otherwise, they will be truncated.
  ## 
  ## .. note:: This only applies when rendering results to a table.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## enable
  ##   ``true`` to enable value wrapping, and ``false`` to disable this
  ##   behaviour.

proc renderWrappedValues*(config: ptr Config): bool {.cdecl,
    importc: "neo4j_config_get_render_wrapped_values", dynlib: libneo4j.}
  ## Check if wrapping of values in result tables is enabled.
  ## 
  ## .. note:: This only applies when rendering results to a table.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns ``true`` if wrapping of values is enabled, and ``false`` otherwise.

proc `renderWrapMarkers=`*(config: ptr Config; enable: bool) {.cdecl,
    importc: "neo4j_config_set_render_wrap_markers", dynlib: libneo4j.}
  ## Enable or disable the rendering of wrap markers when wrapping or truncating.
  ## 
  ## If set to ``true``, then values that are wrapped or truncated will be
  ## rendered with a wrap marker. The default value for this is ``true``.
  ## 
  ## .. note:: This only applies when rendering results to a table.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## enable
  ##   ``true`` to display wrap markers, and ``false`` to disable this
  ##   behaviour.

proc renderWrapMarkers*(config: ptr Config): bool {.cdecl,
    importc: "neo4j_config_get_render_wrap_markers", dynlib: libneo4j.}
  ## Check if wrap markers will be rendered when wrapping or truncating.
  ## 
  ## .. note:: This only applies when rendering results to a table.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns ``true`` if wrap markers are enabled, and ``false``
  ## otherwise.

proc `renderInspectRows=`*(config: ptr Config; rows: cuint) {.cdecl,
    importc: "neo4j_config_set_render_inspect_rows", dynlib: libneo4j.}
  ## Set the number of results to inspect when determining column widths.
  ## 
  ## If set to 0, no inspection will occur.
  ## 
  ## .. note:: This only applies when rendering results to a table.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## rows
  ##   The number of results to inspect.
  ##

proc renderInspectRows*(config: ptr Config): cuint {.cdecl,
    importc: "neo4j_config_get_render_inspect_rows", dynlib: libneo4j.}
  ## Set the number of results to inspect when determining column widths.
  ## 
  ## .. note:: This only applies when rendering results to a table.
  ## 
  ## config
  ##   The neo4j client configuration.
  ##
  ## Returns the number of results that will be inspected to determine column
  ## widths.

type
  ResultsTableColors* {.final, pure.} = object
    border*: array[2, cstring]
    header*: array[2, cstring]
    cells*: array[2, cstring]


var resultsTableNoColors* {.importc: "neo4j_results_table_no_colors",
                          dynlib: libneo4j.}: ptr ResultsTableColors ## Results table colorization rules for uncolorized table output.

var resultsTableAnsiColors* {.importc: "neo4j_results_table_ansi_colors",
                            dynlib: libneo4j.}: ptr ResultsTableColors ## Results table colorization rules for ANSI terminal output.

proc `resultsTableColors=`*(config: ptr Config;
                            colors: ptr ResultsTableColors) {.cdecl,
    importc: "neo4j_config_set_results_table_colors", dynlib: libneo4j.}
  ## Set the colorization rules for rendering of results tables.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## colors
  ##   Colorization rules for result tables. The pointer must
  ##   remain valid until the config (and any duplicates) have been
  ##   released.

proc resultsTableColors*(config: ptr Config): ptr ResultsTableColors {.
    cdecl, importc: "neo4j_config_get_results_table_colors", dynlib: libneo4j.}
  ## Get the colorization rules for rendering of results tables.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## Returns the colorization rules for result table rendering.

type
  PlanTableColors* {.final, pure.} = object
    border*: array[2, cstring]
    header*: array[2, cstring]
    cells*: array[2, cstring]
    graph*: array[2, cstring]

var planTableNoColors* {.importc: "neo4j_plan_table_no_colors", dynlib: libneo4j.}: ptr PlanTableColors ## Plan table colorization rules for uncolorized plan table output.

var planTableAnsiColors* {.importc: "neo4j_plan_table_ansi_colors", dynlib: libneo4j.}: ptr PlanTableColors ## Plan table colorization rules for ANSI terminal output.

proc `planTableColors=`*(config: ptr Config; colors: ptr PlanTableColors) {.
    cdecl, importc: "neo4j_config_set_plan_table_colors", dynlib: libneo4j.}
  ## Set the colorization rules for rendering of plan tables.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## colors
  ##   Colorization rules for plan tables.  The pointer must
  ##   remain valid until the config (and any duplicates) have been
  ##   released.

proc planTableColorization*(config: ptr Config): ptr PlanTableColors {.
    cdecl, importc: "neo4j_config_get_plan_table_colorization", dynlib: libneo4j.}
  ## Get the colorization rules for rendering of plan tables.
  ## 
  ## config
  ##   The neo4j client configuration to update.
  ##
  ## Returns the colorization rules for plan table rendering.

const
  NEO4J_RENDER_MAX_WIDTH* = 4095

proc renderTable*(stream: File; results: ptr ResultStream; width: cuint;
                 flags: uint32): cint {.cdecl, importc: "neo4j_render_table",
                                     dynlib: libneo4j.}
  ## Render a result stream as a table.
  ## 
  ## A bitmask of flags may be supplied, which may include:
  ##
  ## - NEO4J_RENDER_SHOW_NULLS - output 'null' when rendering NULL values, rather
  ##   than an empty cell.
  ## - NEO4J_RENDER_QUOTE_STRINGS - wrap strings in quotes.
  ## - NEO4J_RENDER_ASCII - use only ASCII characters when rendering.
  ## - NEO4J_RENDER_ROWLINES - render a line between each output row.
  ## - NEO4J_RENDER_WRAP_VALUES - wrap oversized values over multiple lines.
  ## - NEO4J_RENDER_NO_WRAP_MARKERS - don't indicate wrapping of values (should
  ##   be used with NEO4J_RENDER_ROWLINES).
  ## - NEO4J_RENDER_ANSI_COLOR - use ANSI escape codes for colorization.
  ## 
  ## If no flags are required, pass 0 or ``NEO4J_RENDER_DEFAULT``.
  ## 
  ## .. attention:: The output will be written to the stream using UTF-8 encoding.
  ## 
  ## stream
  ##   The stream to render to.
  ##
  ## results
  ##   The results stream to render.
  ##
  ## width
  ##   The width of the table to render.
  ##
  ## flags
  ##   A bitmask of flags to control rendering.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc renderResultsTable*(config: ptr Config; stream: File;
                         results: ptr ResultStream; width: cuint): cint {.cdecl,
    importc: "neo4j_render_results_table", dynlib: libneo4j.}
  ## Render a result stream as a table.
  ## 
  ## .. attention:: The output will be written to the stream using UTF-8 encoding.
  ## 
  ## config
  ##   A neo4j client configuration.
  ##
  ## stream
  ##   The stream to render to.
  ##
  ## results
  ##   The results stream to render.
  ##
  ## width
  ##   The width of the table to render.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc renderCsv*(stream: File; results: ptr ResultStream; flags: uint32): cint {.
    cdecl, importc: "neo4j_render_csv", dynlib: libneo4j.}
  ## Render a result stream as comma separated value.
  ## 
  ## A bitmask of flags may be supplied, which may include:
  ##
  ## - NEO4J_RENDER_SHOW_NULL - output 'null' when rendering NULL values, rather
  ##   than an empty cell.
  ## 
  ## If no flags are required, pass 0 or ``NEO4J_RENDER_DEFAULT``.
  ## 
  ## .. attention:: The output will be written to the stream using UTF-8 encoding.
  ## 
  ## stream
  ##   The stream to render to.
  ##
  ## results
  ##   The results stream to render.
  ##
  ## flags
  ##   A bitmask of flags to control rendering.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc renderCsv*(config: ptr Config; stream: File; results: ptr ResultStream): cint {.
    cdecl, importc: "neo4j_render_ccsv", dynlib: libneo4j.}
  ## Render a result stream as comma separated value.
  ## 
  ## .. attention:: The output will be written to the stream using UTF-8 encoding.
  ## 
  ## config
  ##   A neo4j client configuration.
  ##
  ## stream
  ##   The stream to render to.
  ##
  ## results
  ##   The results stream to render.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc renderPlanTable*(stream: File; plan: ptr StatementPlan; width: cuint;
                     flags: uint32): cint {.cdecl,
    importc: "neo4j_render_plan_table", dynlib: libneo4j.}
  ## Render a statement plan as a table.
  ## 
  ## A bitmask of flags may be supplied, which may include:
  ##
  ## - NEO4J_RENDER_ASCII - use only ASCII characters when rendering.
  ## - NEO4J_RENDER_ANSI_COLOR - use ANSI escape codes for colorization.
  ## 
  ## If no flags are required, pass 0 or ``NEO4J_RENDER_DEFAULT``.
  ## 
  ## .. attention:: The output will be written to the stream using UTF-8 encoding.
  ## 
  ## stream
  ##   The stream to render to.
  ##
  ## plan
  ##   The statement plan to render.
  ##
  ## width
  ##   The width of the table to render.
  ##
  ## flags
  ##   A bitmask of flags to control rendering.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc renderPlantable*(config: ptr Config; stream: File; plan: ptr StatementPlan;
                      width: cuint): cint {.cdecl,
                                            importc: "neo4j_render_plan_ctable",
                                            dynlib: libneo4j.}
  ## Render a statement plan as a table.
  ## 
  ## .. attention:: The output will be written to the stream using UTF-8 encoding.
  ## 
  ## config
  ##   A neo4j client configuration.
  ##
  ## stream
  ##   The stream to render to.
  ##
  ## plan
  ##   The statement plan to render.
  ##
  ## width
  ##   The width of the table to render.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

# =====================================
# utility methods
# =====================================

proc dirname*(path: cstring; buffer: cstring; n: csize): cssize {.cdecl,
    importc: "neo4j_dirname", dynlib: libneo4j.}
  ## Obtain the parent directory of a specified path.
  ## 
  ## Any trailing '/' characters are not counted as part of the directory name.
  ## If ``path`` is ``NULL``, the empty string, or contains no '/' characters, the
  ## path "." is placed into the result buffer.
  ## 
  ## path
  ##   The path.
  ##
  ## buffer
  ##   A buffer to place the parent directory path into, or ``NULL``.
  ##
  ## n
  ##   The length of the buffer.
  ##
  ## Returns the length of the parent directory path, or -1 on error
  ## (errno will be set).

proc basename*(path: cstring; buffer: cstring; n: csize): cssize {.cdecl,
    importc: "neo4j_basename", dynlib: libneo4j.}
  ## Obtain the basename of a specified path.
  ## 
  ## path
  ##   The path.
  ##
  ## buffer
  ##   A buffer to place the base name into, or ``NULL``.
  ##
  ## n
  ##   The length of the buffer.
  ##
  ## Returns the length of the base name, or -1 on error (errno will be set).

proc mkdirP*(path: cstring): cint {.cdecl, importc: "neo4j_mkdir_p", dynlib: libneo4j.}
  ## Create a directory and any required parent directories.
  ## 
  ## Directories are created with default permissions as per the users umask.
  ## 
  ## path
  ##   The path of the directory to create.
  ##
  ## Returns 0 on success, or -1 on error (errno will be set).

proc u8clen*(s: cstring; n: csize): cint {.cdecl, importc: "neo4j_u8clen",
                                           dynlib: libneo4j.}
  ## Return the number of bytes in a UTF-8 character.
  ## 
  ## s
  ##   The sequence of bytes containing the character.
  ##
  ## n
  ##   The maximum number of bytes to inspect.
  ##
  ## Returns the length, in bytes, of the UTF-8 character, or -1 if a
  ## decoding error occurs (errno will be set).

proc u8cwidth*(s: cstring; n: csize): cint {.cdecl, importc: "neo4j_u8cwidth",
                                             dynlib: libneo4j.}
  ## Return the column width of a UTF-8 character.
  ## 
  ## s
  ##   The sequence of bytes containing the character.
  ##
  ## n
  ##   The maximum number of bytes to inspect.
  ##
  ## Returns the width, in columns, of the UTF-8 character, or -1 if the
  ## character is unprintable or cannot be decoded.
  
proc u8codepoint*(s: cstring; n: ptr csize): cint {.cdecl, importc: "neo4j_u8codepoint",
    dynlib: libneo4j.}
  ## Return the Unicode codepoint of a UTF-8 character.
  ## 
  ## s
  ##   The sequence of bytes containing the character.
  ##
  ## n
  ##   A ponter to a ``csize`` containing the maximum number of bytes
  ##   to inspect. On successful return, this will be updated to contain
  ##   the number of bytes consumed by the character.
  ##
  ## Returns the codepoint, or -1 if a decoding error occurs (errno will be set).

proc u8cpwidth*(cp: cint): cint {.cdecl, importc: "neo4j_u8cpwidth", dynlib: libneo4j.}
  ## Return the column width of a Unicode codepoint.
  ## 
  ## cp
  ##   The codepoint value.
  ##
  ## Returns the width, in columns, of the Unicode codepoint, or -1 if the
  ##         codepoint is unprintable.

proc u8cswidth*(s: cstring; n: csize): cint {.cdecl, importc: "neo4j_u8cswidth",
                                        dynlib: libneo4j.}
  ## Return the column width of a UTF-8 string.
  ## 
  ## s
  ##   The UTF-8 encoded string.
  ##
  ## n
  ##   The maximum number of bytes to inspect.
  ##
  ## Returns the width, in columns, of the UTF-8 string.

# Initialise the client for use
let initResult = clientInit()
assert initResult == 0
