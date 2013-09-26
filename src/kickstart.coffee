kickstart = do ->

  init: (destination, design) ->
    domElements = $(destination).children().not('script')
    $(destination).html('<div class="doc-section"></div>')

    if not doc.document.initialized
      doc.init(design: design)
      doc.ready =>
        @addRootSnippets(domElements)

    else
      @addRootSnippets(domElements)

  addRootSnippets: (domElements) ->
    domElements.each (index, element) =>
      row = doc.add(@nodeToSnippetName(element))
      @setChildren(row, element)


  populateSnippetContainers: (snippet, data) ->
    containers = if snippet.containers then Object.keys(snippet.containers) else []
    if containers.length == 1 && containers.indexOf('default') != -1 && !$(data).children('default').length
      for child in $(data).children()
        @appendSnippetToContainer(snippet, child, 'default')

    for editableContainer in $(containers.join(','), data)
      for child in $(editableContainer).children()
        @appendSnippetToContainer(snippet, child, editableContainer.localName)


  appendSnippetToContainer: (parentContainer, data, region) ->
    snippetName = @nodeToSnippetName(data)
    snippet = doc.create(snippetName)
    parentContainer.append(region, snippet)

    if snippetName == 'title'
      data = $.parseHTML("<div>#{data.text}</div>")[0]

    @setChildren(snippet, data)


  setChildren: (snippet, data) ->
    @populateSnippetContainers(snippet, data)
    @setEditables(snippet, data)


  getValueForEditable: (key, editableData, snippet) ->
    if key == 'image'
      # TODO: make a test - image innerHTML can't work
      child = editableData.querySelector('img')?.innerHTML

    else if key == 'title'
      log.warn("Your design contains an editable named '#{key}'. This can cause unexpected results due to some Browser limitations.")
      child = editableData.querySelector(key)?.text

    else
      child = editableData.querySelector(key)?.innerHTML

    if !child
      log.warn("The editable '#{key}' of '#{snippet.identifier}' has no content. Display parent HTML instead.")
      child = editableData.innerHTML

    child


  setEditableStyles: (snippet, name, styleclass) ->
    snippet.style(name, styleclass)


  setEditables: (snippet, data) ->
    for key of snippet.content
      snippet.set(key, null)
      child = @getValueForEditable(key, data, snippet)
      snippet.set(key, child)

    styles = $(data).attr('data-doc-styles') || $(data).attr('doc-styles')
    if styles
      styles = styles.split(';')
      styles.forEach (style) =>
        style = style.split(':')
        @setEditableStyles(snippet, style[0], style[1])



  # Convert a dom element into a camelCase snippetName
  nodeToSnippetName: (element) ->
    snippetName = $.camelCase(element.localName)
    snippet = doc.getDesign().get(snippetName)

    # check deprecated HTML elements that automatically convert to new element name.
    if snippetName == 'img' && !snippet
      snippetName = 'image'
      snippet = doc.document.design.get('image')

    assert snippet,
      "The Template named '#{snippetName}' does not exist."

    snippetName
