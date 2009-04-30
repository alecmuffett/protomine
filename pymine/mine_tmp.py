#!/usr/bin/python

##################################################################

class Things:
    """base class for directory of things"""

    def __init__():
        """-"""
        pass

    def new():
        """-"""
        pass

    def list():
        """-"""
        pass

    def exists(id):
        """-"""
        pass

    def named(string):
        """-"""
        pass

    def named_1(string):
        """-"""
        pass

    def select(searchctx):
        """-"""
        pass

    def lock():
        """-"""
        pass

    def unlock():
        """-"""
        pass

##################################################################

class Thing:
    """base class for a thing"""

    # master table for all keys, their types and qualities
    #
    # ro => readonly, not settable
    # reqd => must be set else failure on commit
    # virt => virtual, does not map to a file
    # blob => treat as blob of octets, not as a line of text
    # range => permitted values as tuple of integers (rendered to text using remap_*)

    key_info = {
        'Id':    dict(  ro=True,   reqd=True,  virt=False,  blob=False,  enum=None  ),
        'Name':  dict(  ro=False,  reqd=True,  virt=False,  blob=False,  enum=None  ),
        }

    # prefix for each of the above (thingName, etc)
    key_prefix = 'thing'

    # is thingName required to be unique across all Things
    bool_unique_names = True

    # regexp to match legal Thing keys
    key_regexp = '^thing[A-Z]'

    # api-hardcoded keynames
    key_id = ''
    key_name = ''

    # instantiation setup
    def __init__(self):
        """-"""
        pass

    def id():
        """-"""
        return self.get(key_id)

    def name():
        """-"""
        return self.get(key_name)

    def keys():
        """-"""
        pass

    def commit():
        """-"""
        pass

    def delete():
        """-"""
        pass

    def has(key):
        """-"""
        return True

    def map_in(key, value):
        """-"""
        if key == 'dummy1':
            pass
        elif key == 'dummy2':
            pass
        else:
            return value

    def get(key): # __get_item__
        """-"""
        pass

    def map_out(key, value):
        """-"""
        if key == 'dummy1':
            pass
        elif key == 'dummy2':
            pass
        else:
            return value

    def set(key, value): # __set_item__
        """-"""
        pass

    def compare(thing): # __cmp__
        """-"""
        pass

    def to_string(): # -> __repr__
        """-"""
        pass

##################################################################

class fmeta:
    lastmodified = None
    created = None
    size = None
    path = None
    name = None
    type = None

##################################################################

if __name__ == '__main__':
    pass

##################################################################
