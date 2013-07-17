
Fs = require \fs
Path = require \path

p$ = require \procstreams
Ini = require \ini
Github = require \github
Program = require \commander
Walk = require \walkdir

{ _, ToolShed, Fsm, LiveScript, Debug } = MachineShop = require \MachineShop

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

echo = console.log
debug = Debug 'laboratory'

LAB_PATH = Path.join process.env.HOME, '.Laboratory'
LAB_CONFIG_PATH = Path.join LAB_PATH, \config

# INCOMPLETE: save the keys in here too
USERS = {
	'duralog':
		path: Path.join process.env.HOME, \Projects, \uV
		user:
			name: "duralog"
			email: "funisher@gmail.com"
		github:
			key: '1234'
		gitlab:
			url: 'https://git.hellacoders.com/heavyk/{repo}'
		git:
			url: 'git@git.hellacoders.com:heavyk/{repo}.git'
	'heavyk':
		path: Path.join process.env.HOME, \Projects, \uV
		user:
			name: "flames of love"
			email: "mechanicofthesequence@gmail.com"
		github:
			key: '1234'
		gitlab:
			url: 'https://git.hellacoders.com/heavyk/{repo}'
		git:
			url: 'git@git.hellacoders.com:heavyk/{repo}.git'
}

testing_repos = [\Laboratory \Archivista \Mental \Upgrader \Blueshift]


Program
	.version \0.1.0
	.option '-u, --user', "github user"
	.parse process.argv



# TODO FOR v0.1.0:
# 1. read the config file (~/.Laboratory/config/env.json)
# 2. multiple users (~/.Laboratory/users/{user}/env.json)
# 3.

Laboratory = (user) ->
	debug = Debug 'Laboratory'
	dirs = []
	prjs = []

	lab = new Fsm 'Laboratory' {
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
					else if USER = USERS[user]
						echo "Greetings everyone, '#{USER.user.name}' here"
						echo "Welcome to my laboratory..."
						lab.path = path = USER.path
						process.chdir path
						Fs.watch path, (evt, filename) ->
							if evt is \change
								console.log "lab disturbance", &
							else if evt is \rename
								console.log "there was a "
						prj = Walk USER.path, max_depth: 1
						prj.on \directory (path, st) ->
							# this should create a Project which is really an extension of Repository
							# which will in turn, create a src dir, an app.nw, etc.
							if ~(testing_repos.indexOf Path.basename path)
								prjs.push new Project {path: path}

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


Project = (opts) ->
	path = opts.path
	src_dir = Path.join path, \src
	lib_dir = Path.join path, \lib
	#src_dir = opts.src_dir
	#lib_dir = opts.into
	dirs = []
	prj = new Fsm {
		initialize: -> echo "new Project!!"
		opts: opts
		states:
			uninitialized:
				_onEnter: ->
					console.log "XXX: woah there cowboy"
					dirs.push new SrcDir {path: src_dir, into: lib_dir}
					Fs.stat pkg_src_path = Path.join(path, "package.json.ls"), (err, st) ->
						unless err and st.isFile!
							pkg_src = Src {path: pkg_src_path, write: path, +watch, st}
							# it might be useful to provide livescript output `Config` here...


	}
	return prj


SrcDir = (opts, refs) ->
	if typeof opts isnt \object
		throw new Error "SrcDir needs an object"
	if typeof opts.path isnt \string
		throw new Error "path must be provided"

	debug = Debug 'SrcDir'
	dirs = []
	srcs = {}
	dir = new Fsm "SrcDir(#{Path.relative process.cwd!, opts.path})" {
		initialize: -> echo "loading dir:", opts.path
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
					Fs.watch opts.path, (evt, filename) ->
						if evt is \change
							if filename and s = srcs[filename]
								s.transition \read
							else _.each srcs, (s) -> s.transition \check
						else if evt is \rename
							console.log "XXX: src file renaming not yet supported!!"
						echo "disturbance", &
					d = Walk opts.path, max_depth: 1
					d.on \error (err) ->
						console.log "we got an error:", &
						throw err
					d.on \end ->
						dir.transition \ready
					d.on \file (path, st) ->
						file = Path.basename path
						switch ext = Path.extname file
						#| \.ls \.coffee \.js => srcs.push Src path, st
						| \.ls => srcs[file] = Src {path, file, write: opts.into, st, dir}

			ready:
				_onEnter: ->
					dir.emit \ready

				changed: ->
					console.log "Changed~~~"

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
						options = {bare: true}
						opts.tokens = LiveScript.tokens opts.src
						opts.ast = LiveScript.ast opts.tokens
						if opts.result => opts.ast.makeReturn!
						opts.output = opts.ast.compileRoot options
						if opts.result
							opts.output = LiveScript.run opts.output, options, true

						if opts.json and not opts.run
							opts.output = JSON.stringify opts.output, '\t'

						if opts.write
							Fs.writeFile p = Path.join(opts.write, outfile), opts.output, (err) ->
								if err
									src.emit \error, new Error "unable to write output to #{p}"
									src.transition \error
								else
									debug "wrote %s", p
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
						else if opts.src isnt data
							opts.src = data
							src.transition \compile

			ready:
				_onEnter: ->
					if opts.watch and not src.watcher
						src.watcher = Fs.watchFile file, (evt) ->
							debug "file %s changed", file
							src.transition \read
					src.emit \ready

	}

	return src

return Laboratory \duralog

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


