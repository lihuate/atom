_ = require 'underscore'

Extension = require 'extension'
TreePane = require 'tree/tree-pane'
Watcher = require 'watcher'

fs = require 'fs'

module.exports =
class Tree extends Extension
  ignorePattern: /\.git|\.xcodeproj|\.DS_Store/

  # a path is an object with three keys: label, path, and paths.
  # paths is an optional Array of other path objects.
  paths: []

  constructor: ->
    atom.keybinder.load require.resolve "tree/key-bindings.coffee"

    # watch the root dir
    Watcher.watch atom.path, @watchDir

    # Hide dirs that no longer exist, watch dirs that do.
    for dir in @shownDirs()
      if not fs.exists dir
        @hideDir dir
      else
        Watcher.watch dir, @watchDir

    @paths = @findPaths atom.path
    @pane = new TreePane @

  startup: ->
    @pane.show()

  shutdown: ->
    @unwatchDir atom.path
    @unwatchDir dir for dir in @shownDirs()

  reload: ->
    @pane.reload()

  shownDirStorageKey: ->
    @.constructor.name + ":" + atom.path + ":shownDirs"

  watchDir: (changeType, dir) =>
    # Update the paths
    @paths = @findPaths atom.path
    @pane.reload()

  unwatchDir: (dir) ->
    Watcher.unwatch dir, @watchDir

  shownDirs: ->
    atom.storage.get @shownDirStorageKey(), []

  showDir: (dir) ->
    dirs = @shownDirs().concat dir
    atom.storage.set @shownDirStorageKey(), dirs
    Watcher.watch dir, @watchDir

  hideDir: (dir) ->
    dirs = _.without @shownDirs(), dir
    atom.storage.set @shownDirStorageKey(), dirs
    @unwatchDir dir, @watchDir

  findPath: (searchPath, paths=@paths) ->
    found = null
    for obj in paths
      return found if found
      if obj.path is searchPath
        found = obj
      else if obj.paths
        found = @findPath searchPath, obj.paths
    found

  findPaths: (root) ->
    paths = []

    for path in fs.list root
      continue if @ignorePattern.test path
      paths.push
        label: _.last path.split '/'
        path: path
        paths: @findPaths path if fs.isDirectory path

    paths
