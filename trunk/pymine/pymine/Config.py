class Config(Thing):

    """..."""
    keyPrefix = 'config'
    keyRegexp = '^config[A-Z]'
    keyNamesUnique = True
    # -> keysuffix : ( isReadOnly, isRequired, isOneLine, isVirtual, enumeration )
    keySettings = {
	'Id' : ( True, True, True, True, None ),
	'Name' : ( False, True, True, False, None ),
	}

    def __init__(self, mine):
	"""..."""
	Thing.__init__(self, mine, 0)
	pass
