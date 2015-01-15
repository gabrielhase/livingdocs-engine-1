$ = require('jquery')
JsLoader = require('./js_loader')
CssLoader = require('./css_loader')
Semaphore = require('../modules/semaphore')

module.exports = class Assets

  # @param {Window}
  # @param {Boolean} optional. If set to true no assets will be loaded.
  constructor: ({ @window, disable }) ->
    @isDisabled = disable || false

    @cssLoader = new CssLoader(@window)
    @jsLoader = new JsLoader(@window)


  loadDependencies: (dependencies, callback) ->
    semaphore = new Semaphore()
    semaphore.addCallback(callback)
    for dep in dependencies.js
      @loadJs(dep, semaphore.wait())

    for dep in dependencies.css
      @loadCss(dep, semaphore.wait())

    semaphore.start()


  loadDependency: (dependency, callback) ->
    if dependency.isJs()
      @loadJs(dependency, callback)
    else if dependency.isCss()
      @loadCss(dependency, callback)


  loadJs: (dependency, callback) ->
    return callback()  if @isDisabled

    if dependency.inline
      @jsLoader.loadInlineScript(dependency.code, callback)
    else
      @jsLoader.loadSingleUrl(dependency.src, callback)


  loadCss: (dependency, callback) ->
    return callback()  if @isDisabled

    if dependency.inline
      @cssLoader.loadInlineStyles(dependency.code, callback)
    else
      @cssLoader.loadSingleUrl(dependency.src, callback)



