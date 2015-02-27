{isGen, isIter} = require './gen'

class Seq

  count: ->
    s = @seq()
    c = 0
    while s
      if s.count is @count
        c++
      else
        return c + s.count()
      s = s.tail()
    c

  toString: ->
    s = '('
    rs = @seq()
    while rs
      s += rs.head()
      if rs.tail()
        s += ' '
      rs = rs.tail()
    s + ')'

class EmptyList extends Seq
  head: ->
    null

  rest: ->
    this

  tail: ->
    null

  count: ->
    0

  seq: ->
    null

  toString: ->
    '()'

EMPTY = new EmptyList()

class ArraySeq extends Seq
  constructor: (@ary, @i) ->
    @i ?= 0

  head: ->
    @ary[@i]

  tail: ->
    if @i + 1 < @ary.length
      new ArraySeq(@ary, @i + 1)
    else
      null

  rest:
    @tail ? EMPTY

  count: ->
    @ary.length - @i

  seq: ->
    if @count is 0
      null
    else
      this


class Cons extends Seq
  constructor: (@_head, @_tail) ->
    throw new Error "cannot create seq from #{@_tail}" unless isSeq @_tail

  head: ->
    @_head

  rest: ->
    @_tail ? EMPTY

  tail: ->
    @rest().seq()

  seq: ->
    this

class LazySeq extends Seq
  constructor: (it) ->
    if isGen it
      @_it = it()
    else if isIter it
      @_it = it
    else
      throw new Error 'LazySeq requires a generator'

  seq: ->
    if @_it
      {value, done} = @_it.next()
      if done
        @_seq = seq value
      else
        @_seq = new Cons value, new LazySeq @_it
      @_it = null
    @_seq

  count: ->
    @seq()
    count @_seq

  head: ->
    @seq()
    if @_seq
      @_seq.head()
    else
      null

  rest: ->
    @seq()
    return EMPTY unless @_seq
    @_seq.rest()

  tail: ->
    @seq()
    return null unless @_seq
    @_seq.tail()

module.exports = {
  Seq
  ArraySeq
  LazySeq
  Cons
  isSeq: (s) ->
    not s? or s instanceof Seq

  seq: (s) ->
    if not s?
      null
    else if s instanceof Seq
      s.seq()
    else if s instanceof Array
      return null unless s.length
      new ArraySeq s
    else if isGen s
      (new LazySeq s).seq()
    else
      throw new Error "cannot construct seq from #{s}"

  lazySeq: (f) ->
    if isGen f
      new LazySeq f
    else
      new LazySeq ->
        yield null if false
        f()

  count: (s) ->
    return 0 unless s?
    seq(s).count()

  head: (s) ->
    return null unless s?
    seq(s).head()
  tail: (s) ->
    return null unless s?
    seq(s).tail()
  rest: (s) ->
    return EMPTY unless s?
    seq(s).rest()

  print: (o) ->
    if typeof o?.toString is 'function'
      console.log o.toString()
    else
      console.log o
}
