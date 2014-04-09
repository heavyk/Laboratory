var Fs, Path, assert, Walk, LiveScript, LSAst, MachineShop, ref$, _, ToolShed, Fsm, Debug, Config, _log, echo, debug, Verse, CWD, Laboratory, Project, SrcDir, Src, out$ = typeof exports != 'undefined' && exports || this;
Fs = require('fs');
Path = require('path');
assert = require('assert');
Walk = require('walkdir');
LiveScript = require('livescript');
LSAst = require('livescript/lib/ast');
ref$ = MachineShop = require('MachineShop'), _ = ref$._, ToolShed = ref$.ToolShed, Fsm = ref$.Fsm;
Debug = ToolShed.Debug;
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
out$.Laboratory = Laboratory = (function(superclass){
  var prototype = extend$((import$(Laboratory, superclass).displayName = 'Laboratory', Laboratory), superclass).prototype, constructor = Laboratory;
  function Laboratory(opts, refs){
    var this$ = this instanceof ctor$ ? this : new ctor$;
    this$.opts = opts;
    this$.refs = refs;
    if (typeof opts !== 'object') {
      throw new Error("Laboratory opts must be an object");
    }
    this$.prjs = [];
    Laboratory.superclass.call(this$, 'Laboratory');
    return this$;
  } function ctor$(){} ctor$.prototype = prototype;
  prototype.initialize = function(){
    return echo("Loading Vulcrum's Lare...");
  };
  prototype.eventListeners = {
    user: function(user){}
  };
  prototype.states = {
    uninitialized: {
      onenter: function(){
        var this$ = this;
        return ToolShed.searchDownwardFor('laboratory.json', this.opts.config_path || process.cwd(), function(err, path){
          var cfg;
          assert(this$ instanceof Laboratory);
          if (err) {
            return this$.transition('setup');
          } else {
            cfg = ToolShed.Config(path);
            return cfg.once('ready', function(){
              assert(this$ instanceof Laboratory);
              this$.CONFIG = cfg;
              this$.CONFIG.path = this$.path = Path.dirname(path);
              return this$.transition('load');
            });
          }
        });
      }
    },
    load: {
      onenter: function(){
        var task, this$ = this;
        task = this.task('loading...');
        task.push("loading user", function(done){
          var user, ask_user, this$ = this;
          assert(this instanceof Laboratory);
          console.log("user:", user = this.opts.user, this.CONFIG.user);
          ask_user = Verse.prompt("user:", user = this.opts.user || this.CONFIG.user, function(res){
            var u;
            assert(this$ instanceof Laboratory);
            if (typeof res === 'string') {
              if (typeof (u = this$.CONFIG.users[res]) === 'object') {
                this$.CONFIG.user = res;
                this$.USER = u;
                this$.emit('notify', "loading user " + u.github.user);
                return done();
              } else {
                return ask_user("user doesn't exist");
              }
            } else if (typeof res === 'object') {
              if (typeof res.name === 'string' && typeof res.git === 'object') {
                this$.CONFIG.users[res.name] = res;
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
          dir = this$.opts.path || this$.CONFIG.path || Path.join(ToolShed.HOME_DIR, 'Projects');
          ask_path = Verse.prompt("Laboratory Projects path:", dir, function(res){
            if (typeof res === 'string') {
              return ToolShed.stat(res, function(err, st){
                if (err) {
                  if (err.code === 'ENOENT') {
                    return echo("TODO: ask the user if they want to create the path?");
                  }
                } else if (st.isDirectory()) {
                  this$.CONFIG.path = res;
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
          var path, walker, this$ = this;
          path = this.CONFIG.path;
          this.debug("using path %s", path);
          this.watcher = Fs.watch(path, function(evt, filename){
            var new_prj_path, offset;
            console.log("lab disturbance", arguments);
            if (evt === 'change') {
              return console.log("change event", arguments);
            } else if (evt === 'rename') {
              new_prj_path = Path.join(path, filename);
              offset = false;
              _.each(this$.prjs, function(prj, i){
                if (prj.path === new_prj_path) {
                  offset = i;
                  return false;
                }
              });
              return ToolShed.stat(new_prj_path, function(err, st){
                if (offset === false && !err && st.isDirectory()) {
                  return this$.exec('add_project', filename, new_prj_path);
                } else {
                  this$.prjs[offset].transition('close');
                  return this$.prjs.splice(offset, 0);
                }
              });
            }
          });
          walker = Walk(path, {
            max_depth: 1
          });
          walker.on('directory', function(path, st){
            var basename;
            basename = Path.basename(path);
            if (~this$.USER.projects.indexOf(basename)) {
              return this$.exec('add_project', basename, path);
            }
          });
          return walker.on('end', function(){
            return this$.transition('ready');
          });
        });
      }
    },
    ready: {
      onenter: function(){
        this.emit('ready');
        return echo("XXX: TODO ... walk the dirs and shit");
      },
      switch_user: function(user){
        echo("TODO: switch user");
        return prj_watcher.close();
      },
      add_project: function(name, path){
        var prj, this$ = this;
        this.prjs.push(prj = new Project({
          name: name,
          path: path
        }, {
          lab: this
        }));
        return prj.until('ready', function(){
          return this$.emit('new:Project', prj);
        });
      },
      remove_project: function(name){
        return console.error("TODO: ");
      }
    },
    setup: {
      onenter: function(){
        return echo("XXX: TODO ... set this shit up!!");
      }
    },
    close: {
      onenter: function(){
        var this$ = this;
        prj_watcher.close();
        return _.each(this.prjs, function(prj, i){
          prj.transition('close');
          this$.prjs[offset].transition('close');
          this$.prjs.splice(i, 0);
        });
      }
    }
  };
  return Laboratory;
}(Fsm));
out$.Project = Project = (function(superclass){
  var prototype = extend$((import$(Project, superclass).displayName = 'Project', Project), superclass).prototype, constructor = Project;
  function Project(opts, refs){
    var src_dir, lib_dir;
    this.opts = opts;
    this.refs = refs;
    if (typeof opts !== 'object') {
      throw new Error("you must pass an options object {name: '...', path: '...'}");
    }
    if (!opts.path) {
      throw new Error("you need a path for your project");
    } else if (opts.name) {
      opts.path = Path.join(refs.lab.path, opts.name);
    }
    if (typeof refs !== 'object') {
      throw new Error("you must pass in a reference to the lab");
    }
    this.lab = refs.lab;
    this.path = Path.resolve(opts.path);
    this.name = opts.name;
    if (!this.path) {
      throw new Error("invalid path " + opts.path);
    }
    src_dir = Path.join(this.path, 'src');
    lib_dir = Path.join(this.path, 'lib');
    Project.superclass.call(this, "Project(" + opts.name + ")");
  }
  prototype.dirs = {};
  prototype.states = {
    uninitialized: {
      onenter: function(){
        var pkg_src_path, pkg_json_path, pkg, this$ = this;
        pkg_src_path = Path.join(this.path, "package.json.ls");
        pkg_json_path = Path.join(this.path, "package.json");
        pkg = this.PACKAGE = Config(pkg_json_path);
        return pkg.once('ready', function(config, data){
          var src_dir, lib_dir;
          if (!data) {
            pkg.name = this$.name || Path.basename(this$.path);
            pkg.version = '0.0.1';
          }
          src_dir = Path.join(this$.path, 'src');
          lib_dir = Path.join(this$.path, 'lib');
          this$.exec('add_dir', 'src', src_dir, lib_dir);
          return this$.transition('ready');
        });
      }
    },
    ready: {
      onenter: function(){
        return this.emit('ready');
      },
      add_dir: function(name, path, into){
        var src_dir, this$ = this;
        this.dirs[name] = src_dir = new SrcDir({
          path: path,
          into: into
        }, {
          prj: this
        });
        return src_dir.once_initialized(function(){
          return this$.emit('new:SrcDir', src_dir);
        });
      }
    },
    'new': {
      onenter: function(){
        /*
        pkg_src = Src {
        	path: pkg_src_path
        	output: "name: 'untitled'"
        	write: path
        	watch: true
        }
        */
        pkg.name = opts.name || Path.basename(this.path);
        return pkg.version = '0.0.1';
      }
    }
  };
  return Project;
}(Fsm));
out$.SrcDir = SrcDir = (function(superclass){
  var prototype = extend$((import$(SrcDir, superclass).displayName = 'SrcDir', SrcDir), superclass).prototype, constructor = SrcDir;
  function SrcDir(opts, refs){
    this.opts = opts;
    this.refs = refs;
    if (typeof opts !== 'object') {
      throw new Error("SrcDir needs an object");
    }
    if (typeof opts.path !== 'string') {
      throw new Error("path must be provided");
    }
    this.dirs = {};
    this.srcs = {};
    SrcDir.superclass.call(this, refs.prj.name + "::SrcDir(" + Path.relative(refs.prj.path, opts.path) + ")");
  }
  prototype.states = {
    uninitialized: {
      onenter: function(){
        var this$ = this;
        if (this.opts.into) {
          ToolShed.mkdir(this.opts.into, function(err){
            if (err) {
              this$.emit('error', new Error("SrcDir already exists"));
              return this$.transition('error');
            }
          });
        } else {
          this.opts.into = this.opts.path;
        }
        if (this.opts.st && this.opts.st.isDirectory()) {
          this.transition('ready');
          return this.exec('walk');
        } else {
          return Fs.stat(this.opts.path, function(err, st){
            if (err) {
              if (err.code === 'ENOENT') {
                return ToolShed.mkdir(this$.opts.path, function(err){
                  this$.emit('error', err);
                  return this$.transition('error');
                });
              } else {
                this$.emit('error', err);
                return this$.transition('error');
              }
            } else if (st.isDirectory()) {
              this$.transition('ready');
              return this$.exec('walk');
            } else {
              this$.emit('error', new Error("SrcDir already exists"));
              return this$.transition('error');
            }
          });
        }
      }
    },
    ready: {
      onenter: function(){
        return this.emit('ready');
      },
      rescan: function(){
        return console.log("XXX: we should be rescanning now");
      },
      walk: function(){
        var this$ = this;
        this.watcher = Fs.watch(this.opts.path, function(evt, filename){
          var s, ref$, ref1$, path;
          echo("disturbance", evt, filename, this$.opts.path);
          if (evt === 'change') {
            if (filename && (s = this$.srcs[filename])) {
              return s.exec('read');
            } else {
              return _.each(this$.srcs, function(s){
                return s.exec('check');
              });
            }
          } else if (evt === 'rename') {
            console.log("XXX: src file renaming not yet supported!!", arguments);
            if (!filename) {
              return this$.transition('walk');
            } else {
              if (s = this$.srcs[filename]) {
                s.transition('destroy');
                return ref1$ = (ref$ = this$.srcs)[filename], delete ref$[filename], ref1$;
              } else if (s = this$.dirs[filename]) {
                s.transition('destroy');
                return ref1$ = (ref$ = this$.dirs)[filename], delete ref$[filename], ref1$;
              } else {
                path = Path.join(this$.opts.path, filename);
                return Fs.stat(path, function(err, st){
                  var ext, into_dir;
                  if (!err) {
                    if (st.isFile()) {
                      switch (ext = Path.extname(filename)) {
                      case '.ls':
                        return this$.exec('add_src', filename, path, this$.opts.into, st);
                      }
                    } else if (st.isDirectory()) {
                      into_dir = Path.join(this$.opts.into, filename);
                      return this$.exec('add_dir', filename, path, into_dir);
                    }
                  }
                });
              }
            }
          }
        });
        return process.nextTick(function(){
          var d;
          d = Walk(this$.opts.path, {
            max_depth: 1
          });
          d.on('error', function(err){
            return console.log("we got an error:", arguments);
          });
          d.on('end', function(){
            return this$.transition('ready');
          });
          d.on('file', function(path, st){
            var file, ext;
            file = Path.basename(path);
            if (!this$.srcs[file]) {
              switch (ext = Path.extname(file)) {
              case '.ls':
                return this$.exec('add_src', file, path, this$.opts.into, st);
              }
            }
          });
          return d.on('directory', function(path, st){
            var dir_name, into_dir;
            dir_name = Path.basename(path);
            into_dir = Path.join(this$.opts.into, dir_name);
            return this$.exec('add_dir', dir_name, path, into_dir);
          });
        });
      },
      add_src: function(name, path, into, st){
        var src, this$ = this;
        if (this.dirs[name]) {
          throw new Error("dir: " + name + " already exists");
        }
        this.srcs[name] = src = new Src({
          path: path,
          file: name,
          write: into,
          st: st
        }, {
          prj: this.refs.prj,
          dir: this
        });
        return src.once_initialized(function(){
          assert(this$ instanceof SrcDir);
          return this$.emit('new:Src', src);
        });
      },
      add_dir: function(name, path, into){
        var src_dir, this$ = this;
        if (this.dirs[name]) {
          throw new Error("dir: " + name + " already exists");
        }
        this.dirs[name] = src_dir = new SrcDir({
          name: name,
          path: path,
          into: into
        }, {
          prj: this.refs.prj,
          dir: this
        });
        return src_dir.once_initialized(function(){
          assert(this$ instanceof SrcDir);
          return this$.emit('new:SrcDir', src_dir);
        });
      }
    },
    close: {
      onenter: function(){
        var this$ = this;
        this.watcher.close();
        console.log("closing...");
        _.each(this.dirs, function(d, k){
          var ref$, ref1$;
          d.transition('close');
          return ref1$ = (ref$ = this$.dirs)[k], delete ref$[k], ref1$;
        });
        _.each(this.srcs, function(s, k){
          var ref$, ref1$;
          s.transition('close');
          return ref1$ = (ref$ = this$.srcs)[k], delete ref$[k], ref1$;
        });
        return this.emit('closed');
      }
    }
  };
  return SrcDir;
}(Fsm));
out$.Src = Src = (function(superclass){
  var prototype = extend$((import$(Src, superclass).displayName = 'Src', Src), superclass).prototype, constructor = Src;
  function Src(opts, refs){
    var outfile, file, idx_ext, ext, idx_ext2, this$ = this;
    this.opts = opts;
    this.refs = refs;
    if (typeof opts === 'string') {
      opts = {
        path: opts
      };
    } else if (typeof opts === 'object') {
      if (typeof this.opts.path !== 'string') {
        throw new Error("Src must have at least a path");
      }
    } else {
      throw new Error("Src not initialized correctly");
    }
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
      if (~(idx_ext = file.lastIndexOf('.'))) {
        ext = opts.ext
          ? opts.ext
          : file.substr(idx_ext);
        outfile = file.substr(0, idx_ext);
        if (~(idx_ext2 = file.substr(0, idx_ext).lastIndexOf('.'))) {
          ext = opts.ext
            ? opts.ext
            : file.substr(idx_ext2);
          outfile = file.substr(0, idx_ext2);
        }
        switch (ext) {
        case '.blueprint.ls':
          opts.blueprint = true;
          opts.result = true;
          ext = '.blueprint';
          break;
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
        if (ext !== '.js' && opts.result !== false) {
          opts.result = true;
        }
        outfile = outfile + ext;
      } else if (opts.ext) {
        outfile = file + opts.ext;
      } else {
        throw new Error("source file does not have an extension");
      }
      opts.ext = ext;
      opts.outfile = Path.join(opts.write, outfile);
    }
    Src.superclass.call(this, refs.prj.name + "::Src(" + Path.relative(refs.prj.path, opts.path) + ")");
  }
  prototype.eventListeners = {
    transition: function(){
      return this.debug("transition path %s %s", this.opts.path, this.namespace);
    }
  };
  prototype.states = {
    uninitialized: {
      onenter: function(){
        var this$ = this;
        if (typeof this.opts.st === 'object' && this.opts.st.mtime instanceof Date) {
          this.transition('ready');
          return this.exec(this.opts.src ? 'compile' : 'read');
        } else {
          return Fs.stat(this.opts.path, function(err, st){
            var now;
            if (err) {
              if (err.code === 'ENOENT') {
                this$.opts.src = '';
                now = new Date;
                this$.st = {
                  mtime: now,
                  ctime: now
                };
                return this$.transition('ready');
              } else {
                throw err;
              }
            } else {
              this$.st = st;
              this$.transition('ready');
              return this$.exec('read');
            }
          });
        }
      }
    },
    ready: {
      onenter: function(){
        var this$ = this;
        if (this.opts.watch && !this.watcher) {
          this.watcher = Fs.watchFile(this.opts.path, function(evt){
            this$.debug("file %s changed %s", file, this$.path);
            return this$.exec('read');
          });
        }
        return this.emit('ready');
      },
      read: function(){
        var this$ = this;
        return Fs.readFile(this.opts.path, 'utf-8', function(err, data){
          if (err) {
            return this$.transition('error');
          } else if (this$.opts.src !== data || true) {
            this$.opts.src = data;
            return this$.exec('compile');
          }
        });
      },
      check: function(){
        var e;
        console.log("what are we checking???");
        try {
          throw new Error("...");
        } catch (e$) {
          e = e$;
          return console.log(e.stack);
        }
      },
      compile: function(){
        var patch_ast, patch, search_ast, search, j1, searchlen, options, ast, i$, to$, width, i, l1, j2, e, this$ = this;
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
          this.opts.tokens = LiveScript.tokens(this.opts.src);
          this.opts.ast = LiveScript.ast(this.opts.tokens);
          if (this.opts.outfile === 'model.js') {
            ast = JSON.parse(JSON.stringify(this.opts.ast.toJSON()));
            if (global.window) {
              global.window.ast = this.opts.ast;
            }
            for (i$ = 0, to$ = width = ast.lines.length - searchlen; i$ < to$; ++i$) {
              i = i$;
              l1 = ast.lines.slice(i, i + searchlen);
              j2 = JSON.stringify(l1).replace(/[,]*\"line\":[0-9]+/g, '');
              if (j1 === j2) {
                console.log("found target at line #", i);
                ast.lines.splice.apply(this, [i, searchlen].concat(patch.lines));
                this.opts.ast = LSAst.fromJSON(ast);
              }
            }
          }
          if (this.opts.result) {
            this.opts.ast.makeReturn();
          }
          this.opts.output = this.opts.ast.compileRoot(options);
          if (this.opts.result) {
            process.chdir(Path.dirname(this.opts.path));
            this.opts.output = LiveScript.run(this.opts.output, options, true);
            process.chdir(CWD);
          }
          if (this.opts.blueprint) {
            this.opts.output = ToolShed.stringify(this.opts.output, ['name', 'encantador', 'incantation', 'version', 'embodies', 'poetry', 'eventListeners', 'layout']);
          } else if (this.opts.json) {
            this.opts.output = ToolShed.stringify(this.opts.output, ['name', 'version']);
          }
          this.refs.prj.emit(this.opts.ext.substr(1), this.opts.outfile, this.opts.output);
          if (this.opts.write) {
            return Fs.writeFile(this.opts.outfile, this.opts.output, function(err){
              if (err) {
                this$.emit('error', new Error("unable to write output to " + this$.opts.outfile));
                return this$.transition('error');
              } else {
                this$.debug("wrote %s", this$.opts.outfile);
                this$.emit('success', {
                  message: "compiled: '" + this$.opts.outfile + "' successfully"
                });
                return this$.transition('ready');
              }
            });
          } else {
            return this.transition('ready');
          }
        } catch (e$) {
          e = e$;
          if (~e.message.indexOf('Parse error')) {
            console.log(this.opts.path, ':', e.message);
          } else {
            console.log(this.opts.path, ':', e.stack);
          }
          this.emit('error', e);
          return this.transition('error');
        }
      }
    },
    destroy: {
      onenter: function(){
        var s, this$ = this;
        if (s = this.watcher) {
          s.close();
        }
        return Fs.unlink(this.opts.outfile, function(err){
          if (err && err.code !== 'ENOENT') {
            this$.emit('error', err);
          }
          return this$.emit('closed');
        });
      }
    },
    close: {
      onenter: function(){
        return this.emit('closed');
      }
    }
  };
  return Src;
}(Fsm));
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
function extend$(sub, sup){
  function fun(){} fun.prototype = (sub.superclass = sup).prototype;
  (sub.prototype = new fun).constructor = sub;
  if (typeof sup.extended == 'function') sup.extended(sub);
  return sub;
}
function import$(obj, src){
  var own = {}.hasOwnProperty;
  for (var key in src) if (own.call(src, key)) obj[key] = src[key];
  return obj;
}