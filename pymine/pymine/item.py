import Thing

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
