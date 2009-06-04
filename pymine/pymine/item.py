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

class Item(Thing):

    """..."""
    keyPrefix = 'item'
    keyRegexp = '^item[A-Z]'
    keyNamesUnique = False
    # -> keysuffix : ( isReadOnly, isRequired, isOneLine, isVirtual, enumeration )
    keySettings = {
	'Id' : ( True, True, True, True, None ),
	'Name' : ( False, True, True, False, None ),
	'Status' : ( False, True, True, False, ( 0, 1, 2 ) ),
	}

    # itemStatus enumeration:
    # 0: private
    # 1: semiprivate
    # 2: private
    # 3: reserved0
    # 4: reserved1
    # 5: reserved2
    # 6: reserved3
    # 7: reserved4

    def __init__(self, parent):
	"""..."""
	Thing.__init__(self, parent)
	pass

##################################################################

class Items(Things):

    """..."""

    subpath = "items"
    genclass = Item

    def __init__(self, mine):
	"""..."""
	Things.__init__(self, mine)
	pass