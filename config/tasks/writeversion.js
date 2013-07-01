module.exports = function(grunt) {
    'use strict';
    grunt.registerMultiTask("writeversion", "Writes Mozart Version to version file", function () {
        var opts = this.data;

        grunt.verbose.writeln('starting');
        
        var src = grunt.file.read('src/mozart/mozart.coffee', { encoding: "utf8" });

        grunt.verbose.writeln(src);

        var version = src.match(/version\:\s\"([^\"]+)\"/)[1];

        grunt.log.writeln('Mozart version: '+version);

        grunt.file.write(opts.output, version);
    });
};