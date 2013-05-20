# SnippetTreeNode
# ---------------
# Represents a node in a SnippetTree
#
# Every node has a parent node, possibly siblings and multiple
# ChildContainers. ChildContainers are the parents of the
# child nodes, not the TreeNode itself.
#
# E.g. a grid row would have as many ChildContainers as it has
# columns

class SnippetTreeNode

  constructor: ({ parentContainer, snippet }) ->
    error("Missing param parentContainer") if !parentContainer?
    error("Missing param snippet") if !snippet?

    @setParent(parentContainer) if parentContainer
    @snippet = snippet
    @snippet.snippetTreeNode = this
    @next = undefined
    @previous = undefined


  # return an array of all parents in snippetTree
  # (starting from the top)
  parents: () ->
    #todo


  setParent: (parentContainer) ->
    @parentContainer = parentContainer
    @snippetTree = parentContainer?.snippetTree
    @ #chaining


  # @param snippet: Snippet or SnippetTreeNode instance
  before: (snippet) ->
    if snippet
      treeNode = @parentContainer.attachSnippet(snippet)
      treeNode.previous = @previous
      treeNode.next = this
      @previous = treeNode

      if treeNode.isFirst()
        @parentContainer.first = treeNode

      @ #chaining
    else
      @previous


  # @param snippet: Snippet or SnippetTreeNode instance
  after: (snippet) ->
    if snippet
      treeNode = @parentContainer.attachSnippet(snippet)
      treeNode.previous = this
      treeNode.next = @next
      @next = treeNode

      if treeNode.isLast()
        @parentContainer.last = treeNode

      @ #chaining
    else
      @next


  # move up (previous)
  up: () ->
    if @previous?
      previous = @previous
      @unlink()
      previous.before(this)

    @ #chaining


  # move down (next)
  down: () ->
    if @next?
      next = @next
      @unlink()
      next.after(this)

    @ #chaining


  isFirst: () ->
    !@previous?


  isLast: () ->
    !@next?


  # remove TreeNode from its container and SnippetTree
  unlink: () ->

    # update parentContainer links
    @parentContainer.first = @next if @isFirst()
    @parentContainer.last = @previous if @isLast()

    # update previous and next nodes
    @next?.previous = @previous
    @previous?.next = @next

    @previous = undefined
    @next = undefined
    @setParent(undefined)

    @ #chaining

