isGen = (f) ->
  f? and f.constructor.name is 'GeneratorFunction'

isIter = (f) ->
  f? and f.constructor.name is 'GeneratorFunctionPrototype'

class Seq
  constructor: (it) ->
    if isGen it
      @_it = it()
    else if isIter
      @_it = it
    else
      throw new Error 'Seq requires a generator'
    @_hd = @_dne = {}

  head: ->
    if @_hd is @_dne and @_it
      {value, done} = @_it.next()
      if done
        s = seq value
        if s
          {@_hd, @_tl, @_it, @_dne} = s
      else
        @_hd = value
    if @_hd is @_dne
      null
    else
      @_hd

  tail: ->
    @head()
    if @_it
      {value, done} = @_it.next()
      if done
        @_tl = seq value
      else
        @_tl = new Seq @_it
        @_tl._hd = value
      @_it = null
    @_tl
    
  seq: ->
    @head()
    if @_hd is @_dne
      null
    else
      this
    

  toString: ->
    s = '('
    rs = @seq()
    while rs
      s += head rs
      if tail rs
        s += ' '
      rs = tail rs
    s + ')'
    

arraySeq = (ary) ->
  return null if ary.length is 0
  new Seq ->
    yield v for v in ary
    null


head = (s) ->
  r = seq s
  return null unless r
  r.head()

tail = (s) ->
  r = seq s
  return null unless r
  r.tail()


seq = (s) ->
  if not s?
    null
  else if s instanceof Seq
    s.seq()
  else if s instanceof Array
    arraySeq s
  else if isGen s
    (new Seq s).seq()
  else
    throw new Error "cannot construct seq from #{s}"

take = (n, s) ->
  return null if n <= 0
  r = seq s
  do (r) ->
    lazySeq ->
      i = 0
      while r and i < n
        yield head r
        r = tail r
        i += 1
      null

drop = (n, s) ->
  r = seq s
  do (r) ->
    lazySeq ->
      i = 0
      while r and i < n
        r = tail r
        i += 1
      r

lazySeq = (f) ->
  if isGen f
    new Seq f
  else
    new Seq ->
      yield null if false
      seq f()

partitionAll = (n, s) ->
  r = seq s
  return null unless r
  cons (take n, r), lazySeq(-> partitionAll n, (drop n, r))

foldl = (f, i, s) ->
  r = seq s
  return i unless r
  foldl f, f(head(r), i), tail r


foldr = (f, i, s) ->
  r = seq s
  return i unless r
  f(head(r), foldr(f, i, tail r))


cons = (hd, tl) ->
  lazySeq ->
    yield hd
    tl

map = (f, s) ->
  r = seq s
  do (r) ->
    lazySeq ->
      while r
        yield f head r
        r = tail r
      null

comp = (f, fs...) ->
  foldl (g, gs) ->
    (a) -> gs(g(a))
  , f, fs

range = (x, y) ->
  r = lazySeq ->
    i = 0
    loop
      yield i++
  if y?
    drop x, take y, r
  else if x?
    take x, r
  else r
    
print = (s) ->
  if typeof s?.toString is 'function'
    console.log s.toString()
  else
    console.log s

# m = map ((x) -> 2 * x), ->
#   console.log 'before'
#   yield 1
#   console.log 'middle'
#   yield 2
#   console.log 'after'
#   yield 3

# s = seq ->
#   console.log 'long running process'
#   yield 'first'
#   console.log 'another long one'
#   yield 'second'
#   seq [3,4]

# console.log s.toString()


module.exports = {Seq, isGen, isIter, seq, arraySeq, head, tail, map, tail, take, print, foldl, foldr, cons, partitionAll, drop, lazySeq, range}
