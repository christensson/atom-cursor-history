debug = (msg) ->
  return unless atom.config.get('cursor-history.debug')
  console.log msg

module.exports =
class History
  constructor: (max) -> @initialize(max)
  clear: -> @initialize(@max)

  initialize: (max) ->
    @index   = 0
    @entries = []
    @max     = max

  isNewest: -> @isEmpty() or @index >= @entries.length - 1
  isOldest: -> @isEmpty() or @index is 0
  isEmpty:  -> @entries.length is 0

  get: (index) -> @entries[index]
  getCurrent:  -> @get(@index)
  getNext:     -> @get(@index + 1)
  getPrev:     -> @get(@index - 1)
  getLastURI:  -> @getPrev()?.getProperties().URI

  next: ->
    if @isNewest()
      debug "# Newest"
      @dump() if atom.config.get('cursor-history.debug')
      return
    @index += 1
    @dump() if atom.config.get('cursor-history.debug')
    @getCurrent()

  prev: ->
    if @isOldest()
      debug "# Oldest"
      @dump() if atom.config.get('cursor-history.debug')
      return
    @index -= 1
    @dump() if atom.config.get('cursor-history.debug')
    @getCurrent()

  isHead: ->
    @index is @entries.length

  remove: (index) ->
    @entries.splice(index, 1)[0]

  add: (marker) ->
    unless @isHead()
      debug "# Concatenating history"
      tail = @entries.slice(@index)
      # Need copy Marker to avoid destroyed().
      tail = tail.map (marker) -> marker.copy()

      # This deletion is depends on preference, make it configurable?
      @entries.splice(@index, 1)

      @entries.pop()
      @entries = @entries.concat tail.reverse()

    oldMark = @entries[@entries.length-1]
    unless marker.isEqual(oldMark)
      debug "-- save"
      @entries.push marker
    else
      debug "-- skip"

    if @entries.length > @max
      markers = @entries.splice(0, @entries.length - @max)
      for marker in markers
        marker.destroy()

    @index = @entries.length

  pushToHead: (marker) ->
    @entries.push marker
    @dump() if atom.config.get('cursor-history.debug')

  inspectMarker: (marker) ->
    "#{marker.getStartBufferPosition().toString()}, #{marker.getProperties().URI}"

  dump: ->
    currentValue = if @getCurrent() then @inspectMarker(@getCurrent()) else @getCurrent()
    console.log " - index #{@index} #{currentValue}"
    entries = @entries.map(
      ((e, i) ->
        if i is @index
          "> #{i}: #{@inspectMarker(e)}"
        else
          "  #{i}: #{@inspectMarker(e)}"), @)
    entries.push "> #{@index}:" unless currentValue

    console.log entries.join("\n")

  serialize: () ->
