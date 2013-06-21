/*global module */

module.exports = function (grunt) {

    // Load additional modules.
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-handlebars');
    grunt.loadNpmTasks('grunt-contrib-jasmine');
    grunt.loadNpmTasks('grunt-contrib-uglify');

    // Load our custom tasks.
    grunt.loadTasks('config/tasks');

    /**
     * Define our Grunt configuration.
     */
    grunt.initConfig({

        browserify: {
            "mozart.js": {
                entries: ["src/mozart/mozart.coffee"]
            }
        },

        // Handle compiling our app.
        coffee: {
            compile: {
                files: {
                    'test/spec.js': [
                        'src/spec/**/*-spec.coffee'
                    ]
                }
            }
        },

        // Handle compiling our spec templates.
        handlebars: {
            compile: {
                options: {
                    namespace: 'HandlebarsTemplates',
                    processName: function (original) {
                        return original.replace('.hbs', '');
                    },
                    wrapped: true
                },
                files: {
                    'test/templates.js': 'src/templates/*.hbs'
                }
            }
        },

        // Enable command line execution of tests.
        jasmine: {
            src: [
                'mozart.js'
            ],
            options: {
                vendor: [
                    'src/lib/jquery-1.8.2.min.js',
                    'src/lib/underscore-min.js',
                    'src/lib/handlebars-1.0.rc.1.js',
                    'src/lib/sinon-1.6.0.js',
                    'test/templates.js'
                ],
                specs: [
                    'test/spec.js'
                ],
                junit: {
                    path: 'test/junit/'
                }
            }
        },

        // Enable minification for production deployment.
        uglify: {
            dist: {
                files: {
                    'mozart.min.js' : [ 'mozart.js' ]
                }
            }
        }
    });

    // Build task
    grunt.registerTask('build', ['browserify', 'coffee', 'handlebars']);

    // Package for production.
    grunt.registerTask('package', ['build', 'uglify']);

    // Tests
    grunt.registerTask('test', ['build','jasmine']);
};
