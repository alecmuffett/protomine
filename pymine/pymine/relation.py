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

class Relation(Thing):

    """..."""
    keyPrefix = 'relation'
    keyRegexp = '^relation[A-Z]'
    keyNamesUnique = True
    # -> keysuffix : ( isReadOnly, isRequired, isOneLine, isVirtual, enumeration )
    keySettings = {
	'CallbackURL' : ( False, False, True, False, None, 'optional URL for mine callbacks' ),
	'Description' : ( False, False, False, False, None, 'description of this relation (multiline, HTML)' ),
	'EmailAddress' : ( False, False, True, False, None, 'e-mail address to contact this relation' ),
	'EmbargoAfter' : ( False, False, True, False, None, 'optional date after which this relation is treated as invalid' ),
	'EmbargoBefore' : ( False, False, True, False, None, 'optional date before which this relation is treated as invalid' ),
	'HomepageURL' : ( False, False, True, False, None, 'optional URL relating to this relation (eg: homepage, blog)' ),
	'Id' : ( True, True, True, True, None, 'unique numeric identifier for this relation' ),
	'ImageURL' : ( False, False, True, False, None, 'optional URL for an icon for this relation' ),
	'Interests' : ( False, False, True, False, None, 'list of tags in which this relation is interested' ),
	'Name' : ( False, True, True, False, None, 'unique alphanumeric name for this relation' ),
	'NetworkAddress' : ( False, False, True, False, None, """optional feed firewalling, eg: '192.168.' or '172.16.2.3'""" ),
	'Version' : ( False, True, True, False, None, 'relationship revision number' ),
	}

    def __init__(self, aggregator, id):
	"""..."""
	Thing.__init__(self, aggregator, id)

##################################################################

class Relations(Things):

    """..."""

    subpath = "relations"
    genclass = Relation

    def __init__(self, mine):
	"""..."""
	Things.__init__(self, mine)
	pass
