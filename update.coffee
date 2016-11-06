# Run this to update completions stored in the completions.json
path = require 'path'
fs = require 'fs'
request = require 'request'
cheerio = require 'cheerio'

referenceURL = 'https://docs.oracle.com/javase/8/javafx/api/javafx/scene/doc-files/cssref.html'

fetch = ->
  request {url: referenceURL}, (error, response, reference) ->
    if error?
      console.error(error.message)
      return

    if response.statusCode isnt 200
      console.error("Request for JavaFX CSS Reference Guide failed: #{response.statusCode}")
      return

    html = cheerio.load(reference)
    rows = html(".csspropertytable tr")
    completions = {
      properties: Collect(rows, GetProperty),
      pseudoSelectors: Collect(rows, GetSelector),
      classes: Collect(html(".styleclass"), GetClass)
    }
    fs.writeFileSync(path.join(__dirname, 'completions.json'), "#{JSON.stringify(completions, null, '  ')}\n")

Collect = (rows, getter) ->
  dict = {}
  dict[item.name] = item for item in (getter(row) for row in rows) when item?
  delete item.name for name, item of dict
  dict

GetProperty = (row) ->
  name = cheerio("td.propertyname", row)
  value = cheerio("td.value", row)
  {
    name: Text(name),
    values: val for val in Text(value).split(" ") when not /[<>|,=]|\[|\]|\//.test(val)
    description: Text(cheerio("td:nth-child(4)", row))
  } if name.length and value.length

GetSelector = (row) ->
  name = cheerio("td.propertyname", row)
  {
    name: ":" + Text(name),
    description: Text(cheerio("td:nth-child(2)", row))
  } if name.length and cheerio("td", row).length is 2

GetClass = (row) ->
  name = Text(cheerio(row)).replace("Style class:", "").trim()
  {name: name} unless /\s+|\./.test(name)

Text = (node) -> node.text().replace(/\s+/g, " ").trim()

fetch()
