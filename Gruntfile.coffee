###
Copyright 2015 Michael F. Collins, III
###

module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    jekyll:
      options:
        bundleExec: true
      build: {}
      serve:
        options:
          serve: true
          watch: true
          drafts: true
    concat:
      options:
        sourceMap: true
      vendorJS:
        src: [
          'bower_components/jquery/dist/jquery.min.js',
          'bower_components/bootstrap/dist/js/bootstrap.min.js'
        ]
        dest: 'js/vendor.js'
    copy:
      fonts:
        expand: true
        cwd: 'bower_components/bootstrap/dist/fonts/'
        src: ['**']
        dest: 'fonts/'
    less:
      options:
        paths: ['bower_components/bootstrap/less']
      themes:
        expand: true
        cwd: 'less/'
        src: ['*.less']
        dest: 'css/'
        ext: '.css'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-jekyll'

  grunt.registerTask '_build', [
    'concat',
    'copy',
    'less'
  ]
  grunt.registerTask 'default', 'Builds the website', [
    '_build',
    'jekyll:build'
  ]
  grunt.registerTask 'serve', 'Builds and serves the website', [
    '_build',
    'jekyll:serve'
  ]
