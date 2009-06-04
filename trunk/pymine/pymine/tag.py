import Thing

class Tag(Thing):

    """..."""
    keyPrefix = 'tag'
    keyRegexp = '^tag[A-Z]'
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

class Tags(Things):

    """..."""

    subpath = "tags"
    genclass = Tag

    def __init__(self, mine):
	"""..."""
	Things.__init__(self, mine)
	pass
