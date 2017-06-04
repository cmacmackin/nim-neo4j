
import posix

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
    SsizeT* = cint
else:
  type
    SsizeT* = clonglong
## *
##  Configuration for neo4j client.
## 

type
  ConfigT* {.final, pure.} = object

## *
##  A connection to a neo4j server.
## 

type
  ConnectionT* {.final, pure.} = object

## *
##  A stream of results from a job.
## 

type
  ResultStreamT* {.final, pure.} = object

## *
##  A result from a job.
## 

type
  ResultT* {.final, pure.} = object

## *
##  A neo4j value type.
## 

type
  TypeT* {.final, pure, bycopy.} = uint8

## *
##  Function type for callback when a passwords is required.
## 
##  Should copy the password into the supplied buffer, and return the
##  actual length of the password.
## 
##  @param [userdata] The user data for the callback.
##  @param [buf] The buffer to copy the password into.
##  @param [len] The length of the buffer.
##  @return The length of the password as copied into the buffer.
## 

type
  PasswordCallbackT* = proc (userdata: pointer; buf: cstring; len: csize): SsizeT {.cdecl.}

## *
##  Function type for callback when username and/or password is required.
## 
##  Should update the `NULL` terminated strings in the `username` and/or
##  `password` buffers.
## 
##  @param [userdata] The user data for the callback.
##  @param [host] The host description (typically "<hostname>:<port>").
##  @param [username] A buffer of size `usize`, possibly containing a `NULL`
##          terminated default username.
##  @param [usize] The size of the username buffer.
##  @param [password] A buffer of size `psize`, possibly containing a `NULL`
##          terminated default password.
##  @param [psize] The size of the password buffer.
##  @return 0 on success, -1 on error (errno should be set).
## 

type
  BasicAuthCallbackT* = proc (userdata: pointer; host: cstring; username: cstring;
                           usize: csize; password: cstring; psize: csize): cint {.cdecl.}

## 
##  =====================================
##  version
##  =====================================
## 
## *
##  The version string for libneo4j-client.
## 

proc libneo4jClientVersion*(): cstring {.cdecl, importc: "libneo4j_client_version",
                                      dynlib: libneo4j.}
## *
##  The default client ID string for libneo4j-client.
## 

proc libneo4jClientId*(): cstring {.cdecl, importc: "libneo4j_client_id",
                                 dynlib: libneo4j.}
## 
##  =====================================
##  init
##  =====================================
## 
## *
##  Initialize the neo4j client library.
## 
##  This function should be invoked once per application including the neo4j
##  client library.
## 
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc clientInit*(): cint {.cdecl, importc: "neo4j_client_init", dynlib: libneo4j.}
## *
##  Cleanup after use of the neo4j client library.
## 
##  Whilst it is not necessary to call this function, it can be useful
##  for clearing any allocated memory when testing with tools such as valgrind.
## 
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc clientCleanup*(): cint {.cdecl, importc: "neo4j_client_cleanup", dynlib: libneo4j.}
## 
##  =====================================
##  logging
##  =====================================
## 

const
  NEO4J_LOG_ERROR* = 0
  NEO4J_LOG_WARN* = 1
  NEO4J_LOG_INFO* = 2
  NEO4J_LOG_DEBUG* = 3
  NEO4J_LOG_TRACE* = 4

## *
##  A logger for neo4j client.
## 

type
  Logger* {.final, pure.} = object
    retain*: proc (self: ptr Logger): ptr Logger {.cdecl.} ## *
                                                   ##  Retain a reference to this logger.
                                                   ## 
                                                   ##  @param [self] This logger.
                                                   ##  @return This logger.
                                                   ## 
    ## *
    ##  Release a reference to this logger.
    ## 
    ##  If all references have been released, the logger will be deallocated.
    ## 
    ##  @param [self] This logger.
    ## 
    release*: proc (self: ptr Logger) {.cdecl.} ## *
                                          ##  Write an entry to the log.
                                          ## 
                                          ##  @param [self] This logger.
                                          ##  @param [level] The log level for the entry.
                                          ##  @param [format] The printf-style message format.
                                          ##  @param [ap] The list of arguments for the format.
                                          ## 
    log*: proc (self: ptr Logger; level: uint8; format: cstring) {.cdecl, varargs.} ## *
                                                                           ##  Determine if a logging level is enabled for this logger.
                                                                           ## 
                                                                           ##  @param [self] This logger.
                                                                           ##  @param [level] The level to check.
                                                                           ##  @return `true` if the level is enabled and `false` otherwise.
                                                                           ## 
    isEnabled*: proc (self: ptr Logger; level: uint8): bool {.cdecl.} ## *
                                                             ##  Change the logging level for this logger.
                                                             ## 
                                                             ##  @param [self] This logger.
                                                             ##  @param [level] The level to set.
                                                             ## 
    setLevel*: proc (self: ptr Logger; level: uint8) {.cdecl.}


## *
##  A provider for a neo4j logger.
## 

type
  LoggerProvider* {.final, pure.} = object
    getLogger*: proc (self: ptr LoggerProvider; name: cstring): ptr Logger {.cdecl.} ## *
                                                                           ##  Get a new logger for the provided name.
                                                                           ## 
                                                                           ##  @param [self] This provider.
                                                                           ##  @param [name] The name for the new logger.
                                                                           ##  @return A `neo4j_logger`, or `NULL` on error (errno will be set).
                                                                           ## 
  

const
  NEO4J_STD_LOGGER_DEFAULT* = 0
  NEO4J_STD_LOGGER_NO_PREFIX* = (1 shl 0)

## *
##  Obtain a standard logger provider.
## 
##  The logger will output to the provided `FILE`.
## 
##  A bitmask of flags may be supplied, which may include:
##  - NEO4J_STD_LOGGER_NO_PREFIX - don't output a prefix on each logline
## 
##  If no flags are required, pass 0 or `NEO4J_STD_LOGGER_DEFAULT`.
## 
##  @param [stream] The stream to output to.
##  @param [level] The default level to log at.
##  @param [flags] A bitmask of flags for the standard logger output.
##  @return A `neo4j_logger_provider`, or `NULL` on error (errno will be set).
## 

proc stdLoggerProvider*(stream: File; level: uint8; flags: uint32): ptr LoggerProvider {.
    cdecl, importc: "neo4j_std_logger_provider", dynlib: libneo4j.}
## *
##  Free a standard logger provider.
## 
##  Provider must have been obtained via neo4j_std_logger_provider().
## 
##  @param [provider] The provider to free.
## 

proc stdLoggerProviderFree*(provider: ptr LoggerProvider) {.cdecl,
    importc: "neo4j_std_logger_provider_free", dynlib: libneo4j.}
## *
##  The name for the logging level.
## 
##  @param [level] The logging level.
##  @return A `NULL` terminated ASCII string describing the logging level.
## 

proc logLevelStr*(level: uint8): cstring {.cdecl, importc: "neo4j_log_level_str",
                                       dynlib: libneo4j.}
## 
##  =====================================
##  I/O
##  =====================================
## 
## *
##  An I/O stream for neo4j client.
## 

type
  Iostream* {.final, pure.} = object
    read*: proc (self: ptr Iostream; buf: pointer; nbyte: csize): SsizeT {.cdecl.} ## *
                                                                        ##  Read bytes from a stream into the supplied buffer.
                                                                        ## 
                                                                        ##  @param [self] This stream.
                                                                        ##  @param [buf] A pointer to a memory buffer to read into.
                                                                        ##  @param [nbyte] The size of the memory buffer.
                                                                        ##  @return The bytes read, or -1 on error (errno will be set).
                                                                        ## 
    ## *
    ##  Read bytes from a stream into the supplied I/O vector.
    ## 
    ##  @param [self] This stream.
    ##  @param [iov] A pointer to the I/O vector.
    ##  @param [iovcnt] The length of the I/O vector.
    ##  @return The bytes read, or -1 on error (errno will be set).
    ## 
    readv*: proc (self: ptr Iostream; iov: ptr Iovec; iovcnt: cuint): SsizeT {.cdecl.} ## *
                                                                           ##  Write bytes to a stream from the supplied buffer.
                                                                           ## 
                                                                           ##  @param [self] This stream.
                                                                           ##  @param [buf] A pointer to a memory buffer to read from.
                                                                           ##  @param [nbyte] The size of the memory buffer.
                                                                           ##  @return The bytes written, or -1 on error (errno will be set).
                                                                           ## 
    write*: proc (self: ptr Iostream; buf: pointer; nbyte: csize): SsizeT {.cdecl.} ## *
                                                                         ##  Write bytes to a stream ifrom the supplied I/O vector.
                                                                         ## 
                                                                         ##  @param [self] This stream.
                                                                         ##  @param [iov] A pointer to the I/O vector.
                                                                         ##  @param [iovcnt] The length of the I/O vector.
                                                                         ##  @return The bytes written, or -1 on error (errno will be set).
                                                                         ## 
    writev*: proc (self: ptr Iostream; iov: ptr Iovec; iovcnt: cuint): SsizeT {.cdecl.} ## *
                                                                            ##  Flush the output buffer of the iostream.
                                                                            ## 
                                                                            ##  For unbuffered streams, this is a no-op.
                                                                            ## 
                                                                            ##  @param [self] This stream.
                                                                            ##  @return 0 on success, or -1 on error (errno will be set).
                                                                            ## 
    flush*: proc (self: ptr Iostream): cint {.cdecl.} ## *
                                               ##  Close the stream.
                                               ## 
                                               ##  This function should close the stream and deallocate memory associated
                                               ##  with it.
                                               ## 
                                               ##  @param [self] This stream.
                                               ##  @return 0 on success, or -1 on error (errno will be set).
                                               ## 
    close*: proc (self: ptr Iostream): cint {.cdecl.}


## *
##  A factory for establishing communications with neo4j.
## 

type
  ConnectionFactory* {.final, pure.} = object
    tcpConnect*: proc (self: ptr ConnectionFactory; hostname: cstring; port: cuint;
                     config: ptr ConfigT; flags: uint32; logger: ptr Logger): ptr Iostream {.
        cdecl.} ## *
               ##  Establish a TCP connection.
               ## 
               ##  @param [self] This factory.
               ##  @param [hostname] The hostname to connect to.
               ##  @param [port] The TCP port number to connect to.
               ##  @param [config] The client configuration.
               ##  @param [flags] A bitmask of flags to control connections.
               ##  @param [logger] A logger that may be used for status logging.
               ##  @return A new `neo4j_iostream`, or `NULL` on error (errno will be set).
               ## 
  

## 
##  =====================================
##  error handling
##  =====================================
## 

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

## *
##  Print the error message corresponding to an error number.
## 
##  @param [stream] The stream to write to.
##  @param [errnum] The error number.
##  @param [message] `NULL`, or a pointer to a message string which will
##          be prepend to the error message, separated by a colon and space.
## 

proc perror*(stream: File; errnum: cint; message: cstring) {.cdecl,
    importc: "neo4j_perror", dynlib: libneo4j.}
## *
##  Look up the error message corresponding to an error number.
## 
##  @param [errnum] The error number.
##  @param [buf] A character buffer that may be used to hold the message.
##  @param [buflen] The length of the provided buffer.
##  @return A pointer to a character string containing the error message.
## 

proc strerror*(errnum: cint; buf: cstring; buflen: csize): cstring {.cdecl,
    importc: "neo4j_strerror", dynlib: libneo4j.}
## 
##  =====================================
##  memory
##  =====================================
## 
## *
##  A memory allocator for neo4j client.
## 
##  This will be used to allocate regions of memory as required by
##  a connection, for buffers, etc.
## 

type
  MemoryAllocator* {.final, pure.} = object
    alloc*: proc (self: ptr MemoryAllocator; context: pointer; size: csize): pointer {.
        cdecl.} ## *
               ##  Allocate memory from this allocator.
               ## 
               ##  @param [self] This allocator.
               ##  @param [context] An opaque 'context' for the allocation, which an
               ##          allocator may use to try an optimize storage as memory allocated
               ##          with the same context is likely (but not guaranteed) to be all
               ##          deallocated at the same time. Context may be `NULL`, in which
               ##          case it does not offer any guidance on deallocation.
               ##  @param [size] The amount of memory (in bytes) to allocate.
               ##  @return A pointer to the allocated memory, or `NULL` on error
               ##          (errno will be set).
               ## 
    ## *
    ##  Allocate memory for consecutive objects from this allocator.
    ## 
    ##  Allocates contiguous space for multiple objects of the specified size,
    ##  and fills the space with bytes of value zero.
    ## 
    ##  @param [self] This allocator.
    ##  @param [context] An opaque 'context' for the allocation, which an
    ##          allocator may use to try an optimize storage as memory allocated
    ##          with the same context is likely (but not guaranteed) to be all
    ##          deallocated at the same time. Context may be `NULL`, in which
    ##          case it does not offer any guidance on deallocation.
    ##  @param [count] The number of objects to allocate.
    ##  @param [size] The size (in bytes) of each object.
    ##  @return A pointer to the allocated memory, or `NULL` on error
    ##          (errno will be set).
    ## 
    calloc*: proc (self: ptr MemoryAllocator; context: pointer; count: csize; size: csize): pointer {.
        cdecl.} ## *
               ##  Return memory to this allocator.
               ## 
               ##  @param [self] This allocator.
               ##  @param [ptr] A pointer to the memory being returned.
               ## 
    free*: proc (self: ptr MemoryAllocator; `ptr`: pointer) {.cdecl.} ## *
                                                              ##  Return multiple memory regions to this allocator.
                                                              ## 
                                                              ##  @param [self] This allocator.
                                                              ##  @param [ptrs] An array of pointers to memory for returning.
                                                              ##  @param [n] The length of the pointer array.
                                                              ## 
    vfree*: proc (self: ptr MemoryAllocator; ptrs: ptr pointer; n: csize) {.cdecl.}


## 
##  =====================================
##  values
##  =====================================
## 
## * The neo4j null value type.

var NEO4J_NULL* {.importc: "NEO4J_NULL", dynlib: libneo4j.}: TypeT

## * The neo4j boolean value type.

var NEO4J_BOOL* {.importc: "NEO4J_BOOL", dynlib: libneo4j.}: TypeT

## * The neo4j integer value type.

var NEO4J_INT* {.importc: "NEO4J_INT", dynlib: libneo4j.}: TypeT

## * The neo4j float value type.

var NEO4J_FLOAT* {.importc: "NEO4J_FLOAT", dynlib: libneo4j.}: TypeT

## * The neo4j string value type.

var NEO4J_STRING* {.importc: "NEO4J_STRING", dynlib: libneo4j.}: TypeT

## * The neo4j list value type.

var NEO4J_LIST* {.importc: "NEO4J_LIST", dynlib: libneo4j.}: TypeT

## * The neo4j map value type.

var NEO4J_MAP* {.importc: "NEO4J_MAP", dynlib: libneo4j.}: TypeT

## * The neo4j node value type.

var NEO4J_NODE* {.importc: "NEO4J_NODE", dynlib: libneo4j.}: TypeT

## * The neo4j relationship value type.

var NEO4J_RELATIONSHIP* {.importc: "NEO4J_RELATIONSHIP", dynlib: libneo4j.}: TypeT

## * The neo4j path value type.

var NEO4J_PATH* {.importc: "NEO4J_PATH", dynlib: libneo4j.}: TypeT

## * The neo4j identity value type.

var NEO4J_IDENTITY* {.importc: "NEO4J_IDENTITY", dynlib: libneo4j.}: TypeT

var NEO4J_STRUCT* {.importc: "NEO4J_STRUCT", dynlib: libneo4j.}: TypeT

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


## *
##  An entry in a neo4j map.
## 

type
  MapEntryT* {.final, pure.} = object
    key*: Neo4jValue
    value*: Neo4jValue


## *
##  @fn neo4j_type_t neo4j_type(neo4j_value_t value)
##  @brief Get the type of a neo4j value.
## 
##  @param [value] The neo4j value.
##  @return The type of the value.
## 

template `type`*(v: Neo4jValue): uint8 =
  v.`type`

## *
##  Check the type of a neo4j value.
## 
##  @param [value] The neo4j value.
##  @param [type] The neo4j type.
##  @return `true` if the node is of the specified type and `false` otherwise.
## 

proc instanceof*(value: Neo4jValue; `type`: TypeT): bool {.cdecl,
    importc: "neo4j_instanceof", dynlib: libneo4j.}
## *
##  Get a string description of the neo4j type.
## 
##  @param [t] The neo4j type.
##  @return A pointer to a `NULL` terminated string containing the type name.
## 

proc typestr*(t: TypeT): cstring {.cdecl, importc: "neo4j_typestr", dynlib: libneo4j.}
## *
##  Get a string representation of a neo4j value.
## 
##  Writes as much of the representation as possible into the buffer,
##  ensuring it is always `NULL` terminated.
## 
##  @param [value] The neo4j value.
##  @param [strbuf] A buffer to write the string representation into.
##  @param [n] The length of the buffer.
##  @return A pointer to the provided buffer.
## 

proc tostring*(value: Neo4jValue; strbuf: cstring; n: csize): cstring {.cdecl,
    importc: "neo4j_tostring", dynlib: libneo4j.}
## *
##  Get a UTF-8 string representation of a neo4j value.
## 
##  Writes as much of the representation as possible into the buffer,
##  ensuring it is always `NULL` terminated.
## 
##  @param [value] The neo4j value.
##  @param [strbuf] A buffer to write the string representation into.
##  @param [n] The length of the buffer.
##  @return The number of bytes that would have been written into the buffer
##          had the buffer been large enough.
## 

proc ntostring*(value: Neo4jValue; strbuf: cstring; n: csize): csize {.cdecl,
    importc: "neo4j_ntostring", dynlib: libneo4j.}
## *
##  Print a UTF-8 string representation of a neo4j value to a stream.
## 
##  @param [value] The neo4j value.
##  @param [stream] The stream to print to.
##  @return The number of bytes written to the stream, or -1 on error
##          (errno will be set).
## 

proc fprint*(value: Neo4jValue; stream: File): SsizeT {.cdecl, importc: "neo4j_fprint",
    dynlib: libneo4j.}
## *
##  Compare two neo4j values for equality.
## 
##  @param [value1] The first neo4j value.
##  @param [value2] The second neo4j value.
##  @return `true` if the two values are equivalent, `false` otherwise.
## 

proc eq*(value1: Neo4jValue; value2: Neo4jValue): bool {.cdecl, importc: "neo4j_eq",
    dynlib: libneo4j.}
## *
##  @fn bool neo4j_is_null(neo4j_value_t value);
##  @brief Check if a neo4j value is the null value.
## 
##  @param [value] The neo4j value.
##  @return `true` if the value is the null value.
## 

template isNull*(v: untyped): untyped =
  (`type`(v) == neo4j_Null)

## *
##  The neo4j null value.
## 

var null* {.importc: "neo4j_null", dynlib: libneo4j.}: Neo4jValue

## *
##  Construct a neo4j value encoding a boolean.
## 
##  @param [value] A boolean value.
##  @return A neo4j value encoding the Bool.
## 

proc newBool*(value: bool): Neo4jValue {.cdecl, importc: "neo4j_bool", dynlib: libneo4j.}
## *
##  Return the native boolean value from a neo4j boolean.
## 
##  Note that the result is undefined if the value is not of type NEO4J_BOOL.
## 
##  @param [value] The neo4j value
##  @return The native boolean true or false
## 

proc boolValue*(value: Neo4jValue): bool {.cdecl, importc: "neo4j_bool_value",
                                   dynlib: libneo4j.}
## *
##  Construct a neo4j value encoding an integer.
## 
##  @param [value] A signed integer. This must be in the range INT64_MIN to
##          INT64_MAX, or it will be capped to the closest value.
##  @return A neo4j value encoding the Int.
## 

proc newInt*(value: clonglong): Neo4jValue {.cdecl, importc: "neo4j_int", dynlib: libneo4j.}
## *
##  Return the native integer value from a neo4j int.
## 
##  Note that the result is undefined if the value is not of type NEO4J_INT.
## 
##  @param [value] The neo4j value
##  @return The native integer value
## 

proc intValue*(value: Neo4jValue): clonglong {.cdecl, importc: "neo4j_int_value",
                                       dynlib: libneo4j.}
## *
##  Construct a neo4j value encoding a double.
## 
##  @param [value] A double precision floating point value.
##  @return A neo4j value encoding the Float.
## 

proc newFloat*(value: cdouble): Neo4jValue {.cdecl, importc: "neo4j_float", dynlib: libneo4j.}
## *
##  Return the native double value from a neo4j float.
## 
##  Note that the result is undefined if the value is not of type NEO4J_FLOAT.
## 
##  @param [value] The neo4j value
##  @return The native double value
## 

proc floatValue*(value: Neo4jValue): cdouble {.cdecl, importc: "neo4j_float_value",
                                       dynlib: libneo4j.}
## *
##  @fn neo4j_value_t neo4j_string(const char *s)
##  @brief Construct a neo4j value encoding a string.
## 
##  @param [s] A pointer to a `NULL` terminated ASCII string. The pointer
##          must remain valid, and the content unchanged, for the lifetime of
##          the neo4j value.
##  @return A neo4j value encoding the String.
## 

template toString*(s: cstring): typed =
  ustring(s, s.len)

## *
##  Construct a neo4j value encoding a string.
## 
##  @param [u] A pointer to a UTF-8 string. The pointer must remain valid, and
##          the content unchanged, for the lifetime of the neo4j value.
##  @param [n] The length of the UTF-8 string. This must be less than
##          UINT32_MAX in length (and will be truncated otherwise).
##  @return A neo4j value encoding the String.
## 

proc ustring*(u: cstring; n: cuint): Neo4jValue {.cdecl, importc: "neo4j_ustring",
                                        dynlib: libneo4j.}
## *
##  Return the length of a neo4j UTF-8 string.
## 
##  Note that the result is undefined if the value is not of type NEO4J_STRING.
## 
##  @param [value] The neo4j string.
##  @return The length of the string in bytes.
## 

proc stringLength*(value: Neo4jValue): cuint {.cdecl, importc: "neo4j_string_length",
                                       dynlib: libneo4j.}
## *
##  Return a pointer to a UTF-8 string.
## 
##  The pointer will be to a UTF-8 string, and will NOT be `NULL` terminated.
##  The length of the string, in bytes, can be obtained using
##  neo4j_ustring_length(value).
## 
##  Note that the result is undefined if the value is not of type NEO4J_STRING.
## 
##  @param [value] The neo4j string.
##  @return A pointer to a UTF-8 string, which will not be terminated.
## 

proc ustringValue*(value: Neo4jValue): cstring {.cdecl, importc: "neo4j_ustring_value",
    dynlib: libneo4j.}
## *
##  Copy a neo4j string to a `NULL` terminated buffer.
## 
##  As much of the string will be copied to the buffer as possible, and
##  the result will be `NULL` terminated.
## 
##  Note that the result is undefined if the value is not of type NEO4J_STRING.
## 
##  @attention The content copied to the buffer may contain UTF-8 multi-byte
##          characters.
## 
##  @param [value] The neo4j string.
##  @param [buffer] A pointer to a buffer for storing the string. The pointer
##          must remain valid, and the content unchanged, for the lifetime of
##          the neo4j value.
##  @param [length] The length of the buffer.
##  @return A pointer to the supplied buffer.
## 

proc stringValue*(value: Neo4jValue; buffer: cstring; length: csize): cstring {.cdecl,
    importc: "neo4j_string_value", dynlib: libneo4j.}
## *
##  Construct a neo4j value encoding a list.
## 
##  @param [items] An array of neo4j values. The pointer to the items must
##          remain valid, and the content unchanged, for the lifetime of the
##          neo4j value.
##  @param [n] The length of the array of items. This must be less than
##          UINT32_MAX (or the list will be truncated).
##  @return A neo4j value encoding the List.
## 

proc list*(items: ptr Neo4jValue; n: cuint): Neo4jValue {.cdecl, importc: "neo4j_list",
    dynlib: libneo4j.}
## *
##  Return the length of a neo4j list (number of entries).
## 
##  Note that the result is undefined if the value is not of type NEO4J_LIST.
## 
##  @param [value] The neo4j list.
##  @return The number of entries.
## 

proc listLength*(value: Neo4jValue): cuint {.cdecl, importc: "neo4j_list_length",
                                     dynlib: libneo4j.}
## *
##  Return an element from a neo4j list.
## 
##  Note that the result is undefined if the value is not of type NEO4J_LIST.
## 
##  @param [value] The neo4j list.
##  @param [index] The index of the element to return.
##  @return A pointer to a `neo4j_value_t` element, or `NULL` if the index is
##          beyond the end of the list.
## 

proc listGet*(value: Neo4jValue; index: cuint): Neo4jValue {.cdecl, importc: "neo4j_list_get",
    dynlib: libneo4j.}
## *
##  Construct a neo4j value encoding a map.
## 
##  @param [entries] An array of neo4j map entries. This pointer must remain
##          valid, and the content unchanged, for the lifetime of the neo4j
##          value.
##  @param [n] The length of the array of entries. This must be less than
##          UINT32_MAX (or the list of entries will be truncated).
##  @return A neo4j value encoding the Map.
## 

proc map*(entries: ptr MapEntryT; n: cuint): Neo4jValue {.cdecl, importc: "neo4j_map",
    dynlib: libneo4j.}
## *
##  Return the size of a neo4j map (number of entries).
## 
##  Note that the result is undefined if the value is not of type NEO4J_MAP.
## 
##  @param [value] The neo4j map.
##  @return The number of entries.
## 

proc mapSize*(value: Neo4jValue): cuint {.cdecl, importc: "neo4j_map_size",
                                  dynlib: libneo4j.}
## *
##  Return an entry from a neo4j map.
## 
##  Note that the result is undefined if the value is not of type NEO4J_MAP.
## 
##  @param [value] The neo4j map.
##  @param [index] The index of the entry to return.
##  @return The entry at the specified index, or `NULL` if the index
##          is too large.
## 

proc mapGetentry*(value: Neo4jValue; index: cuint): ptr MapEntryT {.cdecl,
    importc: "neo4j_map_getentry", dynlib: libneo4j.}
## *
##  @fn neo4j_value_t neo4j_map_get(neo4j_value_t value, const char *key);
##  @brief Return a value from a neo4j map.
## 
##  Note that the result is undefined if the value is not of type NEO4J_MAP.
## 
##  @param [value] The neo4j map.
##  @param [key] The null terminated string key for the entry.
##  @return The value stored under the specified key, or `NULL` if the key is
##          not known.
## 

template mapGet*(value, key: untyped): untyped =
  mapKget(value, string(key))

## *
##  Return a value from a neo4j map.
## 
##  Note that the result is undefined if the value is not of type NEO4J_MAP.
## 
##  @param [value] The neo4j map.
##  @param [key] The map key.
##  @return The value stored under the specified key, or `NULL` if the key is
##          not known.
## 

proc mapKget*(value: Neo4jValue; key: Neo4jValue): Neo4jValue {.cdecl, importc: "neo4j_map_kget",
    dynlib: libneo4j.}
## *
##  @fn neo4j_map_entry_t neo4j_map_entry(const char *key, neo4j_value_t value);
##  @brief Constrct a neo4j map entry.
## 
##  @param [key] The null terminated string key for the entry.
##  @param [value] The value for the entry.
##  @return A neo4j map entry.
## 

template mapEntry*(key, value: untyped): untyped =
  mapKentry(string(key), value)

## *
##  Constrct a neo4j map entry using a value key.
## 
##  The value key must be of type NEO4J_STRING.
## 
##  @param [key] The key for the entry.
##  @param [value] The value for the entry.
##  @return A neo4j map entry.
## 

proc mapKentry*(key: Neo4jValue; value: Neo4jValue): MapEntryT {.cdecl,
    importc: "neo4j_map_kentry", dynlib: libneo4j.}
## *
##  Return the label list of a neo4j node.
## 
##  Note that the result is undefined if the value is not of type NEO4J_NODE.
## 
##  @param [value] The neo4j node.
##  @return A neo4j value encoding the List of labels.
## 

proc nodeLabels*(value: Neo4jValue): Neo4jValue {.cdecl, importc: "neo4j_node_labels",
                                      dynlib: libneo4j.}
## *
##  Return the property map of a neo4j node.
## 
##  Note that the result is undefined if the value is not of type NEO4J_NODE.
## 
##  @param [value] The neo4j node.
##  @return A neo4j value encoding the Map of properties.
## 

proc nodeProperties*(value: Neo4jValue): Neo4jValue {.cdecl,
    importc: "neo4j_node_properties", dynlib: libneo4j.}
## *
##  Return the identity of a neo4j node.
## 
##  @param [value] The neo4j node.
##  @return A neo4j value encoding the Identity of the node.
## 

proc nodeIdentity*(value: Neo4jValue): Neo4jValue {.cdecl, importc: "neo4j_node_identity",
                                        dynlib: libneo4j.}
## *
##  Return the type of a neo4j relationship.
## 
##  Note that the result is undefined if the value is not of type
##  NEO4J_RELATIONSHIP.
## 
##  @param [value] The neo4j node.
##  @return A neo4j value encoding the type as a String.
## 

proc relationshipType*(value: Neo4jValue): Neo4jValue {.cdecl,
    importc: "neo4j_relationship_type", dynlib: libneo4j.}
## *
##  Return the property map of a neo4j relationship.
## 
##  Note that the result is undefined if the value is not of type
##  NEO4J_RELATIONSHIP.
## 
##  @param [value] The neo4j relationship.
##  @return A neo4j value encoding the Map of properties.
## 

proc relationshipProperties*(value: Neo4jValue): Neo4jValue {.cdecl,
    importc: "neo4j_relationship_properties", dynlib: libneo4j.}
## *
##  Return the identity of a neo4j relationship.
## 
##  @param [value] The neo4j relationship.
##  @return A neo4j value encoding the Identity of the relationship.
## 

proc relationshipIdentity*(value: Neo4jValue): Neo4jValue {.cdecl,
    importc: "neo4j_relationship_identity", dynlib: libneo4j.}
## *
##  Return the start node identity for a neo4j relationship.
## 
##  @param [value] The neo4j relationship.
##  @return A neo4j value encoding the Identity of the start node.
## 

proc relationshipStartNodeIdentity*(value: Neo4jValue): Neo4jValue {.cdecl,
    importc: "neo4j_relationship_start_node_identity", dynlib: libneo4j.}
## *
##  Return the end node identity for a neo4j relationship.
## 
##  @param [value] The neo4j relationship.
##  @return A neo4j value encoding the Identity of the end node.
## 

proc relationshipEndNodeIdentity*(value: Neo4jValue): Neo4jValue {.cdecl,
    importc: "neo4j_relationship_end_node_identity", dynlib: libneo4j.}
## *
##  Return the length of a neo4j path.
## 
##  The length of a path is defined by the number of relationships included in
##  it.
## 
##  Note that the result is undefined if the value is not of type NEO4J_PATH.
## 
##  @param [value] The neo4j path.
##  @return The length of the path
## 

proc pathLength*(value: Neo4jValue): cuint {.cdecl, importc: "neo4j_path_length",
                                     dynlib: libneo4j.}
## *
##  Return the node at a given distance into the path.
## 
##  Note that the result is undefined if the value is not of type NEO4J_PATH.
## 
##  @param [value] The neo4j path.
##  @param [hops] The number of hops (distance).
##  @return A neo4j value enconding the Node.
## 

proc pathGetNode*(value: Neo4jValue; hops: cuint): Neo4jValue {.cdecl,
    importc: "neo4j_path_get_node", dynlib: libneo4j.}
## *
##  Return the relationship for the given hop in the path.
## 
##  Note that the result is undefined if the value is not of type NEO4J_PATH.
## 
##  @param [value] The neo4j path.
##  @param [hops] The number of hops (distance).
##  @param [forward] `NULL`, or a pointer to a boolean which will be set to
##          `true` if the relationship was traversed in its natural direction
##          and `false` if it was traversed backward.
##  @return A neo4j value enconding the Relationship.
## 

proc pathGetRelationship*(value: Neo4jValue; hops: cuint; forward: ptr bool): Neo4jValue {.cdecl,
    importc: "neo4j_path_get_relationship", dynlib: libneo4j.}
## 
##  =====================================
##  config
##  =====================================
## 
## *
##  Generate a new neo4j client configuration.
## 
##  The returned configuration must be later released using
##  neo4j_config_free().
## 
##  @return A pointer to a new neo4j client configuration, or `NULL` on error
##          (errno will be set).
## 

proc newConfig*(): ptr ConfigT {.cdecl, importc: "neo4j_new_config", dynlib: libneo4j.}
## *
##  Release a neo4j client configuration.
## 
##  @param [config] A pointer to a neo4j client configuration. This pointer will
##          be invalid after the function returns.
## 

proc configFree*(config: ptr ConfigT) {.cdecl, importc: "neo4j_config_free",
                                    dynlib: libneo4j.}
## *
##  Duplicate a neo4j client configuration.
## 
##  The returned configuration must be later released using
##  neo4j_config_free().
## 
##  @param [config] A pointer to a neo4j client configuration.
##  @return A duplicate configuration.
## 

proc configDup*(config: ptr ConfigT): ptr ConfigT {.cdecl, importc: "neo4j_config_dup",
    dynlib: libneo4j.}
## *
##  Set the client ID.
## 
##  The client ID will be used when identifying the client to neo4j.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [client_id] The client ID string. This string should remain allocated
##          whilst the config is allocated _or if any connections opened with
##          the config remain active_.
## 

proc configSetClientId*(config: ptr ConfigT; clientId: cstring) {.cdecl,
    importc: "neo4j_config_set_client_id", dynlib: libneo4j.}
## *
##  Get the client ID in the neo4j client configuration.
## 
##  @param [config] The neo4j client configuration.
##  @return A pointer to the client ID, or `NULL` if one is not set.
## 

proc configGetClientId*(config: ptr ConfigT): cstring {.cdecl,
    importc: "neo4j_config_get_client_id", dynlib: libneo4j.}
const
  NEO4J_MAXUSERNAMELEN* = 1023

## *
##  Set the username in the neo4j client configuration.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [username] The username to authenticate with. The string will be
##          duplicated, and thus may point to temporary memory.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetUsername*(config: ptr ConfigT; username: cstring): cint {.cdecl,
    importc: "neo4j_config_set_username", dynlib: libneo4j.}
## *
##  Get the username in the neo4j client configuration.
## 
##  The returned username will only be valid whilst the configuration is
##  unchanged.
## 
##  @param [config] The neo4j client configuration.
##  @return A pointer to the username, or `NULL` if one is not set.
## 

proc configGetUsername*(config: ptr ConfigT): cstring {.cdecl,
    importc: "neo4j_config_get_username", dynlib: libneo4j.}
const
  NEO4J_MAXPASSWORDLEN* = 1023

## *
##  Set the password in the neo4j client configuration.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [password] The password to authenticate with. The string will be
##          duplicated, and thus may point to temporary memory.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetPassword*(config: ptr ConfigT; password: cstring): cint {.cdecl,
    importc: "neo4j_config_set_password", dynlib: libneo4j.}
## *
##  Set the basic authentication callback.
## 
##  If a username and/or password is required for basic authentication and
##  isn't available in the configuration or connection URI, then this callback
##  will be invoked to obtain the username and/or password.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [callback] The callback to be invoked.
##  @param [userdata] User data that will be supplied to the callback.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetBasicAuthCallback*(config: ptr ConfigT; callback: BasicAuthCallbackT;
                                userdata: pointer): cint {.cdecl,
    importc: "neo4j_config_set_basic_auth_callback", dynlib: libneo4j.}
## *
##  Set the location of a TLS private key and certificate chain.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [path] The path to the PEM file containing the private key
##          and certificate chain. This string should remain allocated whilst
##          the config is allocated _or if any connections opened with the
##          config remain active_.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetTlsPrivateKey*(config: ptr ConfigT; path: cstring): cint {.cdecl,
    importc: "neo4j_config_set_TLS_private_key", dynlib: libneo4j.}
## *
##  Obtain the path to the TLS private key and certificate chain.
## 
##  @param [config] The neo4j client configuration.
##  @return The path set in the config, or `NULL` if none.
## 

proc configGetTlsPrivateKey*(config: ptr ConfigT): cstring {.cdecl,
    importc: "neo4j_config_get_TLS_private_key", dynlib: libneo4j.}
## *
##  Set the password callback for the TLS private key file.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [callback] The callback to be invoked whenever a password for
##          the certificate file is required.
##  @param [userdata] User data that will be supplied to the callback.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetTlsPrivateKeyPasswordCallback*(config: ptr ConfigT;
    callback: PasswordCallbackT; userdata: pointer): cint {.cdecl,
    importc: "neo4j_config_set_TLS_private_key_password_callback",
    dynlib: libneo4j.}
## *
##  Set the password for the TLS private key file.
## 
##  This is a simpler alternative to using
##  neo4j_config_set_TLS_private_key_password_callback().
## 
##  @param [config] The neo4j client configuration to update.
##  @param [password] The password for the certificate file. This string should
##          remain allocated whilst the config is allocated _or if any
##          connections opened with the config remain active_.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetTlsPrivateKeyPassword*(config: ptr ConfigT; password: cstring): cint {.
    cdecl, importc: "neo4j_config_set_TLS_private_key_password", dynlib: libneo4j.}
## *
##  Set the location of a file containing TLS certificate authorities (and CRLs).
## 
##  The file should contain the certificates of the trusted CAs and CRLs. The
##  file must be in base64 privacy enhanced mail (PEM) format.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [path] The path to the PEM file containing the trusted CAs and CRLs.
##          This string should remain allocated whilst the config is allocated
##          _or if any connections opened with the config remain active_.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetTlsCaFile*(config: ptr ConfigT; path: cstring): cint {.cdecl,
    importc: "neo4j_config_set_TLS_ca_file", dynlib: libneo4j.}
## *
##  Obtain the path to the TLS certificate authority file.
## 
##  @param [config] The neo4j client configuration.
##  @return The path set in the config, or `NULL` if none.
## 

proc configGetTlsCaFile*(config: ptr ConfigT): cstring {.cdecl,
    importc: "neo4j_config_get_TLS_ca_file", dynlib: libneo4j.}
## *
##  Set the location of a directory of TLS certificate authorities (and CRLs).
## 
##  The specified directory should contain the certificates of the trusted CAs
##  and CRLs, named by hash according to the `c_rehash` tool.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [path] The path to the directory of CAs and CRLs. This string should
##          remain allocated whilst the config is allocated _or if any
##          connections opened with the config remain active_.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetTlsCaDir*(config: ptr ConfigT; path: cstring): cint {.cdecl,
    importc: "neo4j_config_set_TLS_ca_dir", dynlib: libneo4j.}
## *
##  Obtain the path to the TLS certificate authority directory.
## 
##  @param [config] The neo4j client configuration.
##  @return The path set in the config, or `NULL` if none.
## 

proc configGetTlsCaDir*(config: ptr ConfigT): cstring {.cdecl,
    importc: "neo4j_config_get_TLS_ca_dir", dynlib: libneo4j.}
## *
##  Enable or disable trusting of known hosts.
## 
##  When enabled, the neo4j client will check if a host has been previously
##  trusted and stored into the "known hosts" file, and that the host
##  fingerprint still matches the previously accepted value. This is enabled by
##  default.
## 
##  If verification fails, the callback set with
##  neo4j_config_set_unverified_host_callback() will be invoked.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [enable] `true` to enable trusting of known hosts, and `false` to
##          disable this behaviour.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetTrustKnownHosts*(config: ptr ConfigT; enable: bool): cint {.cdecl,
    importc: "neo4j_config_set_trust_known_hosts", dynlib: libneo4j.}
## *
##  Check if trusting of known hosts is enabled.
## 
##  @param [config] The neo4j client configuration.
##  @return `true` if enabled and `false` otherwise.
## 

proc configGetTrustKnownHosts*(config: ptr ConfigT): bool {.cdecl,
    importc: "neo4j_config_get_trust_known_hosts", dynlib: libneo4j.}
## *
##  Set the location of the known hosts file for TLS certificates.
## 
##  The file, which will be created and maintained by neo4j client,
##  will be used for storing trust information when using "Trust On First Use".
## 
##  @param [config] The neo4j client configuration to update.
##  @param [path] The path to known hosts file. This string should
##          remain allocated whilst the config is allocated _or if any
##          connections opened with the config remain active_.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetKnownHostsFile*(config: ptr ConfigT; path: cstring): cint {.cdecl,
    importc: "neo4j_config_set_known_hosts_file", dynlib: libneo4j.}
## *
##  Obtain the path to the known hosts file.
## 
##  @param [config] The neo4j client configuration.
##  @return The path set in the config, or `NULL` if none.
## 

proc configGetKnownHostsFile*(config: ptr ConfigT): cstring {.cdecl,
    importc: "neo4j_config_get_known_hosts_file", dynlib: libneo4j.}
type
  UnverifiedHostReasonT* {.size: sizeof(cint).} = enum
    NEO4J_HOST_VERIFICATION_UNRECOGNIZED, NEO4J_HOST_VERIFICATION_MISMATCH


const
  NEO4J_HOST_VERIFICATION_REJECT* = 0
  NEO4J_HOST_VERIFICATION_ACCEPT_ONCE* = 1
  NEO4J_HOST_VERIFICATION_TRUST* = 2

## *
##  Function type for callback when host verification has failed.
## 
##  @param [userdata] The user data for the callback.
##  @param [host] The host description (typically "<hostname>:<port>").
##  @param [fingerprint] The fingerprint for the host.
##  @param [reason] The reason for the verification failure, which will be
##          either `NEO4J_HOST_VERIFICATION_UNRECOGNIZED` or
##          `NEO4J_HOST_VERIFICATION_MISMATCH`.
##  @return `NEO4J_HOST_VERIFICATION_REJECT` if the host should be rejected,
##          `NEO4J_HOST_VERIFICATION_ACCEPT_ONCE` if the host should be accepted
##          for just the one connection, `NEO4J_HOST_VERIFICATION_TRUST` if the
##          fingerprint should be stored in the "known hosts" file and thus
##          trusted for future connections, or -1 on error (errno should be set).
## 

type
  UnverifiedHostCallbackT* = proc (userdata: pointer; host: cstring;
                                fingerprint: cstring;
                                reason: UnverifiedHostReasonT): cint {.cdecl.}

## *
##  Set the unverified host callback.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [callback] The callback to be invoked whenever a host verification
##          fails.
##  @param [userdata] User data that will be supplied to the callback.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetUnverifiedHostCallback*(config: ptr ConfigT;
                                     callback: UnverifiedHostCallbackT;
                                     userdata: pointer): cint {.cdecl,
    importc: "neo4j_config_set_unverified_host_callback", dynlib: libneo4j.}
## *
##  Set the I/O output buffer size.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [size] The I/O output buffer size.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetSndbufSize*(config: ptr ConfigT; size: csize): cint {.cdecl,
    importc: "neo4j_config_set_sndbuf_size", dynlib: libneo4j.}
## *
##  Get the size for the I/O output buffer.
## 
##  @param [config] The neo4j client configuration.
##  @return The sndbuf size.
## 

proc configGetSndbufSize*(config: ptr ConfigT): csize {.cdecl,
    importc: "neo4j_config_get_sndbuf_size", dynlib: libneo4j.}
## *
##  Set the I/O input buffer size.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [size] The I/O input buffer size.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetRcvbufSize*(config: ptr ConfigT; size: csize): cint {.cdecl,
    importc: "neo4j_config_set_rcvbuf_size", dynlib: libneo4j.}
## *
##  Get the size for the I/O input buffer.
## 
##  @param [config] The neo4j client configuration.
##  @return The rcvbuf size.
## 

proc configGetRcvbufSize*(config: ptr ConfigT): csize {.cdecl,
    importc: "neo4j_config_get_rcvbuf_size", dynlib: libneo4j.}
## *
##  Set a logger provider in the neo4j client configuration.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [logger_provider] The logger provider function.
## 

proc configSetLoggerProvider*(config: ptr ConfigT;
                             loggerProvider: ptr LoggerProvider) {.cdecl,
    importc: "neo4j_config_set_logger_provider", dynlib: libneo4j.}
## *
##  Set the socket send buffer size.
## 
##  This is only applicable to the standard connection factory.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [size] The socket send buffer size, or 0 to use the system default.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetSoSndbufSize*(config: ptr ConfigT; size: cuint): cint {.cdecl,
    importc: "neo4j_config_set_so_sndbuf_size", dynlib: libneo4j.}
## *
##  Get the size for the socket send buffer.
## 
##  @param [config] The neo4j client configuration.
##  @return The so_sndbuf size.
## 

proc configGetSoSndbufSize*(config: ptr ConfigT): cuint {.cdecl,
    importc: "neo4j_config_get_so_sndbuf_size", dynlib: libneo4j.}
## *
##  Set the socket receive buffer size.
## 
##  This is only applicable to the standard connection factory.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [size] The socket receive buffer size, or 0 to use the system default.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc configSetSoRcvbufSize*(config: ptr ConfigT; size: cuint): cint {.cdecl,
    importc: "neo4j_config_set_so_rcvbuf_size", dynlib: libneo4j.}
## *
##  Get the size for the socket receive buffer.
## 
##  @param [config] The neo4j client configuration.
##  @return The so_rcvbuf size.
## 

proc configGetSoRcvbufSize*(config: ptr ConfigT): cuint {.cdecl,
    importc: "neo4j_config_get_so_rcvbuf_size", dynlib: libneo4j.}
## *
##  Set a connection factory.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [factory] The connection factory.
## 

proc configSetConnectionFactory*(config: ptr ConfigT; factory: ptr ConnectionFactory) {.
    cdecl, importc: "neo4j_config_set_connection_factory", dynlib: libneo4j.}
## *
##  The standard connection factory.
## 

var stdConnectionFactory* {.importc: "neo4j_std_connection_factory",
                          dynlib: libneo4j.}: ConnectionFactory

## 
##  The standard memory allocator.
## 
##  This memory allocator delegates to the system malloc/free functions.
## 

var stdMemoryAllocator* {.importc: "neo4j_std_memory_allocator", dynlib: libneo4j.}: MemoryAllocator

## *
##  Set a memory allocator.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [allocator] The memory allocator.
## 

proc configSetMemoryAllocator*(config: ptr ConfigT; allocator: ptr MemoryAllocator) {.
    cdecl, importc: "neo4j_config_set_memory_allocator", dynlib: libneo4j.}
## *
##  Get the memory allocator.
## 
##  @param [config] The neo4j client configuration.
##  @return The memory allocator.
## 

proc configGetMemoryAllocator*(config: ptr ConfigT): ptr MemoryAllocator {.cdecl,
    importc: "neo4j_config_get_memory_allocator", dynlib: libneo4j.}
## *
##  Set the maximum number of requests that can be pipelined to the
##  server.
## 
##  @attention Setting this value too high could result in deadlocking within
##  the client, as the client will block when trying to send statements
##  to a server with a full queue, instead of reading results that would drain
##  the queue.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [n] The new maximum.
## 

proc configSetMaxPipelinedRequests*(config: ptr ConfigT; n: cuint) {.cdecl,
    importc: "neo4j_config_set_max_pipelined_requests", dynlib: libneo4j.}
## *
##  Get the maximum number of requests that can be pipelined to the server.
## 
##  @param [config] The neo4j client configuration.
##  @return The number of requests that can be pipelined.
## 

proc configGetMaxPipelinedRequests*(config: ptr ConfigT): cuint {.cdecl,
    importc: "neo4j_config_get_max_pipelined_requests", dynlib: libneo4j.}
## *
##  Return a path within the neo4j dot directory.
## 
##  The neo4j dot directory is typically ".neo4j" within the users home
##  directory. If append is `NULL`, then an absoulte path to the home
##  directory is placed into buffer.
## 
##  @param [buffer] The buffer in which to place the path, which will be
##          null terminated. If the buffer is `NULL`, then the function
##          will still return the length of the path it would have placed
##          into the buffer.
##  @param [n] The size of the buffer. If the path is too large to place
##          into the buffer (including the terminating '\0' character),
##          an `ERANGE` error will result.
##  @param [append] The relative path to append to the dot directory, which
##          may be `NULL`.
##  @return The length of the resulting path (not including the null
##          terminating character), or -1 on error (errno will be set).
## 

proc dotDir*(buffer: cstring; n: csize; append: cstring): SsizeT {.cdecl,
    importc: "neo4j_dot_dir", dynlib: libneo4j.}
## 
##  =====================================
##  connection
##  =====================================
## 

const
  NEO4J_DEFAULT_TCP_PORT* = 7687
  NEO4J_CONNECT_DEFAULT* = 0
  NEO4J_INSECURE* = (1 shl 0)
  NEO4J_NO_URI_CREDENTIALS* = (1 shl 1)
  NEO4J_NO_URI_PASSWORD* = (1 shl 2)

## *
##  Establish a connection to a neo4j server.
## 
##  A bitmask of flags may be supplied, which may include:
##  - NEO4J_INSECURE - do not attempt to establish a secure connection. If a
##    secure connection is required, then connect will fail with errno set to
##    `NEO4J_SERVER_REQUIRES_SECURE_CONNECTION`.
##  - NEO4J_NO_URI_CREDENTIALS - do not use credentials provided in the
##    server URI (use credentials from the configuration instead).
##  - NEO4J_NO_URI_PASSWORD - do not use any password provided in the
##    server URI (obtain password from the configuration instead).
## 
##  If no flags are required, pass 0 or `NEO4J_CONNECT_DEFAULT`.
## 
##  @param [uri] A URI describing the server to connect to, which may also
##          include authentication data (which will override any provided
##          in the config).
##  @param [config] The neo4j client configuration to use for this connection.
##  @param [flags] A bitmask of flags to control connections.
##  @return A pointer to a `neo4j_connection_t` structure, or `NULL` on error
##          (errno will be set).
## 

proc connect*(uri: cstring; config: ptr ConfigT; flags: uint32): ptr ConnectionT {.cdecl,
    importc: "neo4j_connect", dynlib: libneo4j.}
## *
##  Establish a connection to a neo4j server.
## 
##  A bitmask of flags may be supplied, which may include:
##  - NEO4J_INSECURE - do not attempt to establish a secure connection. If a
##    secure connection is required, then connect will fail with errno set to
##    `NEO4J_SERVER_REQUIRES_SECURE_CONNECTION`.
## 
##  If no flags are required, pass 0 or `NEO4J_CONNECT_DEFAULT`.
## 
##  @param [hostname] The hostname to connect to.
##  @param [port] The port to connect to.
##  @param [config] The neo4j client configuration to use for this connection.
##  @param [flags] A bitmask of flags to control connections.
##  @return A pointer to a `neo4j_connection_t` structure, or `NULL` on error
##          (errno will be set).
## 

proc tcpConnect*(hostname: cstring; port: cuint; config: ptr ConfigT; flags: uint32): ptr ConnectionT {.
    cdecl, importc: "neo4j_tcp_connect", dynlib: libneo4j.}
## *
##  Close a connection to a neo4j server.
## 
##  @param [connection] The connection to close. This pointer will be invalid
##          after the function returns.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc close*(connection: ptr ConnectionT): cint {.cdecl, importc: "neo4j_close",
    dynlib: libneo4j.}
## *
##  Get the hostname for a connection.
## 
##  @param [connection] The neo4j connection.
##  @return A pointer to a hostname string, which will remain valid only whilst
##          the connection remains open.
## 

proc connectionHostname*(connection: ptr ConnectionT): cstring {.cdecl,
    importc: "neo4j_connection_hostname", dynlib: libneo4j.}
## *
##  Get the port for a connection.
## 
##  @param [connection] The neo4j connection.
##  @return The port of the connection.
## 

proc connectionPort*(connection: ptr ConnectionT): cuint {.cdecl,
    importc: "neo4j_connection_port", dynlib: libneo4j.}
## *
##  Get the username for a connection.
## 
##  @param [connection] The neo4j connection.
##  @return A pointer to a username string, which will remain valid only whilst
##          the connection remains open, or `NULL` if no username was associated
##          with the connection.
## 

proc connectionUsername*(connection: ptr ConnectionT): cstring {.cdecl,
    importc: "neo4j_connection_username", dynlib: libneo4j.}
## *
##  Check if a given connection uses TLS.
## 
##  @param [connection] The neo4j connection.
##  @return `true` if the connection was established over TLS, and `false`
##          otherwise.
## 

proc connectionIsSecure*(connection: ptr ConnectionT): bool {.cdecl,
    importc: "neo4j_connection_is_secure", dynlib: libneo4j.}
## 
##  =====================================
##  session
##  =====================================
## 
## *
##  Reset a session.
## 
##  Invoking this function causes all server-held state for the connection to be
##  cleared, including rolling back any open transactions, and causes any
##  existing result stream to be terminated.
## 
##  @param [connection] The connection to reset.
##  @return 0 on sucess, or -1 on error (errno will be set).
## 

proc reset*(connection: ptr ConnectionT): cint {.cdecl, importc: "neo4j_reset",
    dynlib: libneo4j.}
## *
##  Check if the server indicated that credentials have expired.
## 
##  @param [connection] The connection.
##  @return `true` if the server indicated that credentials have expired,
##          and `false` otherwise.
## 

proc credentialsExpired*(connection: ptr ConnectionT): bool {.cdecl,
    importc: "neo4j_credentials_expired", dynlib: libneo4j.}
## *
##  Get the server ID string.
## 
##  @param [connection] The connection.
##  @return The server ID string, or `NULL` if none was available.
## 

proc serverId*(connection: ptr ConnectionT): cstring {.cdecl,
    importc: "neo4j_server_id", dynlib: libneo4j.}
## 
##  =====================================
##  job
##  =====================================
## 
## *
##  Evaluate a statement.
## 
##  @attention The statement and the params must remain valid until the returned
##  result stream is closed.
## 
##  @param [connection] The connection.
##  @param [statement] The statement to be evaluated. This must be a `NULL`
##          terminated string and may contain UTF-8 multi-byte characters.
##  @param [params] The parameters for the statement, which must be a value of
##          type NEO4J_MAP or #neo4j_null.
##  @return A `neo4j_result_stream_t`, or `NULL` on error (errno will be set).
## 

proc run*(connection: ptr ConnectionT; statement: cstring; params: Neo4jValue): ptr ResultStreamT {.
    cdecl, importc: "neo4j_run", dynlib: libneo4j.}
## *
##  Evaluate a statement, ignoring any results.
## 
##  The `neo4j_result_stream_t` returned from this function will not
##  provide any results. It can be used to check for evaluation errors using
##  neo4j_check_failure().
## 
##  @param [connection] The connection.
##  @param [statement] The statement to be evaluated. This must be a `NULL`
##          terminated string and may contain UTF-8 multi-byte characters.
##  @param [params] The parameters for the statement, which must be a value of
##          type NEO4J_MAP or #neo4j_null.
##  @return A `neo4j_result_stream_t`, or `NULL` on error (errno will be set).
## 

proc send*(connection: ptr ConnectionT; statement: cstring; params: Neo4jValue): ptr ResultStreamT {.
    cdecl, importc: "neo4j_send", dynlib: libneo4j.}
## 
##  =====================================
##  result stream
##  =====================================
## 
## *
##  Check if a results stream has failed.
## 
##  Note: if the error is `NEO4J_STATEMENT_EVALUATION_FAILED`, then additional
##  error information will be available via neo4j_error_message().
## 
##  @param [results] The result stream.
##  @return 0 if no failure has occurred, and an error number otherwise.
## 

proc checkFailure*(results: ptr ResultStreamT): cint {.cdecl,
    importc: "neo4j_check_failure", dynlib: libneo4j.}
## *
##  Get the number of fields in a result stream.
## 
##  @param [results] The result stream.
##  @return The number of fields in the result, or 0 if no fields were available
##          or on error (errno will be set).
## 

proc nfields*(results: ptr ResultStreamT): cuint {.cdecl, importc: "neo4j_nfields",
    dynlib: libneo4j.}
## *
##  Get the name of a field in a result stream.
## 
##  @attention Note that the returned pointer is only valid whilst the result
##  stream has not been closed.
## 
##  @param [results] The result stream.
##  @param [index] The field index to get the name of.
##  @return The name of the field, or `NULL` on error (errno will be set).
##          If returned, the name will be a `NULL` terminated string and may
##          contain UTF-8 multi-byte characters.
## 

proc fieldname*(results: ptr ResultStreamT; index: cuint): cstring {.cdecl,
    importc: "neo4j_fieldname", dynlib: libneo4j.}
## *
##  Fetch the next record from the result stream.
## 
##  @attention The pointer to the result will only remain valid until the
##  next call to neo4j_fetch_next() or until the result stream is closed. To
##  hold the result longer, use neo4j_retain() and neo4j_release().
## 
##  @param [results] The result stream.
##  @return The next result, or `NULL` if the stream is exahusted or an
##          error has occurred (errno will be set).
## 

proc fetchNext*(results: ptr ResultStreamT): ptr ResultT {.cdecl,
    importc: "neo4j_fetch_next", dynlib: libneo4j.}
## *
##  Peek at a record in the result stream.
## 
##  @attention The pointer to the result will only remain valid until it is
##  retreived via neo4j_fetch_next() or until the result stream is closed. To
##  hold the result longer, use neo4j_retain() and neo4j_release().
## 
##  @attention All results up to the specified depth will be retrieved and
##  held in memory. Avoid using this method with large depths.
## 
##  @param [results] The result stream.
##  @param [depth] The depth to peek into the remaining records in the stream.
##  @return The result at the specified depth, or `NULL` if the stream is
##          exahusted or an error has occurred (errno will be set).
## 

proc peek*(results: ptr ResultStreamT; depth: cuint): ptr ResultT {.cdecl,
    importc: "neo4j_peek", dynlib: libneo4j.}
## *
##  Close a result stream.
## 
##  Closes the result stream and releases all memory held by it, including
##  results and values obtained from it.
## 
##  @attention After this function is invoked, all `neo4j_result_t` objects
##  fetched from this stream, and any values obtained from them, will be invalid
##  and _must not be accessed_. Doing so will result in undetermined and
##  unstable behaviour. This is true even if this function returns an error.
## 
##  @param [results] The result stream. The pointer will be invalid after the
##          function returns.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc closeResults*(results: ptr ResultStreamT): cint {.cdecl,
    importc: "neo4j_close_results", dynlib: libneo4j.}
## 
##  =====================================
##  result metadata
##  =====================================
## 
## *
##  Return the error code sent from neo4j.
## 
##  When neo4j_check_failure() returns `NEO4J_STATEMENT_EVALUATION_FAILED`,
##  then this function can be used to get the error code sent from neo4j.
## 
##  @attention Note that the returned pointer is only valid whilst the result
##  stream has not been closed.
## 
##  @param [results] The result stream.
##  @return A `NULL` terminated string reprenting the error code, or `NULL`
##          if the stream has not failed or the failure was not
##          `NEO4J_STATEMENT_EVALUATION_FAILED`.
## 

proc errorCode*(results: ptr ResultStreamT): cstring {.cdecl,
    importc: "neo4j_error_code", dynlib: libneo4j.}
## *
##  Return the error message sent from neo4j.
## 
##  When neo4j_check_failure() returns `NEO4J_STATEMENT_EVALUATION_FAILED`,
##  then this function can be used to get the detailed error message sent
##  from neo4j.
## 
##  @attention Note that the returned pointer is only valid whilst the result
##  stream has not been closed.
## 
##  @param [results] The result stream.
##  @return The error message, or `NULL` if the stream has not failed or the
##          failure was not `NEO4J_STATEMENT_EVALUATION_FAILED`. If returned,
##          the message will be a `NULL` terminated string and may contain UTF-8
##          mutli-byte characters.
## 

proc errorMessage*(results: ptr ResultStreamT): cstring {.cdecl,
    importc: "neo4j_error_message", dynlib: libneo4j.}
## *
##  Failure details.
## 

type
  FailureDetails* {.final, pure.} = object
    code*: cstring             ## * The failure code.
    ## *
    ##  The complete failure message.
    ## 
    ##  @attention This may contain UTF-8 multi-byte characters.
    ## 
    message*: cstring ## *
                    ##  The human readable description of the failure.
                    ## 
                    ##  @attention This may contain UTF-8 multi-byte characters.
                    ## 
    description*: cstring ## *
                        ##  The line of statement text that the failure relates to.
                        ## 
                        ##  Will be 0 if the failure was not related to a line of statement text.
                        ## 
    line*: cuint ## *
               ##  The column of statement text that the failure relates to.
               ## 
               ##  Will be 0 if the failure was not related to a line of statement text.
               ## 
    column*: cuint ## *
                 ##  The character offset into the statement text that the failure relates to.
                 ## 
                 ##  Will be 0 if the failure is related to the first character of the
                 ##  statement text, or if the failure was not related to the statement text.
                 ## 
    offset*: cuint ## *
                 ##  A string providing context around where the failure occurred.
                 ## 
                 ##  @attention This may contain UTF-8 multi-byte characters.
                 ## 
                 ##  Will be `NULL` if the failure was not related to the statement text.
                 ## 
    context*: cstring ## *
                    ##  The offset into the context where the failure occurred.
                    ## 
                    ##  Will be 0 if the failure was not related to a line of statement text.
                    ## 
    contextOffset*: cuint


## *
##  Return the details of a statement evaluation failure.
## 
##  When neo4j_check_failure() returns `NEO4J_STATEMENT_EVALUATION_FAILED`,
##  then this function can be used to get the details of the failure.
## 
##  @attention Note that the returned pointer is only valid whilst the result
##  stream has not been closed.
## 
##  @param [results] The result stream.
##  @return A pointer to the failure details, or `NULL` if no failure details
##          were available.
## 

proc failureDetails*(results: ptr ResultStreamT): ptr FailureDetails {.cdecl,
    importc: "neo4j_failure_details", dynlib: libneo4j.}
## 
##  Return the number of records received in a result stream.
## 
##  This value will continue to increase until all results have been fetched.
## 
##  @param [results] The result stream.
##  @return The number of results.
## 

proc resultCount*(results: ptr ResultStreamT): culonglong {.cdecl,
    importc: "neo4j_result_count", dynlib: libneo4j.}
## 
##  Return the reported time until the first record was available.
## 
##  @param [results] The result stream.
##  @return The time, in milliseconds, or 0 if it was not available.
## 

proc resultsAvailableAfter*(results: ptr ResultStreamT): culonglong {.cdecl,
    importc: "neo4j_results_available_after", dynlib: libneo4j.}
## 
##  Return the reported time until all records were consumed.
## 
##  @attention As the consumption time is only available at the end of the result
##  stream, invoking this function will will result in any unfetched results
##  being pulled from the server and held in memory. It is usually better to
##  exhaust the stream using neo4j_fetch_next() before invoking this
##  method.
## 
##  @param [results] The result stream.
##  @return The time, in milliseconds, or 0 if it was not available.
## 

proc resultsConsumedAfter*(results: ptr ResultStreamT): culonglong {.cdecl,
    importc: "neo4j_results_consumed_after", dynlib: libneo4j.}
const
  NEO4J_READ_ONLY_STATEMENT* = 0
  NEO4J_WRITE_ONLY_STATEMENT* = 1
  NEO4J_READ_WRITE_STATEMENT* = 2
  NEO4J_SCHEMA_UPDATE_STATEMENT* = 3
  NEO4J_CONTROL_STATEMENT* = 4

## *
##  Return the statement type for the result stream.
## 
##  The returned value will be one of the following:
##  - NEO4J_READ_ONLY_STATEMENT
##  - NEO4J_WRITE_ONLY_STATEMENT
##  - NEO4J_READ_WRITE_STATEMENT
##  - NEO4J_SCHEMA_UPDATE_STATEMENT
##  - NEO4J_CONTROL_STATEMENT
## 
##  @attention As the statement type is only available at the end of the result
##  stream, invoking this function will will result in any unfetched results
##  being pulled from the server and held in memory. It is usually better to
##  exhaust the stream using neo4j_fetch_next() before invoking this
##  method.
## 
##  @param [results] The result stream.
##  @return The statement type, or -1 on error (errno will be set).
## 

proc statementType*(results: ptr ResultStreamT): cint {.cdecl,
    importc: "neo4j_statement_type", dynlib: libneo4j.}
## *
##  Update counts.
## 
##  These are a count of all the updates that occurred as a result of
##  the statement sent to neo4j.
## 

type
  UpdateCounts* {.final, pure.}  = object
    nodesCreated*: culonglong  ## * Nodes created.
    ## * Nodes deleted.
    nodesDeleted*: culonglong  ## * Relationships created.
    relationshipsCreated*: culonglong ## * Relationships deleted.
    relationshipsDeleted*: culonglong ## * Properties set.
    propertiesSet*: culonglong ## * Labels added.
    labelsAdded*: culonglong   ## * Labels removed.
    labelsRemoved*: culonglong ## * Indexes added.
    indexesAdded*: culonglong  ## * Indexes removed.
    indexesRemoved*: culonglong ## * Constraints added.
    constraintsAdded*: culonglong ## * Constraints removed.
    constraintsRemoved*: culonglong


## *
##  Return the update counts for the result stream.
## 
##  @attention As the update counts are only available at the end of the result
##  stream, invoking this function will will result in any unfetched results
##  being pulled from the server and held in memory. It is usually better to
##  exhaust the stream using neo4j_fetch_next() before invoking this
##  method.
## 
##  @param [results] The result stream.
##  @return The update counts. If an error has occurred, all the counts will be
##          zero.
## 

proc updateCounts*(results: ptr ResultStreamT): UpdateCounts {.cdecl,
    importc: "neo4j_update_counts", dynlib: libneo4j.}
  

## *
##  The plan (or profile) for an evaluated statement.
## 
##  Plans and profiles differ only in that execution steps do not contain row
##  and db-hit data.
## 

type
  StatementPlan* {.final, pure.} = object
    version*: cstring          ## * The version of the compiler that produced the plan/profile.
    ## * The planner that was used to produce the plan/profile.
    planner*: cstring          ## * The runtime that was or would be used for evaluating the statement.
    runtime*: cstring          ## * `true` if profile data is included in the execution steps.
    isProfile*: bool           ## * The output execution step.
    outputStep*: ptr StatementExecutionStep


  ## *
  ##  An execution step in a plan (or profile) for an evaluated statement.
  ## 

  StatementExecutionStep* {.final, pure.} = object
    operatorType*: cstring     ## * The name of the operator type applied in this execution step.
    ## * An array of identifier names available in this step.
    identifiers*: cstringArray ## * The number of identifiers.
    nidentifiers*: cuint       ## * The estimated number of rows to be handled by this step.
    estimatedRows*: cdouble    ## * The number of rows handled by this step (for profiled plans only).
    rows*: culonglong          ## * The number of db_hits (for profiled plans only).
    dbHits*: culonglong        ## * The number of page cache hits (for profiled plans only).
    pageCacheHits*: culonglong ## * The number of page cache misses (for profiled plans only).
    pageCacheMisses*: culonglong ## * An array containing the sources for this step.
    sources*: ptr ptr StatementExecutionStep ## * The number of sources.
    nsources*: cuint ## *
                   ##  A NEO4J_MAP, containing all the arguments for this step as provided by
                   ##  the server.
                   ## 
    arguments*: Neo4jValue


## *
##  Return the statement plan for the result stream.
## 
##  The returned statement plan, if not `NULL`, must be later released using
##  neo4j_statement_plan_release().
## 
##  If the was no plan (or profile) in the server response, the result of this
##  function will be `NULL` and errno will be set to NEO4J_NO_PLAN_AVAILABLE.
##  Note that errno will not be modified when a plan is returned, so error
##  checking MUST evaluate the return value first.
## 
##  @param [results] The result stream.
##  @return The statement plan/profile, or `NULL` if a plan/profile was not
##          available or on error (errno will be set).
## 

proc statementPlan*(results: ptr ResultStreamT): ptr StatementPlan {.cdecl,
    importc: "neo4j_statement_plan", dynlib: libneo4j.}
## *
##  Release a statement plan.
## 
##  The pointer will be invalid and should not be used after this function
##  is called.
## 
##  @param [plan] A statment plan.
## 

proc statementPlanRelease*(plan: ptr StatementPlan) {.cdecl,
    importc: "neo4j_statement_plan_release", dynlib: libneo4j.}
## 
##  =====================================
##  result
##  =====================================
## 
## *
##  Get a field from a result.
## 
##  @param [result] A result.
##  @param [index] The field index to get.
##  @return The field from the result, or #neo4j_null if index is out of bounds.
## 

proc resultField*(result: ptr ResultT; index: cuint): Neo4jValue {.cdecl,
    importc: "neo4j_result_field", dynlib: libneo4j.}
## *
##  Retain a result.
## 
##  This retains the result and all values contained within it, preventing
##  them from being deallocated on the next call to neo4j_fetch_next()
##  or when the result stream is closed via neo4j_close_results(). Once
##  retained, the result _must_ be explicitly released via
##  neo4j_release().
## 
##  @param [result] A result.
##  @return The result.
## 

proc retain*(result: ptr ResultT): ptr ResultT {.cdecl, importc: "neo4j_retain",
    dynlib: libneo4j.}
## *
##  Release a result.
## 
##  @param [result] A previously retained result.
## 

proc release*(result: ptr ResultT) {.cdecl, importc: "neo4j_release", dynlib: libneo4j.}
## 
##  =====================================
##  render results
##  =====================================
## 

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

## *
##  Enable or disable rendering NEO4J_NULL values.
## 
##  If set to `true`, then NEO4J_NULL values will be rendered using the
##  string 'null'. Otherwise, they will be blank.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [enable] `true` to enable rendering of NEO4J_NULL values, and
##          `false` to disable this behaviour.
## 

proc configSetRenderNulls*(config: ptr ConfigT; enable: bool) {.cdecl,
    importc: "neo4j_config_set_render_nulls", dynlib: libneo4j.}
## *
##  Check if rendering of NEO4J_NULL values is enabled.
## 
##  @param [config] The neo4j client configuration.
##  @return `true` if rendering of NEO4J_NULL values is enabled, and `false`
##          otherwise.
## 

proc configGetRenderNulls*(config: ptr ConfigT): bool {.cdecl,
    importc: "neo4j_config_get_render_nulls", dynlib: libneo4j.}
## *
##  Enable or disable quoting of NEO4J_STRING values.
## 
##  If set to `true`, then NEO4J_STRING values will be rendered with
##  surrounding quotes.
## 
##  @note This only applies when rendering to a table. In CSV output, strings
##  are always quoted.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [enable] `true` to enable rendering of NEO4J_STRING values with
##          quotes, and `false` to disable this behaviour.
## 

proc configSetRenderQuotedStrings*(config: ptr ConfigT; enable: bool) {.cdecl,
    importc: "neo4j_config_set_render_quoted_strings", dynlib: libneo4j.}
## *
##  Check if quoting of NEO4J_STRING values is enabled.
## 
##  @note This only applies when rendering to a table. In CSV output, strings
##  are always quoted.
## 
##  @param [config] The neo4j client configuration.
##  @return `true` if quoting of NEO4J_STRING values is enabled, and `false`
##          otherwise.
## 

proc configGetRenderQuotedStrings*(config: ptr ConfigT): bool {.cdecl,
    importc: "neo4j_config_get_render_quoted_strings", dynlib: libneo4j.}
## *
##  Enable or disable rendering in ASCII-only.
## 
##  If set to `true`, then render output will only use ASCII characters and
##  any non-ASCII characters in values will be escaped. Otherwise, UTF-8
##  characters will be used, including unicode border drawing characters.
## 
##  @note This does not effect CSV output.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [enable] `true` to enable rendering in only ASCII characters,
##          and `false` to disable this behaviour.
## 

proc configSetRenderAscii*(config: ptr ConfigT; enable: bool) {.cdecl,
    importc: "neo4j_config_set_render_ascii", dynlib: libneo4j.}
## *
##  Check if ASCII-only rendering is enabled.
## 
##  @note This does not effect CSV output.
## 
##  @param [config] The neo4j client configuration.
##  @return `true` if ASCII-only rendering is enabled, and `false`
##          otherwise.
## 

proc configGetRenderAscii*(config: ptr ConfigT): bool {.cdecl,
    importc: "neo4j_config_get_render_ascii", dynlib: libneo4j.}
## *
##  Enable or disable rendering of rowlines in result tables.
## 
##  If set to `true`, then render output will separate each table row
##  with a rowline.
## 
##  @note This only applies when rendering results to a table.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [enable] `true` to enable rowline rendering, and `false` to disable
##          this behaviour.
## 

proc configSetRenderRowlines*(config: ptr ConfigT; enable: bool) {.cdecl,
    importc: "neo4j_config_set_render_rowlines", dynlib: libneo4j.}
## *
##  Check if rendering of rowlines is enabled.
## 
##  @note This only applies when rendering results to a table.
## 
##  @param [config] The neo4j client configuration.
##  @return `true` if rowline rendering is enabled, and `false`
##          otherwise.
## 

proc configGetRenderRowlines*(config: ptr ConfigT): bool {.cdecl,
    importc: "neo4j_config_get_render_rowlines", dynlib: libneo4j.}
## *
##  Enable or disable wrapping of values in result tables.
## 
##  If set to `true`, then values will be wrapped when rendering tables.
##  Otherwise, they will be truncated.
## 
##  @note This only applies when rendering results to a table.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [enable] `true` to enable value wrapping, and `false` to disable this
##          behaviour.
## 

proc configSetRenderWrappedValues*(config: ptr ConfigT; enable: bool) {.cdecl,
    importc: "neo4j_config_set_render_wrapped_values", dynlib: libneo4j.}
## *
##  Check if wrapping of values in result tables is enabled.
## 
##  @note This only applies when rendering results to a table.
## 
##  @param [config] The neo4j client configuration.
##  @return `true` if wrapping of values is enabled, and `false` otherwise.
## 

proc configGetRenderWrappedValues*(config: ptr ConfigT): bool {.cdecl,
    importc: "neo4j_config_get_render_wrapped_values", dynlib: libneo4j.}
## *
##  Enable or disable the rendering of wrap markers when wrapping or truncating.
## 
##  If set to `true`, then values that are wrapped or truncated will be
##  rendered with a wrap marker. The default value for this is `true`.
## 
##  @note This only applies when rendering results to a table.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [enable] `true` to display wrap markers, and `false` to disable this
##          behaviour.
## 

proc configSetRenderWrapMarkers*(config: ptr ConfigT; enable: bool) {.cdecl,
    importc: "neo4j_config_set_render_wrap_markers", dynlib: libneo4j.}
## *
##  Check if wrap markers will be rendered when wrapping or truncating.
## 
##  @note This only applies when rendering results to a table.
## 
##  @param [config] The neo4j client configuration.
##  @return `true` if wrap markers are enabled, and `false` otherwise.
## 

proc configGetRenderWrapMarkers*(config: ptr ConfigT): bool {.cdecl,
    importc: "neo4j_config_get_render_wrap_markers", dynlib: libneo4j.}
## *
##  Set the number of results to inspect when determining column widths.
## 
##  If set to 0, no inspection will occur.
## 
##  @note This only applies when rendering results to a table.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [rows] The number of results to inspect.
## 

proc configSetRenderInspectRows*(config: ptr ConfigT; rows: cuint) {.cdecl,
    importc: "neo4j_config_set_render_inspect_rows", dynlib: libneo4j.}
## *
##  Set the number of results to inspect when determining column widths.
## 
##  @note This only applies when rendering results to a table.
## 
##  @param [config] The neo4j client configuration.
##  @return The number of results that will be inspected to determine column
##          widths.
## 

proc configGetRenderInspectRows*(config: ptr ConfigT): cuint {.cdecl,
    importc: "neo4j_config_get_render_inspect_rows", dynlib: libneo4j.}
type
  ResultsTableColors* {.final, pure.} = object
    border*: array[2, cstring]
    header*: array[2, cstring]
    cells*: array[2, cstring]


## * Results table colorization rules for uncolorized table output.

var resultsTableNoColors* {.importc: "neo4j_results_table_no_colors",
                          dynlib: libneo4j.}: ptr ResultsTableColors

## * Results table colorization rules for ANSI terminal output.

var resultsTableAnsiColors* {.importc: "neo4j_results_table_ansi_colors",
                            dynlib: libneo4j.}: ptr ResultsTableColors

## *
##  Set the colorization rules for rendering of results tables.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [colors] Colorization rules for result tables. The pointer must
##          remain valid until the config (and any duplicates) have been
##          released.
## 

proc configSetResultsTableColors*(config: ptr ConfigT;
                                 colors: ptr ResultsTableColors) {.cdecl,
    importc: "neo4j_config_set_results_table_colors", dynlib: libneo4j.}
## *
##  Get the colorization rules for rendering of results tables.
## 
##  @param [config] The neo4j client configuration to update.
##  @return The colorization rules for result table rendering.
## 

proc configGetResultsTableColors*(config: ptr ConfigT): ptr ResultsTableColors {.
    cdecl, importc: "neo4j_config_get_results_table_colors", dynlib: libneo4j.}
type
  PlanTableColors* {.final, pure.} = object
    border*: array[2, cstring]
    header*: array[2, cstring]
    cells*: array[2, cstring]
    graph*: array[2, cstring]


## * Plan table colorization rules for uncolorized plan table output.

var planTableNoColors* {.importc: "neo4j_plan_table_no_colors", dynlib: libneo4j.}: ptr PlanTableColors

## * Plan table colorization rules for ANSI terminal output.

var planTableAnsiColors* {.importc: "neo4j_plan_table_ansi_colors", dynlib: libneo4j.}: ptr PlanTableColors

## *
##  Set the colorization rules for rendering of plan tables.
## 
##  @param [config] The neo4j client configuration to update.
##  @param [colors] Colorization rules for plan tables.  The pointer must
##          remain valid until the config (and any duplicates) have been
##          released.
## 

proc configSetPlanTableColors*(config: ptr ConfigT; colors: ptr PlanTableColors) {.
    cdecl, importc: "neo4j_config_set_plan_table_colors", dynlib: libneo4j.}
## *
##  Get the colorization rules for rendering of plan tables.
## 
##  @param [config] The neo4j client configuration to update.
##  @return The colorization rules for plan table rendering.
## 

proc configGetPlanTableColorization*(config: ptr ConfigT): ptr PlanTableColors {.
    cdecl, importc: "neo4j_config_get_plan_table_colorization", dynlib: libneo4j.}
const
  NEO4J_RENDER_MAX_WIDTH* = 4095

## *
##  Render a result stream as a table.
## 
##  A bitmask of flags may be supplied, which may include:
##  - NEO4J_RENDER_SHOW_NULLS - output 'null' when rendering NULL values, rather
##  than an empty cell.
##  - NEO4J_RENDER_QUOTE_STRINGS - wrap strings in quotes.
##  - NEO4J_RENDER_ASCII - use only ASCII characters when rendering.
##  - NEO4J_RENDER_ROWLINES - render a line between each output row.
##  - NEO4J_RENDER_WRAP_VALUES - wrap oversized values over multiple lines.
##  - NEO4J_RENDER_NO_WRAP_MARKERS - don't indicate wrapping of values (should
##  be used with NEO4J_RENDER_ROWLINES).
##  - NEO4J_RENDER_ANSI_COLOR - use ANSI escape codes for colorization.
## 
##  If no flags are required, pass 0 or `NEO4J_RENDER_DEFAULT`.
## 
##  @attention The output will be written to the stream using UTF-8 encoding.
## 
##  @param [stream] The stream to render to.
##  @param [results] The results stream to render.
##  @param [width] The width of the table to render.
##  @param [flags] A bitmask of flags to control rendering.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc renderTable*(stream: File; results: ptr ResultStreamT; width: cuint;
                 flags: uint32): cint {.cdecl, importc: "neo4j_render_table",
                                     dynlib: libneo4j.}
## *
##  Render a result stream as a table.
## 
##  @attention The output will be written to the stream using UTF-8 encoding.
## 
##  @param [config] A neo4j client configuration.
##  @param [stream] The stream to render to.
##  @param [results] The results stream to render.
##  @param [width] The width of the table to render.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc renderResultsTable*(config: ptr ConfigT; stream: File;
                        results: ptr ResultStreamT; width: cuint): cint {.cdecl,
    importc: "neo4j_render_results_table", dynlib: libneo4j.}
## *
##  Render a result stream as comma separated value.
## 
##  A bitmask of flags may be supplied, which may include:
##  - NEO4J_RENDER_SHOW_NULL - output 'null' when rendering NULL values, rather
##  than an empty cell.
## 
##  If no flags are required, pass 0 or `NEO4J_RENDER_DEFAULT`.
## 
##  @attention The output will be written to the stream using UTF-8 encoding.
## 
##  @param [stream] The stream to render to.
##  @param [results] The results stream to render.
##  @param [flags] A bitmask of flags to control rendering.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc renderCsv*(stream: File; results: ptr ResultStreamT; flags: uint32): cint {.
    cdecl, importc: "neo4j_render_csv", dynlib: libneo4j.}
## *
##  Render a result stream as comma separated value.
## 
##  @attention The output will be written to the stream using UTF-8 encoding.
## 
##  @param [config] A neo4j client configuration.
##  @param [stream] The stream to render to.
##  @param [results] The results stream to render.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc renderCcsv*(config: ptr ConfigT; stream: File; results: ptr ResultStreamT): cint {.
    cdecl, importc: "neo4j_render_ccsv", dynlib: libneo4j.}
## *
##  Render a statement plan as a table.
## 
##  A bitmask of flags may be supplied, which may include:
##  - NEO4J_RENDER_ASCII - use only ASCII characters when rendering.
##  - NEO4J_RENDER_ANSI_COLOR - use ANSI escape codes for colorization.
## 
##  If no flags are required, pass 0 or `NEO4J_RENDER_DEFAULT`.
## 
##  @attention The output will be written to the stream using UTF-8 encoding.
## 
##  @param [stream] The stream to render to.
##  @param [plan] The statement plan to render.
##  @param [width] The width of the table to render.
##  @param [flags] A bitmask of flags to control rendering.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc renderPlanTable*(stream: File; plan: ptr StatementPlan; width: cuint;
                     flags: uint32): cint {.cdecl,
    importc: "neo4j_render_plan_table", dynlib: libneo4j.}
## *
##  Render a statement plan as a table.
## 
##  @attention The output will be written to the stream using UTF-8 encoding.
## 
##  @param [config] A neo4j client configuration.
##  @param [stream] The stream to render to.
##  @param [plan] The statement plan to render.
##  @param [width] The width of the table to render.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc renderPlanCtable*(config: ptr ConfigT; stream: File; plan: ptr StatementPlan;
                      width: cuint): cint {.cdecl,
    importc: "neo4j_render_plan_ctable", dynlib: libneo4j.}
## 
##  =====================================
##  utility methods
##  =====================================
## 
## *
##  Obtain the parent directory of a specified path.
## 
##  Any trailing '/' characters are not counted as part of the directory name.
##  If `path` is `NULL`, the empty string, or contains no '/' characters, the
##  path "." is placed into the result buffer.
## 
##  @param [path] The path.
##  @param [buffer] A buffer to place the parent directory path into, or `NULL`.
##  @param [n] The length of the buffer.
##  @return The length of the parent directory path, or -1 on error
##          (errno will be set).
## 

proc dirname*(path: cstring; buffer: cstring; n: csize): SsizeT {.cdecl,
    importc: "neo4j_dirname", dynlib: libneo4j.}
## *
##  Obtain the basename of a specified path.
## 
##  @param [path] The path.
##  @param [buffer] A buffer to place the base name into, or `NULL`.
##  @param [n] The length of the buffer.
##  @return The length of the base name, or -1 on error (errno will be set).
## 

proc basename*(path: cstring; buffer: cstring; n: csize): SsizeT {.cdecl,
    importc: "neo4j_basename", dynlib: libneo4j.}
## *
##  Create a directory and any required parent directories.
## 
##  Directories are created with default permissions as per the users umask.
## 
##  @param [path] The path of the directory to create.
##  @return 0 on success, or -1 on error (errno will be set).
## 

proc mkdirP*(path: cstring): cint {.cdecl, importc: "neo4j_mkdir_p", dynlib: libneo4j.}
## *
##  Return the number of bytes in a UTF-8 character.
## 
##  @param [s] The sequence of bytes containing the character.
##  @param [n] The maximum number of bytes to inspect.
##  @return The length, in bytes, of the UTF-8 character, or -1 if a
##          decoding error occurs (errno will be set).
## 

proc u8clen*(s: cstring; n: csize): cint {.cdecl, importc: "neo4j_u8clen",
                                     dynlib: libneo4j.}
## *
##  Return the column width of a UTF-8 character.
## 
##  @param [s] The sequence of bytes containing the character.
##  @param [n] The maximum number of bytes to inspect.
##  @return The width, in columns, of the UTF-8 character, or -1 if the
##          character is unprintable or cannot be decoded.
## 

proc u8cwidth*(s: cstring; n: csize): cint {.cdecl, importc: "neo4j_u8cwidth",
                                       dynlib: libneo4j.}
## *
##  Return the Unicode codepoint of a UTF-8 character.
## 
##  @param [s] The sequence of bytes containing the character.
##  @param [n] A ponter to a `size_t` containing the maximum number of bytes
##         to inspect. On successful return, this will be updated to contain
##         the number of bytes consumed by the character.
##  @return The codepoint, or -1 if a decoding error occurs (errno will be set).
## 

proc u8codepoint*(s: cstring; n: ptr csize): cint {.cdecl, importc: "neo4j_u8codepoint",
    dynlib: libneo4j.}
## *
##  Return the column width of a Unicode codepoint.
## 
##  @param [cp] The codepoint value.
##  @return The width, in columns, of the Unicode codepoint, or -1 if the
##          codepoint is unprintable.
## 

proc u8cpwidth*(cp: cint): cint {.cdecl, importc: "neo4j_u8cpwidth", dynlib: libneo4j.}
## *
##  Return the column width of a UTF-8 string.
## 
##  @param [s] The UTF-8 encoded string.
##  @param [n] The maximum number of bytes to inspect.
##  @return The width, in columns, of the UTF-8 string.
## 

proc u8cswidth*(s: cstring; n: csize): cint {.cdecl, importc: "neo4j_u8cswidth",
                                        dynlib: libneo4j.}

# Initialise the client for use
let init_result = client_init()
assert init_result == 0
