#!/usr/bin/python

from pymine.mine import Mine

if __name__ == '__main__':

    user = "alecm"
    m = Mine(user)

    t = m.items.Open(30)
    v = t.Get('itemName')
    print v
