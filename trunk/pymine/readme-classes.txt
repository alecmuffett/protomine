things
	new
	list
	exists(id)
	named(string)
	select(searchcontext)
thing
	__read_trim = sub
	__read_verbatim = sub
	__keyre = '';
	id # returns 
	name # returns name as string
	items # list of keyfiles in the dir, matching __keyre
	commit # updates utimes on a 'stamp' file
	delete # renames 42 to 42~
	get('key') -> __getitem__ # returns param object
	getfile('key')
	set('key', 'value') -> __setitem__
	setfile('key', file)
	map_key('key', 'value')
	unmap_key('key', 'value')
	exists_key('key')
	compare -> __cmp__
	to_string -> __repr__
	lock? 
	unlock?
	created
	last_modified
	last_accessed
param					### THIS NEEDS WORK
	.key
	.value
	.type
	.size
	.lastmodified

relations(things)

relation(thing)
	__keyre = r'^relation\w+';
	map_key
	unmap_key
	version
	get_interests

items(things)

item(thing)
	__keyre = r'^(item\w+|data)$';
	map_key
	unmap_key
	match_interests
	to_atom

tags(things)

tag(thing)
	__keyre = r'^tag\w+';
	map_key
	unmap_key

comments(things)

comment(thing)
	__keyre = r'^comment\w+';

config(thing) # no configs object
	__keyre = r'^(\w+\.)*\w+$';

searchctx
cgictx
interestctx

crypto
	reset
	encrypt(plaintext)
	decrypt(ciphertext)
	digest(plaintext)
	checksum(plaintext)

minekey
	validate
	newfromencoded
	newfromrelation
	encode
	readable
	permalink
	spawn_oid
	spawn_object
	spawn_submit
	spawn_rewrite

page

log
	message
	error

------------------------------------------------------------------

