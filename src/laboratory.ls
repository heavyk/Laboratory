
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
#export class Doc extends Fsm


Program
	.version \0.1.0
	.option '-u, --user', "github user"
	.option '-p, --project', "skip project selection screen and open a project directly"
	.parse process.argv



# TODO FOR v0.1.0:
# 1. read the config file (~/.Laboratory/config/env.json)
# 2. multiple users (~/.Laboratory/users/{user}/env.json)
# 3.

#mongoose = require 'mongoose'
#Schema = mongoose.Schema
#ObjectId = Schema.Types.ObjectId

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

export Laboratory = (opts, refs) ->
	debug = Debug 'Laboratory'

	unless typeof opts is \object
		throw new Error "Laboratory opts must be an object"

	#private vars
	var prj_watcher

	lab = new Fsm 'Laboratory' {
		opts: opts
		refs: refs
		prjs: []
		initialize: -> echo "Loading Vulcrum's Lare..."

		eventListeners:
			user: (user) ->

		states:
			uninitialized:
				_onEnter: ->
					ToolShed.searchDownwardFor 'laboratory.json', (opts.config_path || process.cwd!), (err, path) ->
						if err
							lab.transition \setup
						else
							cfg = ToolShed.Config path
							cfg.on \ready (obj) ->
								lab.CONFIG = obj
								lab.CONFIG.path = Path.dirname path
								lab.transition \load

			load:
				_onEnter: ->
					task = @task 'loading...'
					task.push "loading user", (done) ->
						ask_user = Verse.prompt "user:", (user = opts.user || lab.CONFIG.user), (res) ->
							if typeof res is \string
								if typeof (u = lab.CONFIG.users[res])
									lab.CONFIG.user = res
									lab.USER = u
									done!
								else ask_user "user doesn't exist"
							else if typeof res is \object
								#TODO: these should use mongoose/PublicDB model verification
								# mun = new Mun res
								if typeof res.name is \string and typeof res.git is \object
									# we're just gonna assume everything is all verified for now
									lab.CONFIG.users[res.name] = res
									done!
								else "unknown object format or data"
							else ask_user "unknown input"
						#echo "XXX: prompt for the user. grab the zigzags. grab the glock. a mac.\nsome niggaz be cranked out. some be dranked out. I be danked out.\nthis is hamsta mutha fuckin nipples .. wit some heat 4 yo azz"
						#setTimeout ->
						#	echo("tickedy tacky tack toe, that's some LOLz fo yo motha fuckin ho")
						#, 5000
						ask_user "please type your user"

					task.choke "getting lab path" (done) ->
						dir = opts.path || lab.CONFIG.path || Path.join ToolShed.HOME_DIR, 'Projects'
						ask_path = Verse.prompt "Laboratory Projects path:", dir, (res) ->
							if typeof res is \string
								ToolShed.stat res, (err, st) ->
									if err
										if err.code is \ENOENT
											echo "TODO: ask the user if they want to create the path?"
											#lab.transition \setup
									else if st.isDirectory!
										lab.CONFIG.path = res
										done!
									else ask_path "path exists already but isn't a directory"
							else ask_path "unknown input"
						#TODO: do a quick check to see if HOME_DIR/Projects exists
						ask_path "where is your Laboratory located?"


					task.end ->
						console.log "task.end", &
						path = lab.CONFIG.path
						debug "using path %s", path
						#process.chdir path
						prj_watcher := Fs.watch path, (evt, filename) ->
							console.log "lab disturbance", &
							if evt is \change
								console.log "change event", &
							else if evt is \rename
								#lab.prjs.push new Project {path: path}
								new_prj_path = Path.join path, filename
								offset = false
								_.each lab.prjs, !(prj, i) ->
									if prj.path is new_prj_path
										offset := i
										return false
								ToolShed.stat new_prj_path, (err, st) ->
									if offset is false and not err and st.isDirectory!
										new Project {path: new_prj_path, name: filename}, {lab: lab}
									else
										lab.prjs[offset].transition \close
										lab.prjs.splice offset, 0
						walker = Walk path, max_depth: 1
						walker.on \directory (path, st) ->
							# this should create a Project which is really an extension of Repository
							# which will in turn, create a src dir, an app.nw, etc.
							if ~(lab.USER.projects.indexOf Path.basename path)
								#lab.prjs.push new Project {path: path}
								new Project {path: path}, {lab: lab}
						walker.on \end ->
							lab.transition \ready

			ready:
				_onEnter: ->
					@emit \ready
					echo "XXX: TODO ... walk the dirs and shit"

				switch_user: (user) ->
					echo "TODO: switch user"
					prj_watcher.close!

			setup:
				_onEnter: -> echo "XXX: TODO ... set this shit up!!"77

			close:
				_onEnter: ->
					prj_watcher.close!
					_.each lab.prjs, !(prj, i) ->
						prj.transition \close
						lab.prjs[offset].transition \close
						lab.prjs.splice i, 0
	}
#*/


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

export Project = (opts, refs) ->
	unless opts.path
		throw new Error "you need a path for your project"
	else if opts.name
		opts.path = Path.join refs.lab.path, opts.name

	refs = {} if typeof refs is \undefined

	lab = refs.lab
	path = Path.resolve opts.path
	unless path => throw new Error "invalid path #{opts.path}"

	src_dir = Path.join path, \src
	lib_dir = Path.join path, \lib

	prj = new Fsm "Project(#{opts.name})" {
		path: path
		dirs: {}
		opts: opts
		# FUTURE: convert this into a command:
		states:
			uninitialized:
				_onEnter: ->
					pkg_src_path = Path.join path, "package.json.ls"
					pkg_json_path = Path.join path, "package.json"
					pkg = prj.PACKAGE = Config pkg_json_path
					pkg.once \new ->
						pkg.name = opts.name or Path.basename path
						pkg.version = '0.0.1'

					pkg.once \ready (obj, is_new) ->
						prj.PACKAGE = obj
						prj.transition \loaded

						if pkg.state is \new then prj.transition \
					/*
					ToolShed.readFile pkg_json_path, 'utf-8', (err, data) ->
						if err
							if err.code is \ENOENT
								console.log "TODO: prompt the user for the project name"
								prj.transition \new
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
					*/
			loaded:
				_onEnter: ->
					src_dir = Path.join path, \src
					lib_dir = Path.join path, \lib
					prj.exec \add_dir, \src, src_dir, lib_dir
					prj.transition \ready

			ready:
				_onEnter: ->
					console.log "project totally ready"

				add_dir: (name, path, into) ->
					console.log "adding dir"
					prj.dirs[name] = new SrcDir {path: path, into: into}

			new:
				_onEnter: ->
					/*
					pkg_src = Src {
						path: pkg_src_path
						output: "name: 'untitled'"
						write: path
						watch: true
					}
					*/
					pkg.name = opts.name or Path.basename path
					pkg.version = '0.0.1'

	}

	lab.prjs.push prj
	lab.emit \added, prj
	return prj


export SrcDir = (opts, refs) ->
	if typeof opts isnt \object
		throw new Error "SrcDir needs an object"
	if typeof opts.path isnt \string
		throw new Error "path must be provided"

	debug = Debug 'SrcDir'
	dir = new Fsm "SrcDir(#{Path.relative process.cwd!, opts.path})" {
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
							else _.each dir.srcs, (s) ->
								s.transition \check
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


export Src = (opts) ->
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

			if ext isnt \.js
				opts.result = true
			outfile = file.substr(0, idx_ext) + ext
		else if opts.ext
			outfile = file + opts.ext
		else
			throw new Error "source file does not have an extension"

		opts.outfile = Path.join(opts.write, outfile)

	src = new Fsm "Src(#{Path.relative process.cwd!, opts.path})" {
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
							process.chdir Path.dirname opts.path
							opts.output = LiveScript.run opts.output, options, true
							process.chdir CWD

						if opts.json
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
						console.log opts.path, ':', e.stack
						src.emit \error, e
						src.transition \error

			read:
				_onEnter: ->
					Fs.readFile opts.path, 'utf-8', (err, data) ->
						if err
							src.transition \error
						else if opts.src isnt data or true
							opts.src = data
							src.transition \compile

			check:
				_onEnter: ->
					console.log "what are we checking???"
					try
						throw new Error "..."
					catch e
						console.log e.stack
					@transition \ready

			ready:
				_onEnter: ->
					if opts.watch and not src.watcher
						src.watcher = Fs.watchFile opts.path, (evt) ->
							debug "file %s changed", file
							src.transition \read
					src.emit \ready

			destroy:
				_onEnter: ->
					if s = src.watcher then s.close!
					Fs.unlink opts.outfile, (err) ->
						if err and err.code isnt \ENOENT
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


