
Fs = require \fs
Path = require \path

p$ = require \procstreams
Ini = require \ini
Github = require \github
Program = require \commander
Walk = require \walkdir
LiveScript = require \livescript
LSAst = require \livescript/lib/ast

{ _, ToolShed, Fsm, Debug } = MachineShop = require \MachineShop

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

LAB_PATH = Path.join process.env.HOME, '.Laboratory'
LAB_CONFIG_PATH = Path.join LAB_PATH, \config

# INCOMPLETE: save the keys in here too
# this should be stored in Mongo, I think...

# XXX: DELETE ME BEFORE GOING PUBLIC
testing_repos = <[
	Laboratory
	Archivista
	Mental
	Upgrader
	Blueshift
	node-sencillo
	MachineShop
]>


Program
	.version \0.1.0
	.option '-u, --user', "github user"
	.parse process.argv



# TODO FOR v0.1.0:
# 1. read the config file (~/.Laboratory/config/env.json)
# 2. multiple users (~/.Laboratory/users/{user}/env.json)
# 3.

#mongoose = require 'mongoose'
#Schema = mongoose.Schema
#ObjectId = Schema.Types.ObjectId

#class Laboratory extends Fsm



export Laboratory = (opts, refs) ->
	debug = Debug 'Laboratory'

	unless typeof opts is \object
		throw new Error "Laboratory opts must be an object"

	user = opts.user
	console.log "using user", user
	console.log "github:", user.github.user

	#unless path = opts.path
	#	throw new Error "you gatta provide a path!!!!!"

	lab = new Fsm 'Laboratory' {
		prjs: []
		initialize: -> echo "Loading Vulcrum's Lare..."

		states:
			uninitialized:
				_onEnter: ->
					ToolShed.mkdir LAB_CONFIG_PATH, (err, dir) ->
						if err => throw err
						else if typeof dir isnt \string
							#ToolShed.Config Path.join LAB_CONFIG_PATH, "env.json"
							lab.transition \load
						else
							lab.transition \setup

			load:
				_onEnter: ->
					unless user
						echo "XXX: prompt for the user. grab the zigzags. grab the glock. a mac.\nsome niggaz be cranked out. some be dranked out. I be danked out.\nthis is hamsta mutha fuckin nipples .. wit some heat 4 yo azz"
						setTimeout ->
							echo("tickedy tacky tack toe, that's some LOLz fo yo motha fuckin ho")
						, 5000
						return setTimeout ->
							throw new Error "lol..."
						, 8000
					else
						echo "Greetings everyone, '#{user.github.user}' here"
						echo "Welcome to my laboratory..."
						lab.path = path = user.path
						#process.chdir path
						Fs.watch path, (evt, filename) ->
							console.log "lab disturbance", &
							if evt is \change
								console.log "change event", &
							else if evt is \rename
								console.log "rename event", &
						walker = Walk user.path, max_depth: 1
						walker.on \directory (path, st) ->
							# this should create a Project which is really an extension of Repository
							# which will in turn, create a src dir, an app.nw, etc.
							if ~(testing_repos.indexOf Path.basename path)
								#lab.prjs.push new Project {path: path}
								new Project {path: path}, {lab: lab}
						walker.on \end ->
							lab.transition \ready

					/*
					dir = Walk path, max_depth: 1
					dir.on \directory (path, st) ->
						echo "d:", path
						#Fs.watch path,
					dir.on \file (path, st) ->
						#echo "f:", path
						o = {}
						f = Path.basename path
						if ~(ext = f.indexOf '.')
							Fs.readFile path, 'utf-8', (err, data) ->
								switch (ext = f.substr ext)
								| '.json.ls' => LiveScript.compile data, bare: true
								| '.ls' => LiveScript.compile data, bare: true
								| '.coffee' => console.log "XXX: coffeescript not yet implemented"
								| '.json.coffee' => console.log "XXX: coffeescript not yet implemented"
					*/

			ready:
				_onEnter: -> echo "XXX: TODO ... walk the dirs and shit"


			setup:
				_onEnter: -> echo "XXX: TODO ... set this shit up!!"77
	}

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


Project = (opts, refs) ->
	unless opts.path
		throw new Error "you need a path for your project"
	else if opts.name
		opts.path = Path.join refs.lab.path, opts.name

	path = opts.path
	lab = refs.lab
	src_dir = Path.join path, \src
	lib_dir = Path.join path, \lib

	prj = new Fsm {
		initialize: -> echo "new Project!!"
		dirs: {}
		opts: opts
		states:
			uninitialized:
				_onEnter: ->
					pkg_src_path = Path.join path, "package.json.ls"
					pkg_json_path = Path.join path, "package.json"
					ToolShed.readFile pkg_json_path, 'utf-8', (err, data) ->
						if err
							if err.code is \ENOENT
								console.log "TODO: prompt the user for the project name"
								pkg_src = Src {
									path: pkg_src_path
									output: "name: 'untitled'"
									write: path
									watch: true
								}
							else
								prj.emit \error, err
								prj.transition \error
						else
							try
								json = JSON.parse data
								prj.name = json.name
								# .. get the rest of the data from the package

							catch e
								prj.emit \error, e
								prj.transition \error
							Fs.stat pkg_src_path, (err, st) ->
								unless err and st.isFile!
									pkg_src = Src {
										path: pkg_src_path
										write: path
										watch: true
										st: st
									}
									prj.transition \loaded
									# it might be useful to provide livescript output `Config` here...

			loaded:
				_onEnter: ->
					#prj.dirs.push new SrcDir {path: path, into: into_dir}
					prj.dirs.src = new SrcDir {path: src_dir, into: lib_dir}
					prj.transition \ready

			ready:
				_onEnter: ->
					lab.prjs.push prj
					lab.emit \added, prj
					console.log "totally ready"


	}

	return prj


SrcDir = (opts, refs) ->
	if typeof opts isnt \object
		throw new Error "SrcDir needs an object"
	if typeof opts.path isnt \string
		throw new Error "path must be provided"

	debug = Debug 'SrcDir'
	dir = new Fsm "SrcDir(#{Path.relative process.cwd!, opts.path})" {
		initialize: -> echo "loading dir:", opts.path
		dirs: {}
		srcs: {}
		opts: opts
		refs: refs
		states:
			uninitialized:
				_onEnter: ->
					if opts.into
						ToolShed.mkdir opts.into, (err) ->
							if err
								dir.emit \error new Error "SrcDir already exists"
								dir.transition \error
					else opts.into = opts.path

					if opts.st and opts.st.isDirectory!
						dir.transition \walk
					else Fs.stat opts.path, (err, st) ->
						if err
							if err.code is \ENOENT
								ToolShed.mkdir opts.path, (err) ->
									dir.emit \error err
									dir.transition \error
							else
								dir.emit \error, err
								dir.transition \error
						else if st.isDirectory!
							dir.transition \walk
						else
							dir.emit \error new Error "SrcDir already exists"
							dir.transition \error

			walk:
				_onEnter: ->
					@watcher = Fs.watch opts.path, (evt, filename) ->
						echo "disturbance", evt, filename
						if evt is \change
							if filename and s = dir.srcs[filename]
								s.transition \read
							else _.each dir.srcs, (s) -> s.transition \check
						else if evt is \rename
							console.log "XXX: src file renaming not yet supported!!", &
							unless filename
								dir.transition \walk
							else
								if s = dir.srcs[filename]
									s.transition \destroy
									delete dir.srcs[filename]
								else if s = dir.dirs[filename]
									s.transition \destroy
									delete dir.dirs[filename]
								else
									path = Path.join opts.path, filename
									Fs.stat path, (err, st) ->
										unless err
											if st.isFile!
												switch ext = Path.extname filename
												#| \.ls \.coffee \.js => dir.srcs.push Src path, st
												| \.ls => dir.srcs[filename] = Src {path, file: filename, write: opts.into, st, dir}
											else if st.isDirectory!
												into_dir = Path.join opts.into, filename
												dir.dirs[filename] = new SrcDir {path: path, into: into_dir}

					d = Walk opts.path, max_depth: 1
					d.on \error (err) ->
						console.log "we got an error:", &
						throw err
					d.on \end -> dir.transition \ready
					d.on \file (path, st) ->
						file = Path.basename path
						unless dir.srcs[file]
							switch ext = Path.extname file
							#| \.ls \.coffee \.js => dir.srcs.push Src path, st
							| \.ls => dir.srcs[file] = Src {path, file, write: opts.into, st, dir}
					d.on \directory (path, st) ->
						console.log "we have a directory!!", &
						dir_name = Path.basename path
						into_dir = Path.join opts.into, dir_name
						dir.dirs[dir_name] = new SrcDir {path: path, into: into_dir}

			ready:
				_onEnter: ->
					dir.emit \ready

				rescan: ->
					console.log "XXX: we should be rescanning now"

			close:
				_onEnter: ->
					@watcher.close!
					console.log "closing..."
					_.each dir.dirs, (d, k) ->
						d.transition \close
						delete dir.dirs[k]
					_.each dir.srcs, (s, k) ->
						s.transition \close
						delete dir.srcs[k]
					@emit \closed

	}

	return dir
	#d.on \directory (path, st) ->
		#echo "d:", path
		#Fs.stat p = Path.join(path, \src), (err, st) ->
		#	if not err and st.isDirectory!
		#		echo "project:", path
		#		d = new SrcDir p, st


Src = (opts) ->
	if typeof opts is \string => opts = {path: opts}
	else if typeof opts is \object
		if typeof opts.path isnt \string
			throw new Error "Src must have at least a path"
	else throw new Error "Src not initialized correctly"

	debug = Debug "Src(#{Path.relative process.cwd!, opts.path})"

	outfile = file = Path.basename opts.path
	opts.lang = switch Path.extname file
	| \.ls => \LiveScript
	| \.coffee => \coffee-script
	| \.js => \js
	| \.json => \json

	unless opts.outfile
		if ~(idx_ext = file.indexOf '.')
			switch (ext = if opts.ext then opts.ext else file.substr idx_ext)
			| '.json.ls' =>
				opts.result = true
				opts.json = true
				ext = \.json
			| otherwise =>
				ext = ext.replace /(?:(\.\w+)?\.\w+)?$/, (r, ex) ->
					if ex is \.json then opts.json = true
					return ex or if opts.json then \.json else \.js

			outfile = file.substr(0, idx_ext) + ext
		else if opts.ext
			outfile = file + opts.ext
		else
			throw new Error "source file does not have an extension"

		opts.outfile = Path.join(opts.write, outfile)

	src = new Fsm "Src(#{Path.relative process.cwd!, opts.path})" {
		initialize: -> echo "initializing src: #{opts.path}"

		states:
			uninitialized:
				_onEnter: ->
					if typeof opts.st is \object and opts.st.mtime instanceof Date
						src.transition if opts.src => \compile else \read
					else Fs.stat opts.path, (err, st) ->
						if err
							if err.code is \ENOENT
								# IMPROVEMENT: use the user's default template for the file?
								opts.src = ''
								now = new Date
								src.st = {mtime: now, ctime: now}
								src.transition \ready
							else throw err
						else
							src.st = st
							src.transition \read

			compile:
				_onEnter: ->
					try
						patch_ast = LiveScript.ast LiveScript.tokens "Mongoose = require 'Mongoose'"
						patch = patch_ast.toJSON!

						search_ast = LiveScript.ast LiveScript.tokens "Mongoose = require 'Mongooses'"
						search = search_ast.toJSON!
						j1 = JSON.stringify search.lines .replace /[,]*\"line\":[0-9]+/g, ''
						searchlen = search.lines.length

						options = {bare: true}
						opts.tokens = LiveScript.tokens opts.src
						opts.ast = LiveScript.ast opts.tokens

						if outfile is 'model.js'
							#console.log "ast", opts.ast
							ast = JSON.parse JSON.stringify opts.ast.toJSON!
							if global.window
								global.window.ast = opts.ast

							for i til width = ast.lines.length - searchlen
								# OPTIMIZE: this probably has to be the SLOWEST way to do do patching
								# IMPROVEMENT: I also want to improve patching, by maintaining variable names and the like
								# IMPROVEMENT: I want to search based on a certain pattern and replace based on that pattern
								l1 = ast.lines.slice i, i+searchlen
								j2 = JSON.stringify l1 .replace /[,]*\"line\":[0-9]+/g, ''
								if j1 is j2
									console.log "found target at line #", i
									ast.lines.splice.apply this, [i, searchlen] ++ patch.lines
									opts.ast = LSAst.fromJSON ast
							#livescript.ast(livescript.tokens("\t\tif true then"))

						if opts.result => opts.ast.makeReturn!
						opts.output = opts.ast.compileRoot options
						if opts.result
							opts.output = LiveScript.run opts.output, options, true

						if opts.json and not opts.run
							opts.output = JSON.stringify opts.output, null, '\t'

						if opts.write
							Fs.writeFile opts.outfile, opts.output, (err) ->
								if err
									src.emit \error, new Error "unable to write output to #{opts.outfile}"
									src.transition \error
								else
									debug "wrote %s", opts.outfile
									src.transition \ready
						else
							src.transition \ready
					catch e
						console.log opts.path, ':', e.message
						src.emit \error, e
						src.transition \error

			read:
				_onEnter: ->
					console.log "read:", opts.path
					Fs.readFile opts.path, 'utf-8', (err, data) ->
						if err
							src.transition \error
						else if opts.src isnt data or true
							opts.src = data
							src.transition \compile

			ready:
				_onEnter: ->
					if opts.watch and not src.watcher
						src.watcher = Fs.watchFile file, (evt) ->
							debug "file %s changed", file
							src.transition \read
					src.emit \ready

			destroy:
				_onEnter: ->
					Fs.unlink opts.outfile, (err) ->
						if err
							src.emit \error err
						src.emit \closed

			close:
				_onEnter: ->
					src.emit \closed

	}

	return src

/*

lab = new Fsm {
	initialize: ->
		echo "welcome to my laboratory!"

	states:
		uninitialized:
			_onEnter: ->
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
			_onEnter: ->

		load_user:
			_onEnter: ->
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
			_onEnter: ->
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
			_onEnter: ->
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


