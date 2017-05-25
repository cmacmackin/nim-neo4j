#
#  exceptions.nim
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

## This module contains the core driver exceptions.

import tables, strutils

type
  ## Raised when a network address is invalid.
  AddressError* = object of Exception

  ## Raised when an unexpected or unsupported protocol event occurs.
  ProtocolError* = object of Exception

  ## Raised when no database service is available.
  ServiceUnavailable* = object of Exception

  ## Raised when an action is denied due to security settings.
  SecurityError* = object of Exception

  ## Raised when the Cypher engine returns an error to the client.
  CypherError* = object of Exception
    message*: string
    code*: string
    classification*: string
    category*: string
    title*: string
    metadata*: Table[string, string]

  ## The Client sent a bad request - changing the request might yield
  ## a successful outcome.
  ClientError* = object of CypherError

  ## The datbase failed to service the request
  DatabaseError* = object of CypherError

  ## The database cannot service the request right now, retrying later
  ## might yield a successful outcome.
  TransientError* = object of CypherError

  ConstraintError* = object of ClientError

  CypherSyntaxError* = object of ClientError

  CypherTypeError* = object of ClientError

  Forbidden* = object of ClientError

  ## Raised when authentication failure occurs.
  AuthError* = object of ClientError

    
proc getClientError(code: string): ClientError =
  case code
  of "Neo.ClientError.Schema.ConstraintValidationFailed":
    result = ConstraintError()
  of "Neo.ClientError.Schema.ConstraintViolation":
    result = ConstraintError()
  of "Neo.ClientError.Statement.ConstraintVerificationFailed":
    result = ConstraintError()
  of "Neo.ClientError.Statement.ConstraintViolation":
    result = ConstraintError()
  of "Neo.ClientError.Statement.InvalidSyntax":
    result = CypherSyntaxError()
  of "Neo.ClientError.Statement.SyntaxError":
    result = CypherSyntaxError()
  of "Neo.ClientError.Procedure.TypeError":
    result = CypherTypeError()
  of "Neo.ClientError.Statement.InvalidType":
    result = CypherTypeError()
  of "Neo.ClientError.Statement.TypeError":
    result = CypherTypeError()
  of "Neo.ClientError.General.ForbiddenOnReadOnlyDatabase":
    result = Forbidden()
  of "Neo.ClientError.General.ReadOnly":
    result = Forbidden()
  of "Neo.ClientError.Schema.ForbiddenOnConstraintIndex":
    result = Forbidden()
  of "Neo.ClientError.Schema.IndexBelongsToConstraint":
    result = Forbidden()
  of "Neo.ClientError.Security.Forbidden":
    result = Forbidden()
  of "Neo.ClientError.Transaction.ForbiddenDueToTransactionType":
    result = Forbidden()
  of "Neo.ClientError.Security.AuthorizationFailed":
    result = AuthError()
  of "Neo.ClientError.Security.Unauthorized":
    result = AuthError()
  else:
    result = ClientError()


## Instantiates an error of the appropriate type.
proc hydrateError*(message: string = "An unknown error occurred.",
                   code: string = "New.DatabaseError.General.UnknownError",
                   metadata: Table[string, string] =
                   initTable[string, string](0)): CypherError =
  let errcode = code.split(".")
  var classification, category, title: string
  if errcode.len == 4:
    classification = "DatabaseError"
    category = "General"
    title = "UnknownError"
  else:
    classification = errcode[1]
    category = errcode[2]
    title = errcode[3]
  case classification
  of "ClientError":
    result = getClientError(code)
  of "DatabaseError":
    result = DatabaseError()
  of "TransientError":
    result = TransientError()
  else:
    result = CypherError()
  result.message = message
  result.code = code
  result.classification = classification
  result.category = category
  result.title = title
  result.metadata = metadata
