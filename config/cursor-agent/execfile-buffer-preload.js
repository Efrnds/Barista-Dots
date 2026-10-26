'use strict';
/**
 * Node 24+ defaults child_process.execFile encoding to utf8.
 * cursor-agent clipboard.ts reads wl-paste/xclip via execFile + Buffer.concat,
 * which throws on strings → Ctrl+V image attach always misses.
 * Force binary encoding for clipboard paste helpers.
 */
const cp = require('child_process');
const path = require('path');

const orig = cp.execFile;
const BINARY = new Set(['wl-paste', 'xclip', 'pngpaste', 'osascript']);

cp.execFile = function execFileBufferFix(file, args, options, callback) {
  if (typeof args === 'function') {
    callback = args;
    args = undefined;
    options = undefined;
  } else if (typeof options === 'function') {
    callback = options;
    options = undefined;
  } else if (args != null && typeof args === 'object' && !Array.isArray(args)) {
    options = args;
    args = undefined;
  }

  const bin = typeof file === 'string' ? path.basename(file) : '';
  if (BINARY.has(bin)) {
    options = Object.assign({}, options || {}, { encoding: 'buffer' });
  }

  if (typeof callback === 'function') {
    return orig.call(this, file, args || [], options || {}, callback);
  }
  if (options !== undefined) {
    return orig.call(this, file, args || [], options);
  }
  if (args !== undefined) {
    return orig.call(this, file, args);
  }
  return orig.call(this, file);
};
