var Fs, Path, p$, Ini, Github, Program, Walk, LiveScript, LSAst, MachineShop, ref$, _, ToolShed, Fsm, Debug, Config, _log, echo, debug, Verse, CWD, Laboratory, Project, SrcDir, Src, out$ = typeof exports != 'undefined' && exports || this;
Fs = require('fs');
Path = require('path');
p$ = require('procstreams');
Ini = require('ini');
Github = require('github');
Program = require('commander');
Walk = require('walkdir');
LiveScript = require('livescript');
LSAst = require('livescript/lib/ast');
ref$ = MachineShop = require('MachineShop'), _ = ref$._, ToolShed = ref$.ToolShed, Fsm = ref$.Fsm, Debug = ref$.Debug;
Config = ToolShed.Config;
_log = console.log;
echo = function(){
  var str;
  str = '';
  _.each(arguments, function(s){
    return str += typeof s === 'object'
      ? JSON.stringify(s)
      : s + ' ';
  });
  return console.log(str);
};
debug = Debug('laboratory');
process.on('uncaughtException', function(e){
  debug("uncaught exception %s %s", e, e.stack);
  if (e + '' !== 'nothing') {
    console.log("ERRROR '" + (e + '') + "'");
    console.log(e.stack
      ? e.stack
      : "error: " + e);
    return console.log("\n");
  }
});
Program.version('0.1.0').option('-u, --user', "github user").option('-p, --project', "skip project selection screen and open a project directly").parse(process.argv);
Verse = {
  prompt: function(txt, data, fn){
    var show_prompt;
    if (typeof data === 'function') {
      fn = data;
    } else if (Array.isArray(data)) {
      _.each(data, fn);
    } else {
      fn(data);
    }
    return show_prompt = function(prompt){
      return console.log(prompt + " PROMPT:", txt, data);
    };
  }
};
CWD = process.cwd();
out$.Laboratory = Laboratory = function(opts, refs){
  var debug, prj_watcher, lab;
  debug = Debug('Laboratory');
  if (typeof opts !== 'object') {
    throw new Error("Laboratory opts must be an object");
  }
  return lab = new Fsm('Laboratory', {
    opts: opts,
    refs: refs,
    prjs: [],
    initialize: function(){
      return echo("Loading Vulcrum's Lare...");
    },
    eventListeners: {
      user: function(user){}
    },
    states: {
      uninitialized: {
        _onEnter: function(){
          return ToolShed.searchDownwardFor('laboratory.json', opts.config_path || process.cwd(), function(err, path){
            var cfg;
            if (err) {
              return lab.transition('setup');
            } else {
              cfg = ToolShed.Config(path);
              return cfg.on('ready', function(obj){
                lab.CONFIG = obj;
                lab.CONFIG.path = Path.dirname(path);
                return lab.transition('load');
              });
            }
          });
        }
      },
      load: {
        _onEnter: function(){
          var task;
          task = this.task('loading...');
          task.push("loading user", function(done){
            var ask_user, user;
            ask_user = Verse.prompt("user:", user = opts.user || lab.CONFIG.user, function(res){
              var u;
              if (typeof res === 'string') {
                if (typeof (u = lab.CONFIG.users[res])) {
                  lab.CONFIG.user = res;
                  lab.USER = u;
                  return done();
                } else {
                  return ask_user("user doesn't exist");
                }
              } else if (typeof res === 'object') {
                if (typeof res.name === 'string' && typeof res.git === 'object') {
                  lab.CONFIG.users[res.name] = res;
                  return done();
                } else {
                  return "unknown object format or data";
                }
              } else {
                return ask_user("unknown input");
              }
            });
            return ask_user("please type your user");
          });
          task.choke("getting lab path", function(done){
            var dir, ask_path;
            dir = opts.path || lab.CONFIG.path || Path.join(ToolShed.HOME_DIR, 'Projects');
            ask_path = Verse.prompt("Laboratory Projects path:", dir, function(res){
              if (typeof res === 'string') {
                return ToolShed.stat(res, function(err, st){
                  if (err) {
                    if (err.code === 'ENOENT') {
                      return echo("TODO: ask the user if they want to create the path?");
                    }
                  } else if (st.isDirectory()) {
                    lab.CONFIG.path = res;
                    return done();
                  } else {
                    return ask_path("path exists already but isn't a directory");
                  }
                });
              } else {
                return ask_path("unknown input");
              }
            });
            return ask_path("where is your Laboratory located?");
          });
          return task.end(function(){
            var path, walker;
            console.log("task.end", arguments);
            path = lab.CONFIG.path;
            debug("using path %s", path);
            prj_watcher = Fs.watch(path, function(evt, filename){
              var new_prj_path, offset;
              console.log("lab disturbance", arguments);
              if (evt === 'change') {
                return console.log("change event", arguments);
              } else if (evt === 'rename') {
                new_prj_path = Path.join(path, filename);
                offset = false;
                _.each(lab.prjs, function(prj, i){
                  if (prj.path === new_prj_path) {
                    offset = i;
                    return false;
                  }
                });
                return ToolShed.stat(new_prj_path, function(err, st){
                  if (offset === false && !err && st.isDirectory()) {
                    return new Project({
                      path: new_prj_path,
                      name: filename
                    }, {
                      lab: lab
                    });
                  } else {
                    lab.prjs[offset].transition('close');
                    return lab.prjs.splice(offset, 0);
                  }
                });
              }
            });
            walker = Walk(path, {
              max_depth: 1
            });
            walker.on('directory', function(path, st){
              if (~lab.USER.projects.indexOf(Path.basename(path))) {
                return new Project({
                  path: path
                }, {
                  lab: lab
                });
              }
            });
            return walker.on('end', function(){
              return lab.transition('ready');
            });
          });
        }
      },
      ready: {
        _onEnter: function(){
          this.emit('ready');
          return echo("XXX: TODO ... walk the dirs and shit");
        },
        switch_user: function(user){
          echo("TODO: switch user");
          return prj_watcher.close();
        }
      },
      setup: {
        _onEnter: function(){
          return echo("XXX: TODO ... set this shit up!!"[77]);
        }
      },
      close: {
        _onEnter: function(){
          prj_watcher.close();
          return _.each(lab.prjs, function(prj, i){
            prj.transition('close');
            lab.prjs[offset].transition('close');
            lab.prjs.splice(i, 0);
          });
        }
      }
    }
  });
};
out$.Project = Project = function(opts, refs){
  var lab, path, src_dir, lib_dir, prj;
  if (!opts.path) {
    throw new Error("you need a path for your project");
  } else if (opts.name) {
    opts.path = Path.join(refs.lab.path, opts.name);
  }
  if (typeof refs === 'undefined') {
    refs = {};
  }
  lab = refs.lab;
  path = Path.resolve(opts.path);
  if (!path) {
    throw new Error("invalid path " + opts.path);
  }
  src_dir = Path.join(path, 'src');
  lib_dir = Path.join(path, 'lib');
  prj = new Fsm("Project(" + opts.name + ")", {
    path: path,
    dirs: {},
    opts: opts,
    states: {
      uninitialized: {
        _onEnter: function(){
          var pkg_src_path, pkg_json_path, pkg;
          pkg_src_path = Path.join(path, "package.json.ls");
          pkg_json_path = Path.join(path, "package.json");
          pkg = prj.PACKAGE = Config(pkg_json_path);
          pkg.once('new', function(){
            pkg.name = opts.name || Path.basename(path);
            return pkg.version = '0.0.1';
          });
          return pkg.once('ready', function(obj, is_new){
            prj.PACKAGE = obj;
            prj.transition('loaded');
            if (pkg.state === 'new') {
              return prj.transition;
            }
          });
        }
      },
      loaded: {
        _onEnter: function(){
          var src_dir, lib_dir;
          src_dir = Path.join(path, 'src');
          lib_dir = Path.join(path, 'lib');
          prj.exec('add_dir', 'src', src_dir, lib_dir);
          return prj.transition('ready');
        }
      },
      ready: {
        _onEnter: function(){
          return console.log("project totally ready");
        },
        add_dir: function(name, path, into){
          console.log("adding dir");
          return prj.dirs[name] = new SrcDir({
            path: path,
            into: into
          });
        }
      },
      'new': {
        _onEnter: function(){
          /*
          pkg_src = Src {
          	path: pkg_src_path
          	output: "name: 'untitled'"
          	write: path
          	watch: true
          }
          */
          pkg.name = opts.name || Path.basename(path);
          return pkg.version = '0.0.1';
        }
      }
    }
  });
  lab.prjs.push(prj);
  lab.emit('added', prj);
  return prj;
};
out$.SrcDir = SrcDir = function(opts, refs){
  var debug, dir;
  if (typeof opts !== 'object') {
    throw new Error("SrcDir needs an object");
  }
  if (typeof opts.path !== 'string') {
    throw new Error("path must be provided");
  }
  debug = Debug('SrcDir');
  dir = new Fsm("SrcDir(" + Path.relative(process.cwd(), opts.path) + ")", {
    dirs: {},
    srcs: {},
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
          this.watcher = Fs.watch(opts.path, function(evt, filename){
            var s, ref$, ref1$, path;
            echo("disturbance", evt, filename);
            if (evt === 'change') {
              if (filename && (s = dir.srcs[filename])) {
                return s.transition('read');
              } else {
                return _.each(dir.srcs, function(s){
                  return s.transition('check');
                });
              }
            } else if (evt === 'rename') {
              console.log("XXX: src file renaming not yet supported!!", arguments);
              if (!filename) {
                return dir.transition('walk');
              } else {
                if (s = dir.srcs[filename]) {
                  s.transition('destroy');
                  return ref1$ = (ref$ = dir.srcs)[filename], delete ref$[filename], ref1$;
                } else if (s = dir.dirs[filename]) {
                  s.transition('destroy');
                  return ref1$ = (ref$ = dir.dirs)[filename], delete ref$[filename], ref1$;
                } else {
                  path = Path.join(opts.path, filename);
                  return Fs.stat(path, function(err, st){
                    var ext, into_dir;
                    if (!err) {
                      if (st.isFile()) {
                        switch (ext = Path.extname(filename)) {
                        case '.ls':
                          return dir.srcs[filename] = Src({
                            path: path,
                            file: filename,
                            write: opts.into,
                            st: st,
                            dir: dir
                          });
                        }
                      } else if (st.isDirectory()) {
                        into_dir = Path.join(opts.into, filename);
                        return dir.dirs[filename] = new SrcDir({
                          path: path,
                          into: into_dir
                        });
                      }
                    }
                  });
                }
              }
            }
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
          d.on('file', function(path, st){
            var file, ext;
            file = Path.basename(path);
            if (!dir.srcs[file]) {
              switch (ext = Path.extname(file)) {
              case '.ls':
                return dir.srcs[file] = Src({
                  path: path,
                  file: file,
                  write: opts.into,
                  st: st,
                  dir: dir
                });
              }
            }
          });
          return d.on('directory', function(path, st){
            var dir_name, into_dir;
            dir_name = Path.basename(path);
            into_dir = Path.join(opts.into, dir_name);
            return dir.dirs[dir_name] = new SrcDir({
              path: path,
              into: into_dir
            });
          });
        }
      },
      ready: {
        _onEnter: function(){
          return dir.emit('ready');
        },
        rescan: function(){
          return console.log("XXX: we should be rescanning now");
        }
      },
      close: {
        _onEnter: function(){
          this.watcher.close();
          console.log("closing...");
          _.each(dir.dirs, function(d, k){
            var ref$, ref1$;
            d.transition('close');
            return ref1$ = (ref$ = dir.dirs)[k], delete ref$[k], ref1$;
          });
          _.each(dir.srcs, function(s, k){
            var ref$, ref1$;
            s.transition('close');
            return ref1$ = (ref$ = dir.srcs)[k], delete ref$[k], ref1$;
          });
          return this.emit('closed');
        }
      }
    }
  });
  return dir;
};
out$.Src = Src = function(opts){
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
  if (!opts.outfile) {
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
      if (ext !== '.js') {
        opts.result = true;
      }
      outfile = file.substr(0, idx_ext) + ext;
    } else if (opts.ext) {
      outfile = file + opts.ext;
    } else {
      throw new Error("source file does not have an extension");
    }
    opts.outfile = Path.join(opts.write, outfile);
  }
  src = new Fsm("Src(" + Path.relative(process.cwd(), opts.path) + ")", {
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
          var patch_ast, patch, search_ast, search, j1, searchlen, options, ast, i$, to$, width, i, l1, j2, e;
          try {
            patch_ast = LiveScript.ast(LiveScript.tokens("Mongoose = require 'Mongoose'"));
            patch = patch_ast.toJSON();
            search_ast = LiveScript.ast(LiveScript.tokens("Mongoose = require 'Mongooses'"));
            search = search_ast.toJSON();
            j1 = JSON.stringify(search.lines).replace(/[,]*\"line\":[0-9]+/g, '');
            searchlen = search.lines.length;
            options = {
              bare: true
            };
            opts.tokens = LiveScript.tokens(opts.src);
            opts.ast = LiveScript.ast(opts.tokens);
            if (outfile === 'model.js') {
              ast = JSON.parse(JSON.stringify(opts.ast.toJSON()));
              if (global.window) {
                global.window.ast = opts.ast;
              }
              for (i$ = 0, to$ = width = ast.lines.length - searchlen; i$ < to$; ++i$) {
                i = i$;
                l1 = ast.lines.slice(i, i + searchlen);
                j2 = JSON.stringify(l1).replace(/[,]*\"line\":[0-9]+/g, '');
                if (j1 === j2) {
                  console.log("found target at line #", i);
                  ast.lines.splice.apply(this, [i, searchlen].concat(patch.lines));
                  opts.ast = LSAst.fromJSON(ast);
                }
              }
            }
            if (opts.result) {
              opts.ast.makeReturn();
            }
            opts.output = opts.ast.compileRoot(options);
            if (opts.result) {
              process.chdir(Path.dirname(opts.path));
              opts.output = LiveScript.run(opts.output, options, true);
              process.chdir(CWD);
            }
            if (opts.json) {
              opts.output = JSON.stringify(opts.output, null, '\t');
            }
            if (opts.write) {
              return Fs.writeFile(opts.outfile, opts.output, function(err){
                if (err) {
                  src.emit('error', new Error("unable to write output to " + opts.outfile));
                  return src.transition('error');
                } else {
                  debug("wrote %s", opts.outfile);
                  return src.transition('ready');
                }
              });
            } else {
              return src.transition('ready');
            }
          } catch (e$) {
            e = e$;
            console.log(opts.path, ':', e.stack);
            src.emit('error', e);
            return src.transition('error');
          }
        }
      },
      read: {
        _onEnter: function(){
          return Fs.readFile(opts.path, 'utf-8', function(err, data){
            if (err) {
              return src.transition('error');
            } else if (opts.src !== data || true) {
              opts.src = data;
              return src.transition('compile');
            }
          });
        }
      },
      check: {
        _onEnter: function(){
          var e;
          console.log("what are we checking???");
          try {
            throw new Error("...");
          } catch (e$) {
            e = e$;
            console.log(e.stack);
          }
          return this.transition('ready');
        }
      },
      ready: {
        _onEnter: function(){
          if (opts.watch && !src.watcher) {
            src.watcher = Fs.watchFile(opts.path, function(evt){
              debug("file %s changed", file);
              return src.transition('read');
            });
          }
          return src.emit('ready');
        }
      },
      destroy: {
        _onEnter: function(){
          var s;
          if (s = src.watcher) {
            s.close();
          }
          return Fs.unlink(opts.outfile, function(err){
            if (err && err.code !== 'ENOENT') {
              src.emit('error', err);
            }
            return src.emit('closed');
          });
        }
      },
      close: {
        _onEnter: function(){
          return src.emit('closed');
        }
      }
    }
  });
  return src;
};
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