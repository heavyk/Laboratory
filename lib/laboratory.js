var Fs, Path, p$, Ini, Github, Program, Walk, MachineShop, ref$, _, ToolShed, Fsm, LiveScript, Debug, echo, debug, LAB_PATH, LAB_CONFIG_PATH, USERS, testing_repos, Laboratory, Project, SrcDir, Src;
Fs = require('fs');
Path = require('path');
p$ = require('procstreams');
Ini = require('ini');
Github = require('github');
Program = require('commander');
Walk = require('walkdir');
ref$ = MachineShop = require('MachineShop'), _ = ref$._, ToolShed = ref$.ToolShed, Fsm = ref$.Fsm, LiveScript = ref$.LiveScript, Debug = ref$.Debug;
echo = console.log;
debug = Debug('laboratory');
LAB_PATH = Path.join(process.env.HOME, '.Laboratory');
LAB_CONFIG_PATH = Path.join(LAB_PATH, 'config');
USERS = {
  'duralog': {
    path: Path.join(process.env.HOME, 'Projects', 'uV'),
    user: {
      name: "duralog",
      email: "funisher@gmail.com"
    },
    github: {
      key: '1234'
    },
    gitlab: {
      url: 'https://git.hellacoders.com/heavyk/{repo}'
    },
    git: {
      url: 'git@git.hellacoders.com:heavyk/{repo}.git'
    }
  },
  'heavyk': {
    path: Path.join(process.env.HOME, 'Projects', 'uV'),
    user: {
      name: "flames of love",
      email: "mechanicofthesequence@gmail.com"
    },
    github: {
      key: '1234'
    },
    gitlab: {
      url: 'https://git.hellacoders.com/heavyk/{repo}'
    },
    git: {
      url: 'git@git.hellacoders.com:heavyk/{repo}.git'
    }
  }
};
testing_repos = ['Laboratory', 'Archivista', 'Mental', 'Upgrader', 'Blueshift'];
Program.version('0.1.0').option('-u, --user', "github user").parse(process.argv);
Laboratory = function(user){
  var debug, dirs, prjs, lab;
  debug = Debug('Laboratory');
  dirs = [];
  prjs = [];
  return lab = new Fsm('Laboratory', {
    initialize: function(){
      return echo("Loading Vulcrum's Lare...");
    },
    states: {
      uninitialized: {
        _onEnter: function(){
          return ToolShed.mkdir(LAB_CONFIG_PATH, function(err, dir){
            if (err) {
              throw err;
            } else if (typeof dir !== 'string') {
              return lab.transition('load');
            } else {
              return lab.transition('setup');
            }
          });
        }
      },
      load: {
        _onEnter: function(){
          var USER, path, prj;
          if (!user) {
            echo("XXX: prompt for the user. grab the zigzags. grab the glock. a mac.\nsome niggaz be cranked out. some be dranked out. I be danked out.\nthis is hamsta mutha fuckin nipples .. wit some heat 4 yo azz");
            setTimeout(function(){
              return echo("tickedy tacky tack toe, that's some LOLz fo yo motha fuckin ho");
            }, 5000);
            return setTimeout(function(){
              throw new Error("lol...");
            }, 8000);
          } else if (USER = USERS[user]) {
            echo("Greetings everyone, '" + USER.user.name + "' here");
            echo("Welcome to my laboratory...");
            lab.path = path = USER.path;
            process.chdir(path);
            Fs.watch(path, function(evt, filename){
              if (evt === 'change') {
                return console.log("lab disturbance", arguments);
              } else if (evt === 'rename') {
                return console.log("there was a ");
              }
            });
            prj = Walk(USER.path, {
              max_depth: 1
            });
            return prj.on('directory', function(path, st){
              if (~testing_repos.indexOf(Path.basename(path))) {
                return prjs.push(new Project({
                  path: path
                }));
              }
            });
          }
        }
      },
      ready: {
        _onEnter: function(){
          return echo("XXX: TODO ... walk the dirs and shit");
        }
      },
      setup: {
        _onEnter: function(){
          return echo("XXX: TODO ... set this shit up!!"[77]);
        }
      }
    }
  });
};
Project = function(opts){
  var path, src_dir, lib_dir, dirs, prj;
  path = opts.path;
  src_dir = Path.join(path, 'src');
  lib_dir = Path.join(path, 'lib');
  dirs = [];
  prj = new Fsm({
    initialize: function(){
      return echo("new Project!!");
    },
    opts: opts,
    states: {
      uninitialized: {
        _onEnter: function(){
          var pkg_src_path;
          console.log("XXX: woah there cowboy");
          dirs.push(new SrcDir({
            path: src_dir,
            into: lib_dir
          }));
          return Fs.stat(pkg_src_path = Path.join(path, "package.json.ls"), function(err, st){
            var pkg_src;
            if (!(err && st.isFile())) {
              return pkg_src = Src({
                path: pkg_src_path,
                write: path,
                watch: true,
                st: st
              });
            }
          });
        }
      }
    }
  });
  return prj;
};
SrcDir = function(opts, refs){
  var debug, dirs, srcs, dir;
  if (typeof opts !== 'object') {
    throw new Error("SrcDir needs an object");
  }
  if (typeof opts.path !== 'string') {
    throw new Error("path must be provided");
  }
  debug = Debug('SrcDir');
  dirs = [];
  srcs = {};
  dir = new Fsm("SrcDir(" + Path.relative(process.cwd(), opts.path) + ")", {
    initialize: function(){
      return echo("loading dir:", opts.path);
    },
    opts: opts,
    refs: refs,
    states: {
      uninitialized: {
        _onEnter: function(){
          if (opts.into) {
            ToolShed.mkdir(opts.into, function(err){
              if (err) {
                dir.emit('error', new Error("SrcDir already exists"));
                return dir.transition('error');
              }
            });
          } else {
            opts.into = opts.path;
          }
          if (opts.st && opts.st.isDirectory()) {
            return dir.transition('walk');
          } else {
            return Fs.stat(opts.path, function(err, st){
              if (err) {
                if (err.code === 'ENOENT') {
                  return ToolShed.mkdir(opts.path, function(err){
                    dir.emit('error', err);
                    return dir.transition('error');
                  });
                } else {
                  dir.emit('error', err);
                  return dir.transition('error');
                }
              } else if (st.isDirectory()) {
                return dir.transition('walk');
              } else {
                dir.emit('error', new Error("SrcDir already exists"));
                return dir.transition('error');
              }
            });
          }
        }
      },
      walk: {
        _onEnter: function(){
          var d;
          Fs.watch(opts.path, function(evt, filename){
            var s;
            if (evt === 'change') {
              if (filename && (s = srcs[filename])) {
                s.transition('read');
              } else {
                _.each(srcs, function(s){
                  return s.transition('check');
                });
              }
            } else if (evt === 'rename') {
              console.log("XXX: src file renaming not yet supported!!");
            }
            return echo("disturbance", arguments);
          });
          d = Walk(opts.path, {
            max_depth: 1
          });
          d.on('error', function(err){
            console.log("we got an error:", arguments);
            throw err;
          });
          d.on('end', function(){
            return dir.transition('ready');
          });
          return d.on('file', function(path, st){
            var file, ext;
            file = Path.basename(path);
            switch (ext = Path.extname(file)) {
            case '.ls':
              return srcs[file] = Src({
                path: path,
                file: file,
                write: opts.into,
                st: st,
                dir: dir
              });
            }
          });
        }
      },
      ready: {
        _onEnter: function(){
          return dir.emit('ready');
        },
        changed: function(){
          return console.log("Changed~~~");
        }
      }
    }
  });
  return dir;
};
Src = function(opts){
  var debug, outfile, file, idx_ext, ext, src;
  if (typeof opts === 'string') {
    opts = {
      path: opts
    };
  } else if (typeof opts === 'object') {
    if (typeof opts.path !== 'string') {
      throw new Error("Src must have at least a path");
    }
  } else {
    throw new Error("Src not initialized correctly");
  }
  debug = Debug("Src(" + Path.relative(process.cwd(), opts.path) + ")");
  outfile = file = Path.basename(opts.path);
  opts.lang = (function(){
    switch (Path.extname(file)) {
    case '.ls':
      return 'LiveScript';
    case '.coffee':
      return 'coffee-script';
    case '.js':
      return 'js';
    case '.json':
      return 'json';
    }
  }());
  if (~(idx_ext = file.indexOf('.'))) {
    switch (ext = opts.ext
      ? opts.ext
      : file.substr(idx_ext)) {
    case '.json.ls':
      opts.result = true;
      opts.json = true;
      ext = '.json';
      break;
    default:
      ext = ext.replace(/(?:(\.\w+)?\.\w+)?$/, function(r, ex){
        if (ex === '.json') {
          opts.json = true;
        }
        return ex || (opts.json ? '.json' : '.js');
      });
    }
    outfile = file.substr(0, idx_ext) + ext;
  } else if (opts.ext) {
    outfile = file + opts.ext;
  } else {
    throw new Error("source file does not have an extension");
  }
  src = new Fsm("Src(" + Path.relative(process.cwd(), opts.path) + ")", {
    initialize: function(){
      return echo("initializing src: " + opts.path);
    },
    states: {
      uninitialized: {
        _onEnter: function(){
          if (typeof opts.st === 'object' && opts.st.mtime instanceof Date) {
            return src.transition(opts.src ? 'compile' : 'read');
          } else {
            return Fs.stat(opts.path, function(err, st){
              var now;
              if (err) {
                if (err.code === 'ENOENT') {
                  opts.src = '';
                  now = new Date;
                  src.st = {
                    mtime: now,
                    ctime: now
                  };
                  return src.transition('ready');
                } else {
                  throw err;
                }
              } else {
                src.st = st;
                return src.transition('read');
              }
            });
          }
        }
      },
      compile: {
        _onEnter: function(){
          var options, p, e;
          try {
            options = {
              bare: true
            };
            opts.tokens = LiveScript.tokens(opts.src);
            opts.ast = LiveScript.ast(opts.tokens);
            if (opts.result) {
              opts.ast.makeReturn();
            }
            opts.output = opts.ast.compileRoot(options);
            if (opts.result) {
              opts.output = LiveScript.run(opts.output, options, true);
            }
            if (opts.json && !opts.run) {
              opts.output = JSON.stringify(opts.output, '\t');
            }
            if (opts.write) {
              return Fs.writeFile(p = Path.join(opts.write, outfile), opts.output, function(err){
                if (err) {
                  src.emit('error', new Error("unable to write output to " + p));
                  return src.transition('error');
                } else {
                  debug("wrote %s", p);
                  return src.transition('ready');
                }
              });
            } else {
              return src.transition('ready');
            }
          } catch (e$) {
            e = e$;
            console.log(opts.path, ':', e.message);
            src.emit('error', e);
            return src.transition('error');
          }
        }
      },
      read: {
        _onEnter: function(){
          console.log("read:", opts.path);
          return Fs.readFile(opts.path, 'utf-8', function(err, data){
            if (err) {
              return src.transition('error');
            } else if (opts.src !== data) {
              opts.src = data;
              return src.transition('compile');
            }
          });
        }
      },
      ready: {
        _onEnter: function(){
          if (opts.watch && !src.watcher) {
            src.watcher = Fs.watchFile(file, function(evt){
              debug("file %s changed", file);
              return src.transition('read');
            });
          }
          return src.emit('ready');
        }
      }
    }
  });
  return src;
};
return Laboratory('duralog');
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