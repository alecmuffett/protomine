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


