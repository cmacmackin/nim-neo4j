#
#  tests/config.nim
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

import macros, os

const tdir {.strdefine.} = "."

proc testdir: string =
  if tdir[^1] == '/':
    result = tdir[0..^2]
  else:
    result = tdir

macro includeModules: untyped =
  ## Includes all of the other nim modules in this directory and its
  ## subdirectories.
  var files = ""
  
  for file in walkDirRec(tdir):
    if file[^4..^1] == ".nim" and file != testdir() & "/all_tests.nim":
      if files.len != 0:
        files.add(", ")
      files.add(file[testdir().len+1..^5])
  if files.len != 0:
    result = parseStmt("include " & files)
    
includeModules
