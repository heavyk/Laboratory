// todo: that thing where I check to see if require, module, exports exists
if(require.extensions['.ls']) {
	module.exports = require('./src/laboratory')
} else {
	module.exports = require('./lib/laboratory')
}
