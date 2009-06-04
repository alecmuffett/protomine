from thing import Thing, Things
from tag import Tag, Tags
from relation import Relation, Relations
from item import Item, Items
from comment import Comment, Comments
from config import Config
from cache import Cache

import os

class Mine:
    """the master container-object for a per-username Mine"""

    # boot the Thing classes once, and once only
    Thing.BOOT()
    Tag.BOOT()
    Relation.BOOT()
    Item.BOOT()
    Comment.BOOT()
    Config.BOOT()

    def __init__(self, username):
	"""initialise a mine for user 'username'"""

	# who am i?
	self.username = username

	# where shall we find the Things?
	self.path = os.path.join("database", username)

	# hack for Config to become a Thing without an aggregator
	self.mine = self

	# primary importance: configuration
	self.config = Config(self)

	# secondary importance: cache (so the rest can reference it)
	self.cache = Cache(self)

	# the remainder; items come last, and have comments beneath them
	self.tags = Tags(self)
	self.relations = Relations(self)
	self.items = Items(self)

    def Import(self, file):
	"""returns nothing, imports into a new mine the zipfile referenced by 'file'"""
	pass

    def Export(self, file, srchctx):
	"""returns a filehandle on a zipfile representing the mine with items represented by srchctx, or all if None"""
	pass
