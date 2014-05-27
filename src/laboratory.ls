
Fs = require \fs
Path = require \path
assert = require \assert

# p$ = require \procstreams
# Ini = require \ini
# Github = require \github
Walk = require \walkdir
LiveScript = require \livescript
LSAst = require \livescript/lib/ast

# instead of doing source maps like this,
# I will definitely want to be doing this:
# https://github.com/blendmaster/LiveScript/tree/esprima
# { SourceMapGenerator, SourceMapConsumer, SourceNode } = require \source-map-cjs
# { SourceMapGenerator } = require \source-map-cjs

{ _, ToolShed, Fsm } = MachineShop = require \MachineShop
{ Debug } = ToolShed
Config = ToolShed.Config

# { PublicDB, Blueprint } = require Path.join __dirname, \.. \.. \Blueshift \src \db

# WIP
# 1. set git ini based on argv
# 2. integrate it with github
# 2a. api usage for each user (stored in .Laboratory)
# 3. make it a verse
# 4. integrate this deeply with sencillo

# small things:
# 1. save the prompt responses to a json file (to avoid always asking them again - later, move this over to verse)
# 2. upgrade `Program.choose` to be nice and colorful like in `n`
# 3. check for README.md
# 4. compile package.json.ls
# --> keep a record of those being watched..

# exec osascript -e "delay .5" -e "tell application "node-webkit" to activate"

_log = console.log

echo = ->
	str = ''
	_.each &, (s) ->
		str += if typeof s is \object then JSON.stringify s else s + ' '
	console.log str

debug = Debug 'laboratory'

process.on \uncaughtException (e) ->
	debug "uncaught exception %s %s", e, e.stack
	if e+'' isnt \nothing
		console.log "ERRROR '#{e+''}'"
		console.log if e.stack then e.stack else "error: " +e
		console.log "\n"
		# TODO: log this to the verse error log

# INCOMPLETE: save the keys in here too
# this should be stored in Mongo, I think...


# XXX: remove me and abstract this... this is for testing only
#db = PublicDB {name: \poem}

# XXX: move this over to sencillo/publicdb
#class Doc extends Fsm

# this is just testing for now...
# soon it'll be integrated into Verse
Verse = {
	prompt: (txt, data, fn) ->
		if typeof data is \function
			fn = data
		else if Array.isArray data
			_.each data, fn
		else
			fn data
		show_prompt = (prompt) ->
			console.log "#{prompt} PROMPT:", txt, data
}

CWD = process.cwd! #Path.resolve \..

class Laboratory extends Fsm
	(@refs, @opts) ~>
		unless typeof opts is \object
			throw new Error "Laboratory opts must be an object"

		@prjs = []
		super 'Laboratory'


	initialize: -> echo "Loading Vulcrum's Lare..."

	eventListeners:
		user: (user) ->

	states:
		uninitialized:
			onenter: ->
				ToolShed.searchDownwardFor 'laboratory.json', (@opts.config_path || process.cwd!), (err, path) ~>
					assert this instanceof Laboratory
					if err
						@transition \setup
					else
						cfg = ToolShed.Config path
						cfg.once \ready ~>
							assert this instanceof Laboratory
							@CONFIG = cfg
							@CONFIG.path = @path = Path.dirname path
							@transition \load

		load:
			onenter: ->
				task = @task 'loading...'
				task.push "loading user", (done) ->
					console.log "user:", user = @opts.user, @CONFIG.user
					ask_user = Verse.prompt "user:", (user = @opts.user || @CONFIG.user), (res) ~>
						assert this instanceof Laboratory
						if typeof res is \string
							if typeof (u = @CONFIG.users[res]) is \object
								@CONFIG.user = res
								@USER = u
								@emit \notify, "loading user #{u.github.user}"
								done!
							else ask_user "user doesn't exist"
						else if typeof res is \object
							#TODO: these should use mongoose/PublicDB model verification
							# mun = new Mun res
							if typeof res.name is \string and typeof res.git is \object
								# we're just gonna assume everything is all verified for now
								@CONFIG.users[res.name] = res
								done!
							else "unknown object format or data"
						else ask_user "unknown input"
					#echo "XXX: prompt for the user. grab the zigzags. grab the glock. a mac.\nsome niggaz be cranked out. some be dranked out. I be danked out.\nthis is hamsta mutha fuckin nipples .. wit some heat 4 yo azz"
					#setTimeout ~>
					#	echo("tickedy tacky tack toe, that's some LOLz fo yo motha fuckin ho")
					#, 5000
					ask_user "please type your user"

				task.choke "getting lab path" (done) ~>
					dir = @opts.path || @CONFIG.path || Path.join ToolShed.HOME_DIR, 'Projects'
					ask_path = Verse.prompt "Laboratory Projects path:", dir, (res) ~>
						if typeof res is \string
							ToolShed.stat res, (err, st) ~>
								if err
									if err.code is \ENOENT
										echo "TODO: ask the user if they want to create the path?"
										#@transition \setup
								else if st.isDirectory!
									@CONFIG.path = res
									done!
								else ask_path "path exists already but isn't a directory"
						else ask_path "unknown input"
					#TODO: do a quick check to see if HOME_DIR/Projects exists
					ask_path "where is your Laboratory located?"


				task.end ->
					path = @CONFIG.path
					@debug "using path %s", path
					#process.chdir path
					@watcher := Fs.watch path, (evt, filename) ~>
						console.log "lab disturbance", &
						if evt is \change
							console.log "change event", &
						else if evt is \rename
							#@prjs.push new Project {path: path}
							new_prj_path = Path.join path, filename
							offset = false
							_.each @prjs, !(prj, i) ~>
								if prj.path is new_prj_path
									offset := i
									return false
							ToolShed.stat new_prj_path, (err, st) ~>
								if offset is false and not err and st.isDirectory!
									@exec \add_project filename, new_prj_path
									# @prjs.push prj = new Project {path: new_prj_path, name: filename}, {lab: lab}
									# prj.once_initialized ~>
									# 	@emit \added, prj
								else
									@prjs[offset].transition \close
									@prjs.splice offset, 0
					walker = Walk path, max_depth: 1
					walker.on \directory (path, st) ~>
						# this should create a Project which is really an extension of Repository
						# which will in turn, create a src dir, an app.nw, etc.
						basename = Path.basename path
						if ~(@USER.projects.indexOf basename)
							@exec \add_project, basename, path
					walker.on \end ~>
						@transition \ready

		ready:
			onenter: ->
				@emit \ready
				echo "XXX: TODO ... walk the dirs and shit"

			switch_user: (user) ->
				echo "TODO: switch user"
				prj_watcher.close!

			add_project: (name, path) ->
				@debug "add project #name - #path"
				@prjs.push prj = new Project {lab: @}, {
					name
					path
				}
				prj.until \ready ~>
					# console.log "------------------------prj.once_initialized", prj.namespace
					# console.log "lab.eventListeners",
					# console.log "prj.once_initialized", prj.namespace
					@emit \new:Project, prj

			remove_project: (name) ->
				console.error "TODO: "

		setup:
			onenter: -> echo "XXX: TODO ... set this shit up!!"

		close:
			onenter: ->
				prj_watcher.close!
				_.each @prjs, !(prj, i) ~>
					prj.transition \close
					@prjs[offset].transition \close
					@prjs.splice i, 0


# things I'd like to add soon:
# 1. automatic project file conacatenation
# 1a. self reconfiguration (auto-reload when this file changes)
# 2. js ast transforms (falafel)
# 3. ls ast transforms (sweat ast manipulation)
# 4. npm module resolution (and host recompilation)
# 5. manifest file creation
# 6. release / zip file creation, etc.
# 7. src file based on a URI (for automatic file location resolution!!)
# 7a. file support (TODO)
# 7b. http/Request support (TODO)
# 7c. github support
# 7d. ssh and other protocols too
# 8. github hooks for receiving repo changes

# node-webkit interface:
# 1. tons of stuff, duh!

# current bugs:
# 1. for some strange reason, one time, it gave me a file rename, when the file already existed or something like that (race condition???)
# 2.

# current improvements:
# 1. automatically add index.js.ls which with either:
#  a. put exports for each of the files in src/*.ls
#  b. if concat is enabled, it'll just concat all src/* files into the resulting index.js

# quick note, I do track the package.json, but it should be dynamically configurable
# pkg_json.on \change:modules ... add a new module, etc.
# pkg_json.on \change:name ... change the project name, etc.
# pkg_json.on \change:version ... make a release, etc.
# see where I'm going here??

class Project extends Fsm
	(@refs, @opts) ->
		assert refs.lab instanceof Laboratory
		if typeof opts isnt \object
			throw new Error "you must pass an options object {name: '...', path: '...'}"
		unless opts.path
			throw new Error "you need a path for your project"
		else if opts.name
			opts.path = Path.join refs.lab.path, opts.name

		if typeof refs isnt \object
			throw new Error "you must pass in a reference to the lab"

		@lab = refs.lab
		@path = Path.resolve opts.path
		@name = opts.name
		unless @path => throw new Error "invalid path #{opts.path}"

		src_dir = Path.join @path, \src
		lib_dir = Path.join @path, \lib

		# if not opts.src_dir and not opts.src_dirs
		# 	opts.src_dirs = [\src]
		# if not opts.lib_dir
		# 	opts.lib_dir = \lib
		# if not ~opts.lib_dir.indexOf path
		# 	opts.lib_dir = Path.join path, \lib

		# if not ~opts.lib_dir.indexOf path
		# 	opts.lib_dir = Path.join path, \lib

		super "Project(#{opts.name})"

	# name: opts.name
	# path: path
	dirs: {}
	# FUTURE: convert this into a command:
	states:
		uninitialized:
			onenter: ->
				pkg_src_path = Path.join @path, "package.json.ls"
				pkg_json_path = Path.join @path, "package.json"
				pkg = @PACKAGE = Config pkg_json_path

				pkg.once \ready (config, data) ~>
					unless data
						pkg.name = @name or Path.basename @path
						pkg.version = '0.0.1'

					if sencillo = pkg.sencillo
						if sencillo.srcdirs
							for k, sdir of sencillo.srcdirs
								@exec \add_dir, k, sdir.into, sdir
					else
						src_dir = Path.join @path, \src
						lib_dir = Path.join @path, \lib
						@exec \add_dir, \src, src_dir, lib_dir
					@transition \ready

		ready:
			onenter: ->
				@emit \ready

			add_dir: (name, path, into, opts) ->
				essential_opts = {path: path, into: into}
				# console.log "add dir #name - #path -> #into"
				@dirs[name] = src_dir = new SrcDir {prj: @}, (
					if typeof opts is \object
						essential_opts <<< opts
					else
						essential_opts
				)
				src_dir.once_initialized ~>
					# console.log "once_initialized SrcDir", @namespace
					# console.log "eventListeners", @eventListeners
					@emit \new:SrcDir, src_dir


		new:
			onenter: ->
				/*
				pkg_src = Src {
					path: pkg_src_path
					output: "name: 'untitled'"
					write: path
					watch: true
				}
				*/
				pkg.name = opts.name or Path.basename @path
				pkg.version = '0.0.1'


class SrcDir extends Fsm
	(@refs, @opts) ->
		assert refs.prj instanceof Project
		if typeof opts isnt \object
			throw new Error "SrcDir needs an object"
		if typeof opts.path isnt \string
			throw new Error "path must be provided"

		@dirs = {}
		@srcs = {}

		super "#{refs.prj.name}::SrcDir(#{Path.relative refs.prj.path, opts.path})"

	states:
		uninitialized:
			onenter: ->
				if @opts.into
					ToolShed.mkdir @opts.into, (err) ~>
						if err
							@emit \error new Error "SrcDir already exists"
							@transition \error
				else @opts.into = @opts.path

				if @opts.st and @opts.st.isDirectory!
					@transition \ready
					@exec \walk
				else Fs.stat @opts.path, (err, st) ~>
					if err
						if err.code is \ENOENT
							ToolShed.mkdir @opts.path, (err) ~>
								@emit \error err
								@transition \error
						else
							@emit \error, err
							@transition \error
					else if st.isDirectory!
						@transition \ready
						@exec \walk
					else
						@emit \error new Error "SrcDir already exists"
						@transition \error

		ready:
			onenter: ->
				@emit \ready

			rescan: ->
				console.log "XXX: we should be rescanning now"

			walk: ->
				@watcher = Fs.watch @opts.path, (evt, filename) ~>
					echo "disturbance", evt, filename, @opts.path
					if evt is \change
						if filename and s = @srcs[filename]
							s.exec \read
						else _.each @srcs, (s) ~>
							s.exec \check
					else if evt is \rename
						console.log "XXX: src file renaming not yet supported!!", &
						unless filename
							@transition \walk
						else
							if s = @srcs[filename]
								s.transition \destroy
								delete @srcs[filename]
							else if s = @dirs[filename]
								s.transition \destroy
								delete @dirs[filename]
							else
								path = Path.join @opts.path, filename
								Fs.stat path, (err, st) ~>
									unless err
										if st.isFile!
											switch ext = Path.extname filename
											#| \.ls \.coffee \.js => @srcs.push Src path, st
											#| \.ls => @srcs[filename] = new Src {path, file: filename, write: @opts.into, st, dir}
											| \.ls => @exec \add_src filename, path, @opts.into, st
										else if st.isDirectory!
											into_dir = Path.join @opts.into, filename
											@exec \add_dir filename, path, into_dir

				process.nextTick ~>
					d = Walk @opts.path, max_depth: 1
					d.on \error (err) ~>
						console.log "we got an error:", &
						# throw err
					d.on \end ~>
						@transition \ready
					d.on \file (path, st) ~>
						file = Path.basename path
						unless @srcs[file]
							switch ext = Path.extname file
							#| \.ls \.coffee \.js => @srcs.push Src path, st
							#| \.ls => @srcs[file] = new Src {path, file, write: @opts.into, st, dir}
							| \.ls => @exec \add_src file, path, @opts.into, st
					d.on \directory (path, st) ~>
						dir_name = Path.basename path
						into_dir = Path.join @opts.into, dir_name
						@exec \add_dir dir_name, path, into_dir

			add_src: (name, path, into, st) ->
				#TODO: check to see if src already exists
				# console.log "add src #name - #path -> #into"
				if @dirs[name]
					throw new Error "dir: #{name} already exists"
				@srcs[name] = src = new Src {prj: @refs.prj, dir: @}, {
					path
					file: name
					write: into
					st
				}
				src.once_initialized ~>
					assert this instanceof SrcDir
					# console.log "once_initialized Src", @namespace
					@emit \new:Src, src

			add_dir: (name, path, into) ->
				#TODO: check to see if src_dir already exists
				# console.log "add dir #name - #path -> #into"
				if @dirs[name]
					throw new Error "dir: #{name} already exists"
				@dirs[name] = src_dir = new SrcDir {prj: @refs.prj, dir: @}, {
					name
					path
					into
				}
				src_dir.once_initialized ~>
					assert this instanceof SrcDir
					# console.log "once_initialized SrcDir ...", @namespace
					@emit \new:SrcDir, src_dir

		close:
			onenter: ->
				@watcher.close!
				console.log "closing..."
				_.each @dirs, (d, k) ~>
					d.transition \close
					delete @dirs[k]
				_.each @srcs, (s, k) ~>
					s.transition \close
					delete @srcs[k]
				@emit \closed


class Src extends Fsm
	(@refs, @opts) ->
		assert refs.prj instanceof Project
		assert refs.dir instanceof SrcDir
		if typeof opts is \string => opts = {path: opts}
		else if typeof opts is \object
			if typeof @opts.path isnt \string
				throw new Error "Src must have at least a path"
		else throw new Error "Src not initialized correctly"

		outfile = file = Path.basename opts.path
		opts.lang = switch Path.extname file
		| \.ls => \LiveScript
		| \.coffee => \coffee-script
		| \.js => \js
		| \.json => \json

		unless opts.outfile
			if ~(idx_ext = file.lastIndexOf '.')
				ext = if opts.ext then opts.ext else file.substr idx_ext
				outfile = file.substr 0, idx_ext
				if ~(idx_ext2 = file.substr(0, idx_ext).lastIndexOf '.')
					ext = if opts.ext then opts.ext else file.substr idx_ext2
					outfile = file.substr 0, idx_ext2
				switch ext
				| '.blueprint.ls' =>
					opts.blueprint = true
					opts.result = true
					ext = \.blueprint
					#fallthrough
				| '.json.ls' =>
					opts.result = true
					opts.json = true
					ext = \.json
				| otherwise =>
					ext = ext.replace /(?:(\.\w+)?\.\w+)?$/, (r, ex) ~>
						if ex is \.json then opts.json = true
						return ex or if opts.json then \.json else \.js

				if ext isnt \.js and opts.result isnt false
					opts.result = true
				outfile = outfile + ext
			else if opts.ext
				outfile = file + opts.ext
			else
				throw new Error "source file does not have an extension"

			opts.ext = ext
			opts.outfile = Path.join(opts.write, outfile)

		super "#{refs.prj.name}::Src(#{Path.relative refs.prj.path, opts.path})"

	eventListeners:
		transition: ->
			@debug "transition path %s %s", @opts.path, @namespace

	states:
		uninitialized:
			onenter: ->
				if typeof @opts.st is \object and @opts.st.mtime instanceof Date
					@transition \ready
					@exec if @opts.src => \compile else \read
				else Fs.stat @opts.path, (err, st) ~>
					if err
						if err.code is \ENOENT
							# IMPROVEMENT: use the user's default template for the file?
							@opts.src = ''
							now = new Date
							@st = {mtime: now, ctime: now}
							@transition \ready
						else throw err
					else
						@st = st
						@transition \ready
						@exec \read

		ready:
			onenter: ->
				if @opts.watch and not @watcher
					@watcher = Fs.watchFile @opts.path, (evt) ~>
						@debug "file %s changed %s", file, @path
						@exec \read
				@emit \ready

			read: ->
				Fs.readFile @opts.path, 'utf-8', (err, data) ~>
					if err
						@transition \error
					else if @opts.src isnt data or true
						@opts.src = data
						@exec \compile

			check: ->
				console.log "what are we checking???"
				try
					throw new Error "..."
				catch e
					console.log e.stack

			compile: ->
				try
					patch_ast = LiveScript.ast LiveScript.tokens "Mongoose = require 'Mongoose'"
					patch = patch_ast.toJSON!

					search_ast = LiveScript.ast LiveScript.tokens "Mongoose = require 'Mongooses'"
					search = search_ast.toJSON!
					j1 = JSON.stringify search.lines .replace /[,]*\"line\":[0-9]+/g, ''
					searchlen = search.lines.length

					options = {bare: true}
					@opts.tokens = LiveScript.tokens @opts.src
					@opts.ast = LiveScript.ast @opts.tokens

					if @opts.outfile is 'model.js'
						#console.log "ast", @opts.ast
						ast = JSON.parse JSON.stringify @opts.ast.toJSON!
						if global.window
							global.window.ast = @opts.ast

						for i til width = ast.lines.length - searchlen
							# OPTIMIZE: this probably has to be the SLOWEST way to do do patching
							# IMPROVEMENT: I also want to improve patching, by maintaining variable names and the like
							# IMPROVEMENT: I want to search based on a certain pattern and replace based on that pattern
							l1 = ast.lines.slice i, i+searchlen
							j2 = JSON.stringify l1 .replace /[,]*\"line\":[0-9]+/g, ''
							if j1 is j2
								console.log "found target at line #", i
								ast.lines.splice.apply this, [i, searchlen] ++ patch.lines
								@opts.ast = LSAst.fromJSON ast
						#livescript.ast(livescript.tokens("\t\tif true then"))

					if @opts.result
						@opts.ast.makeReturn!

					@opts.output = @opts.ast.compileRoot options
					if @opts.result
						process.chdir Path.dirname @opts.path
						@opts.output = LiveScript.run @opts.output, options, true
						process.chdir CWD

					if @opts.blueprint
						@opts.output = ToolShed.stringify @opts.output, <[name encantador incantation version embodies poetry eventListeners layout]>
					else if @opts.json
						@opts.output = ToolShed.stringify @opts.output, <[name version]>

					@refs.prj.emit @opts.ext.substr(1), @opts.outfile, @opts.output
					if @opts.write
						Fs.writeFile @opts.outfile, @opts.output, (err) ~>
							if err
								@emit \error, new Error "unable to write output to #{@opts.outfile}"
								@transition \error
							else
								@debug "wrote %s", @opts.outfile
								@emit \success message: "compiled: '#{@opts.outfile}' successfully"
								@transition \ready
					else
						@transition \ready
				catch e
					if ~e.message.indexOf 'Parse error'
						console.log @opts.path, ':', e.message
					else
						console.log @opts.path, ':', e.stack
					@emit \error, e
					@transition \error

		destroy:
			onenter: ->
				if s = @watcher then s.close!
				Fs.unlink @opts.outfile, (err) ~>
					if err and err.code isnt \ENOENT
						@emit \error err
					@emit \closed

		close:
			onenter: ->
				@emit \closed

/*

lab = new Fsm {
	initialize: ->
		echo "welcome to my laboratory!"

	states:
		uninitialized:
			onenter: ->
				# ...
				ToolShed.mkdir LAB_PATH, (res) ->
					if res instanceof Error
						lab.emit \error, "could not initialize data directory!"
						lab.transition \error
					else if typeof res is \string
						# newly created, initialize the dir
						lab.transition \add_user
					else lab.transition \load_user

		init_repo:
			onenter: ->

		load_user:
			onenter: ->
				if lab.user
					console.log 'TODO:get user data from the data store'

				else
					#echo "choose your character"
					user_list = Object.keys USERS
					Program.choose user_list.concat('New character'), (i) ->
						if i is user_list.length
							console "NEW USER!"
							console "INCOMPLETE!!"
						else if u = user_list[i]
							user = USERS[u]
							echo "you choose", i, user
							# check to see if git is configured in this directory
							if user.git or user.github or user.gitlab
								Fs.readFile "./.git/config", 'utf-8', (err, data) ->
									#console.log "readfile", &
									if err
										if err.code is \ENOENT
											# not a git repository
											Program.confirm "git repository does not exist. create one?", (ok) ->
												if ok
													echo "initializing git..."
													task = lab.task 'init dir'
													task.push (done) ->
														p$ 'git init'
															.on \exit, (code) ->
																if code
																	emit \error, err = new Error "we could not init the git repository for some reason..."
																	lab.transition \error
																done err
													#p$ 'touch README.md'
													task.push (done) ->
														ToolShed.mkdir './src', done
													task.push (done) ->
														ToolShed.mkdir './lib', done
													#task.push (done) ->
													#	Updater {}
													#	Repository {}

												else
													echo "ok, no need for a repository then..."
									else
										# read the ini file
										console.log "TODO: read the ini file"
										lab._git_config = Ini.parse data
										console.log "INI", lab._git_config
										lab.transition \check_git_config
							else
								@emit \error "unidentified user type"
								@transition \error


		check_git_config:
			onenter: ->
				#console.log PACKAGE.git
				git_config = lab._git_config
				if typeof git_config is \object
					unless _.isEqual gv = user.user, ini.user
						debug "different users!"
						if typeof gv is \object
							ini.user <<< gv
							console.log "writing ..."
							ToolShed.writeFile Path.join(".git", \config), Ini.stringify ini
		add_user:
			onenter: ->
				echo "create an account"
				Program.choose [
					"GitHub user"
					"GitLab user"
				], (i) ->
					switch i
					| 0 \github =>

					| 1 \gitlab =>
}

class User
	(manifest) ->
		console.log "welcome!"

*/
export Laboratory
export Project
export SrcDir
export Src

