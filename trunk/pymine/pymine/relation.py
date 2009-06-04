import Thing

class Relation(Thing):

    """..."""
    keyPrefix = 'relation'
    keyRegexp = '^relation[A-Z]'
    keyNamesUnique = True
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

class Relations(Things):

    """..."""

    subpath = "relations"
    genclass = Relation

    def __init__(self, mine):
	"""..."""
	Things.__init__(self, mine)
	pass
