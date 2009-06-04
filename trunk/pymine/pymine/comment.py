#!/usr/bin/python
##
## Copyright 2009 Adriana Lukas & Alec Muffett
##
## Licensed under the Apache License, Version 2.0 (the "License"); you
## may not use this file except in compliance with the License. You
## may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
## implied. See the License for the specific language governing
## permissions and limitations under the License.
##

from thing import Thing, Things

class Comment(Thing):

    """..."""
    keyPrefix = 'comment'
    keyRegexp = '^comment[A-Z]'
    keyNamesUnique = False
    # -> keysuffix : ( isReadOnly, isRequired, isOneLine, isVirtual, enumeration )
    keySettings = {
	'Id' : ( True, True, True, True, None ),
	'Name' : ( False, True, True, False, None ),
	}

    def __init__(self, parent):
	"""..."""
	Thing.__init__(self, parent)
	pass

##################################################################

class Comments(Things):

    """..."""

    subpath = ".../comments" # fix this
    genclass = Comment

    def __init__(self, mine):
	"""..."""
	Things.__init__(self, mine)
	pass


