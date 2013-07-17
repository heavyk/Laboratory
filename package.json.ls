# Updater!

name: 'Laboratory'
version: '0.1.1'
description: 'development made easy'
keywords: <[
	development environment dev cli
]>
homepage: 'https://github.com/heavyk/Laboratory'
author: 'flames of love <mechanicofthesequence@gmail.com>'
contributors: [
	'flames of love <mechanicofthesequence@gmail.com>'
]
maintainers: [
	'flames of love <mechanicofthesequence@gmail.com>'
]
engines:
	node: '>0.8.3'
repository:
	type: 'git'
	url: 'https://github.com/heavyk/Laboratory.git'
bugs:
	url: 'https://github.com/heavyk/Laboratory/issues'
main: './lib/updater.js'
dependencies:
	semver: \x
	request: \x
	fstream: \x
	'fstream-ignore': \x
	tar: \x
	temp: \x
	rimraf: \x
	debug: \x
	lodash: \x
	mkdirp: \x # utils dep
	fibers: \x # utils dep
	archiver: \x # archivist dep
	walkdir: \x # archivist dep
	commander: \x # laboratory dep
	ini: \x # laboratory dep
	github: \x # laboratory dep
directories:
	src: 'src'
	lib: 'lib'
	#doc: 'doc'
	example: 'examples'
sencillo:
	universe: \facilmente
	creator:
		name: 'duralog'
		email: 'funisher@gmail.com'
#updater:
#	manifest: ...
#	repository:
#		type: \git
#		url: 'git://github.com/heavyk/Laboratory.git'
