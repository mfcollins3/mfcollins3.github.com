###############################################################################
#
# Rakefile
#
# This script is used to automate the process of building my personal website.
#
# Copyright 2012 Michael F. Collins, III
#
###############################################################################

require 'rake/clean'

CLEAN.include('./temp')

CLOBBER.include('./_site')
CLOBBER.include('./css')
CLOBBER.include('./javascript')

JAVASCRIPT_FILES = FileList.new('./lib/jquery/jquery.js')
JAVASCRIPT_FILES.include('./lib/twitter-bootstrap/js/bootstrap-transition.js')
JAVASCRIPT_FILES.include('./lib/twitter-bootstrap/js/bootstrap-modal.js')
JAVASCRIPT_FILES.include('./lib/twitter-bootstrap/js/bootstrap-dropdown.js')
JAVASCRIPT_FILES.include('./lib/twitter-bootstrap/js/bootstrap-scrollspy.js')
JAVASCRIPT_FILES.include('./lib/twitter-bootstrap/js/bootstrap-tab.js')
JAVASCRIPT_FILES.include('./lib/twitter-bootstrap/js/bootstrap-tooltip.js')
JAVASCRIPT_FILES.include('./lib/twitter-bootstrap/js/bootstrap-popover.js')
JAVASCRIPT_FILES.include('./lib/twitter-bootstrap/js/bootstrap-alert.js')
JAVASCRIPT_FILES.include('./lib/twitter-bootstrap/js/bootstrap-button.js')
JAVASCRIPT_FILES.include('./lib/twitter-bootstrap/js/bootstrap-collapse.js')
JAVASCRIPT_FILES.include('./lib/twitter-bootstrap/js/bootstrap-carousel.js')
JAVASCRIPT_FILES.include('./lib/twitter-bootstrap/js/bootstrap-typeahead.js')
JAVASCRIPT_FILES.include('./lib/twitter-bootstrap/js/bootstrap-affix.js')

STYLESHEET_FILES = FileList.new('./src/stylesheets/normal.less')
CSS_FILES = STYLESHEET_FILES.pathmap('%{^./src/stylesheets,./css}X.css')

desc 'Builds the website'
task :default => [:compile_stylesheets, './javascript/website.js'] do
  sh "jekyll --pygments --safe"
end

task :compile_stylesheets => ['./css/images', './temp', './css/images/glyphicons-halflings.png', './css/images/glyphicons-halflings-white.png'] + CSS_FILES

directory './css/images'

directory './javascript'

directory './temp'

file './css/images/glyphicons-halflings-white.png' => ['./lib/twitter-bootstrap/img/glyphicons-halflings-white.png'] do
  cp './lib/twitter-bootstrap/img/glyphicons-halflings-white.png', './css/images/glyphicons-halflings-white.png'
end

file './css/images/glyphicons-halflings.png' => ['./lib/twitter-bootstrap/img/glyphicons-halflings.png'] do
  cp './lib/twitter-bootstrap/img/glyphicons-halflings.png', './css/images/glyphicons-halflings.png'
end

file './javascript/website.js' => ['./javascript'] + JAVASCRIPT_FILES do
  sh "java -jar lib/googleclosurecompiler/compiler.jar --js #{JAVASCRIPT_FILES.join(' --js ')} > ./javascript/website.js"
end

rule(/\.css$/ => [proc {|t| t.pathmap('%{^./css,./src/stylesheets}X.less')}]) do |t|
  tempCssName = t.name.pathmap('%{^./css,./temp}X.css')
  sh "lessc #{t.source} #{tempCssName}"
  sh "java -jar lib/yuicompressor/build/yuicompressor-2.4.8pre.jar --type css #{tempCssName} > #{t.name}"
end