# Internals

Some of the material I am adding is too implementation-ish or internals-ish to really belong in a reference doc,
even a draft.  This doc is for that stuff.

## Phases

The higher layer which parses the LUIF is called the Kollos Higher Layer, or KHIL.  It has (at least conceptually)
two subphases.

* Translate the EBNF in the LUIF to pure Lua, created a "pure Lua" file.

* Run the "pure Lua file" to create the Kollos Intermediate Representation (KIR),
  which is a Lua table.
  
For each subphase the output can be a editable file.  This is useful for
maintenance, debugging, etc.

## The "pure Lua" file

In the pure lua file all BNF rules
```
     x ::= a b c
```
are converted to calls to a KHOL method:
```
    -- Line 42, column 0:
    -- x :: a b c
    luif_self:rule_parse(luif_self.text.location(798,813))
```
The location is passed as a location object.  The original text is shown
as a comment.  This is not necessary but will be useful when the file is
for debugging, tracing, etc.

## The Kollos Intermediate Representation

This is a Lua table.  Jeffrey does not have full details yet, but here's the
general idea.  The KHOL's cetnral job is to translate the LUIF rules from
an external extended BNF representation, to an internal representation which
is plain BNF.

That table has one key per grammar.  The value for each grammar
key is a table, with keys `xsym`, `isym`, `xrule`, `irule`.  These are,
respectively, external symbol, internal symbol, external rule,
internal rule.  Here "external" means it is in the LUIF as provided
by the user, and "internal" means that it belongs to the internal
representation.

These values
are also tables, indexed by symbol name in the case of the symbols, and
rule ID (an integer) in the case of rules.  The symbol and rule entries contain the
information needed for the KLOL to do its work.  Jeffrey expects to create
examples of what is desired as a by-product of his work on the KLOL.

## Location objects

Location is provided via objects, which have the following
methods:

* `blob` -- the blob name.  Required.
  Archetypally a file name, but not all
  locations will be in files.  Blob name must be suitable for
  appearing in messages.

* `start()` and `end()` -- start and end positions.  Length of the
  text will be `end - start`.

* `range()` -- start and end positions as a two-element array.

* `text()` -- the text from start to end.  LUIF source follows Lua
  restrictions, which means no Unicode.

* `line_column(pos)` -- given a position, of the sort returned
  by `start()` and `end()`, returns the position in a more
  convenient representation.  What is "more convenient"
  depends on the class of the blob, but typically this will be
  line and column.

* `sublocation()` -- the current location within the
   blob in form suitable for an error
  message.

* `location()` -- the current location, including the
  blob name.

### Implementation

Location objects are intended to serve a wide variety of purposes.
They will contain the actual source text, with a "cursor" indicating
current location.
They can also be location stamps, accompanying rules,
symbols, etc., for use in error messages, tracing, etc.
Factory methods will allow live cursors to be created from
stamps, and vice versa.

Implementation can be very efficient.  The constant
data: blob name, text, methods, goes into a prototype,
which is pointed to by the `__index` metamethod.
Into the object itself goes, depending on its use,
a "current" cursor location, and a "start" and "end"
stamp.

Line/column data goes into the prototype, but is
computed "just in time".  It is still considered
"constant" because it is "created on read",
and its value will never vary.
