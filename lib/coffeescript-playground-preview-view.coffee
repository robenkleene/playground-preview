{ScrollView} = require 'atom'

module.exports =
class PlaygroundPreviewView extends ScrollView
  @content: ->
    @div class: 'playground-preview native-key-bindings', tabindex: -1

  constructor: (@editorId) ->
    super
    @resolveEditor(@editorId)

  serialize: ->
    {@editorId, deserializer: @constructor.name}

  destroy: ->
    @unsubscribe()

  resolveEditor: (editorId) ->
    resolve = =>
      @editor = @editorForId(editorId)

      if @editor?
        @trigger 'title-changed' if @editor?
        @handleEvents()
      else
        # The editor this preview was created for has been closed so close
        # this preview since a preview cannot be rendered without an editor
        @parents('.pane').view()?.destroyItem(this)

    if atom.workspace?
      resolve()
    else
      @subscribe atom.packages.once 'activated', =>
        resolve()
        @renderPlayground()

  editorForId: (editorId) ->
    for editor in atom.workspace.getEditors()
      return editor if editor.id?.toString() is editorId.toString()
    null

  handleEvents: ->
    @subscribe this, 'core:move-up', => @scrollUp()
    @subscribe this, 'core:move-down', => @scrollDown()

    changeHandler = =>
      @renderPlayground()
      pane = atom.workspace.paneForUri(@getUri())
      if pane? and pane isnt atom.workspace.getActivePane()
        pane.activateItem(this)

    if @editor?
      @subscribe @editor.getBuffer(), 'contents-modified', =>
        changeHandler() if atom.config.get 'playground-preview.liveUpdate'
      @subscribe @editor, 'path-changed', => @trigger 'title-changed'
      @subscribe @editor.getBuffer(), 'reloaded saved', =>
        changeHandler() unless atom.config.get 'playground-preview.liveUpdate'

  renderPlayground: ->
    console.log "Rendering"

  getTitle: ->
    if @editor?
      "#{@editor.getTitle()} Preview"
    else
      "Playground Preview"

  getIconName: ->
    "markdown" # TODO Replace with langauges icon

  getUri: ->
    "playground-preview://editor/#{@editorId}"