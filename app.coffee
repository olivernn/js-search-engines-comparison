React = require 'react'
superagent = require 'superagent-promise'

{div, input, strong} = React.DOM

# libraries
sifter   = require 'sifter'
lunr     = require 'lunr'
fuzzyset = require 'fuzzyset.js'

# strings
superagent.get('corpus.csv').end()
.then((res) -> res.text.split('\n'))
.then((words) ->
  window.words = words

  indexes =
    fuzzyset: fuzzyset words
    sifter: new sifter ({id: word} for word in words)
    lunr: lunr ->
      @field 'word'
      @ref 'word'

  for word in words
    indexes.lunr.add {word: word}
  indexes
)
.then((indexes) ->
  React.render React.createElement(Main, {indexes: indexes}), document.getElementsByTagName('main')[0]
).catch((x) -> console.log x)

Main = React.createClass
  getInitialState: ->
    results: {}

  render: ->
    (div {},
      (input
        onChange: @search
        ref: 'input'
        style: {display: 'block', clear: 'both'}
      )
      (div {},
        (div {style: {float: 'left', width: '30%'}},
          (strong {}, indexname)
          (div {},
            "#{item.score}: #{item.id}"
          ) for item in @state.results[indexname] or []
        ) for indexname of @props.indexes
      )
    )

  search: (e) ->
    q = React.findDOMNode(@refs.input).value
    @setState
      results:
        fuzzyset: ({score: i[0], id: i[1]} for i in ((@props.indexes.fuzzyset.get q) or [])).slice(0, 100)
        sifter: ({score: i.score, id: words[i.id]} for i in (@props.indexes.sifter.search q, fields: ['id'], limit: 100).items)
        lunr: ({score: i.score, id: i.ref} for i in @props.indexes.lunr.search q).slice(0, 100)
