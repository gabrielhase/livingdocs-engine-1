deepEqual = require('deep-equal')
config = require('../configuration/config')
SnippetContainer = require('./snippet_container')
guid = require('../modules/guid')
log = require('../modules/logging/log')
assert = require('../modules/logging/assert')
directiveFactory = require('./snippet_directive_factory')
DirectiveCollection = require('../template/directive_collection')

# SnippetModel
# ------------
# Each SnippetModel has a template which allows to generate a snippetView
# from a componentModel
#
# Represents a node in a SnippetTree.
# Every SnippetModel can have a parent (SnippetContainer),
# siblings (other snippets) and multiple containers (SnippetContainers).
#
# The containers are the parents of the child SnippetModels.
# E.g. a grid row would have as many containers as it has
# columns
#
# # @prop parentContainer: parent SnippetContainer
module.exports = class SnippetModel

  constructor: ({ @template, id } = {}) ->
    assert @template, 'cannot instantiate snippet without template reference'

    @initializeDirectives()
    @styles = {}
    @dataValues = {}
    @id = id || guid.next()
    @componentName = @template.name

    @next = undefined # set by SnippetContainer
    @previous = undefined # set by SnippetContainer
    @snippetTree = undefined # set by SnippetTree


  initializeDirectives: ->
    @directives = new DirectiveCollection()

    for directive in @template.directives
      switch directive.type
        when 'container'
          @containers ||= {}
          @containers[directive.name] = new SnippetContainer
            name: directive.name
            parentSnippet: this
        when 'editable', 'image', 'html'
          @createSnippetDirective(directive)
          @content ||= {}
          @content[directive.name] = undefined
        else
          log.error "Template directive type '#{ directive.type }' not implemented in SnippetModel"


  # Create a directive for 'editable', 'image', 'html' template directives
  createSnippetDirective: (templateDirective) ->
    @directives.add directiveFactory.create
      snippet: this
      templateDirective: templateDirective


  createView: (isReadOnly) ->
    @template.createView(this, isReadOnly)


  # SnippetTree operations
  # ----------------------

  # Insert a snippet before this one
  before: (componentModel) ->
    if componentModel
      @parentContainer.insertBefore(this, componentModel)
      this
    else
      @previous


  # Insert a snippet after this one
  after: (componentModel) ->
    if componentModel
      @parentContainer.insertAfter(this, componentModel)
      this
    else
      @next


  # Append a snippet to a container of this snippet
  append: (containerName, componentModel) ->
    if arguments.length == 1
      componentModel = containerName
      containerName = config.directives.container.defaultName

    @containers[containerName].append(componentModel)
    this


  # Prepend a snippet to a container of this snippet
  prepend: (containerName, componentModel) ->
    if arguments.length == 1
      componentModel = containerName
      containerName = config.directives.container.defaultName

    @containers[containerName].prepend(componentModel)
    this


  # Move this snippet up (previous)
  up: ->
    @parentContainer.up(this)
    this


  # Move this snippet down (next)
  down: ->
    @parentContainer.down(this)
    this


  # Remove this snippet from its container and SnippetTree
  remove: ->
    @parentContainer.remove(this)


  # SnippetTree Iterators
  # ---------------------
  #
  # Navigate and query the snippet tree relative to this snippet.

  getParent: ->
     @parentContainer?.parentSnippet


  parents: (callback) ->
    componentModel = this
    while (componentModel = componentModel.getParent())
      callback(componentModel)


  children: (callback) ->
    for name, snippetContainer of @containers
      componentModel = snippetContainer.first
      while (componentModel)
        callback(componentModel)
        componentModel = componentModel.next


  descendants: (callback) ->
    for name, snippetContainer of @containers
      componentModel = snippetContainer.first
      while (componentModel)
        callback(componentModel)
        componentModel.descendants(callback)
        componentModel = componentModel.next


  descendantsAndSelf: (callback) ->
    callback(this)
    @descendants(callback)


  # return all descendant containers (including those of this componentModel)
  descendantContainers: (callback) ->
    @descendantsAndSelf (componentModel) ->
      for name, snippetContainer of componentModel.containers
        callback(snippetContainer)


  # return all descendant containers and snippets
  allDescendants: (callback) ->
    @descendantsAndSelf (componentModel) =>
      callback(componentModel) if componentModel != this
      for name, snippetContainer of componentModel.containers
        callback(snippetContainer)


  childrenAndSelf: (callback) ->
    callback(this)
    @children(callback)


  # Directive Operations
  # --------------------
  #
  # Example how to get an ImageDirective:
  # imageDirective = componentModel.directives.get('image')

  hasContainers: ->
    @directives.count('container') > 0


  hasEditables: ->
    @directives.count('editable') > 0


  hasHtml: ->
    @directives.count('html') > 0


  hasImages: ->
    @directives.count('image') > 0


  # set the content data field of the snippet
  setContent: (name, value) ->
    if not value
      if @content[name]
        @content[name] = undefined
        @snippetTree.contentChanging(this, name) if @snippetTree
    else if typeof value == 'string'
      if @content[name] != value
        @content[name] = value
        @snippetTree.contentChanging(this, name) if @snippetTree
    else
      if not deepEqual(@content[name], value)
        @content[name] = value
        @snippetTree.contentChanging(this, name) if @snippetTree


  set: (name, value) ->
    assert @content?.hasOwnProperty(name),
      "set error: #{ @componentName } has no content named #{ name }"

    directive = @directives.get(name)
    if directive.isImage
      if directive.getImageUrl() != value
        directive.setImageUrl(value)
        @snippetTree.contentChanging(this, name) if @snippetTree
    else
      @setContent(name, value)


  get: (name) ->
    assert @content?.hasOwnProperty(name),
      "get error: #{ @componentName } has no content named #{ name }"

    @directives.get(name).getContent()


  # Check if a directive has content
  isEmpty: (name) ->
    value = @get(name)
    value == undefined || value == ''


  # Data Operations
  # ---------------
  #
  # Set arbitrary data to be stored with this componentModel.


  # can be called with a string or a hash
  data: (arg) ->
    if typeof(arg) == 'object'
      changedDataProperties = []
      for name, value of arg
        if @changeData(name, value)
          changedDataProperties.push(name)
      if @snippetTree && changedDataProperties.length > 0
        @snippetTree.dataChanging(this, changedDataProperties)
    else
      @dataValues[arg]


  # @api private
  changeData: (name, value) ->
    if not deepEqual(@dataValues[name], value)
      @dataValues[name] = value
      true
    else
      false


  # Style Operations
  # ----------------

  getStyle: (name) ->
    @styles[name]


  setStyle: (name, value) ->
    style = @template.styles[name]
    if not style
      log.warn "Unknown style '#{ name }' in SnippetModel #{ @componentName }"
    else if not style.validateValue(value)
      log.warn "Invalid value '#{ value }' for style '#{ name }' in SnippetModel #{ @componentName }"
    else
      if @styles[name] != value
        @styles[name] = value
        if @snippetTree
          @snippetTree.htmlChanging(this, 'style', { name, value })


  # @deprecated
  # Getter and Setter in one.
  style: (name, value) ->
    console.log("SnippetModel#style() is deprecated. Please use #getStyle() and #setStyle().")
    if arguments.length == 1
      @styles[name]
    else
      @setStyle(name, value)


  # SnippetModel Operations
  # -----------------------

  copy: ->
    log.warn("SnippetModel#copy() is not implemented yet.")

    # serializing/deserializing should work but needs to get some tests first
    # json = @toJson()
    # json.id = guid.next()
    # SnippetModel.fromJson(json)


  copyWithoutContent: ->
    @template.createModel()


  # @api private
  destroy: ->
    # todo: move into to renderer

