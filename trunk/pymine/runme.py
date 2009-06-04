if __name__ == '__main__':

    Thing.BOOT()
    Tag.BOOT()
    Relation.BOOT()
    Item.BOOT()
    Comment.BOOT()

    mine = Mine("alecm")

    print Thing.dictValidKey
    print Tag.dictValidKey
    print Relation.dictValidKey
    print Item.dictValidKey
    print Item.dictEnumeration
    print Comment.dictValidKey
