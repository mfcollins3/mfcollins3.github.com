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

CLEAN.include('./_temp')

CLOBBER.include('./_site')
CLOBBER.include('./css')
CLOBBER.include('./javascript')

JAVASCRIPT_FILES = FileList.new('./lib/modernizr/modernizr.js')
JAVASCRIPT_FILES.include('./lib/jquery/jquery.js')
JAVASCRIPT_FILES.include('./lib/handlebars/handlebars.runtime.js')
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
JAVASCRIPT_FILES.include('./lib/jstree/jquery.jstree.js')

STYLESHEET_FILES = FileList.new('./src/themes/normal.less')
CSS_FILES = STYLESHEET_FILES.pathmap('%{^./src/themes,./css}X.css')

HANDLEBARS_FILES = FileList.new('./src/templates/*.handlebars')
TEMPLATE_FILES = HANDLEBARS_FILES.pathmap('%{^./src,./_temp}X.js')

HOMEPAGE_JAVASCRIPT_FILES = FileList.new('./src/javascript/homepage.js')

BLOG_JAVASCRIPT_FILES = FileList.new('./src/javascript/blog.js')

EVENTS_JAVASCRIPT_FILES = FileList.new('./lib/fullcalendar/fullcalendar.js')
EVENTS_JAVASCRIPT_FILES.include('./src/javascript/events.js')

PAGE_JAVASCRIPT_MODULES = FileList.new('./javascript/homepage.js')
PAGE_JAVASCRIPT_MODULES.include('./javascript/blog.js')
PAGE_JAVASCRIPT_MODULES.include('./javascript/events.js')

FONT_FILES = FileList.new('./lib/font-awesome/font/fontawesome-webfont.eot')
FONT_FILES.include('./lib/font-awesome/font/fontawesome-webfont.svg')
FONT_FILES.include('./lib/font-awesome/font/fontawesome-webfont.ttf')
FONT_FILES.include('./lib/font-awesome/font/fontawesome-webfont.woff')
FONT_FILES.include('./lib/font-awesome/font/FontAwesome.otf')
CSS_FONT_FILES = FONT_FILES.pathmap('./css/fonts/%f')

JSTREE_SOURCE_THEME_FILES = FileList.new('./lib/jstree/themes/default/**/*.*')
JSTREE_THEME_FILES = JSTREE_SOURCE_THEME_FILES.pathmap('%{^./lib,./javascript}p')

desc 'Builds the website'
task :default => [:compile_stylesheets, :compile_javascript_modules, :compile_templates] do
  sh "jekyll build"
end

task :compile_javascript_modules => ['./javascript/website.js', :compile_page_javascript_modules, :copy_jstree_files]

task :copy_jstree_files => ['./javascript/jstree/themes/default'] + JSTREE_THEME_FILES

task :compile_page_javascript_modules => PAGE_JAVASCRIPT_MODULES

task :compile_stylesheets => ['./css/fonts', './css/images', './_temp/css', './css/images/glyphicons-halflings.png', './css/images/glyphicons-halflings-white.png'] + CSS_FILES + CSS_FONT_FILES

task :compile_templates => ['./_temp/templates'] + TEMPLATE_FILES

directory './css/fonts'

directory './css/images'

directory './javascript'

directory './javascript/jstree/themes/default'

directory './_temp/css'

directory './_temp/templates'

file './css/fonts/FontAwesome.otf' => ['./lib/font-awesome/font/FontAwesome.otf'] do
	cp './lib/font-awesome/font/FontAwesome.otf', './css/fonts/FontAwesome.otf'
end

file './css/images/glyphicons-halflings-white.png' => ['./lib/twitter-bootstrap/img/glyphicons-halflings-white.png'] do
  cp './lib/twitter-bootstrap/img/glyphicons-halflings-white.png', './css/images/glyphicons-halflings-white.png'
end

file './css/images/glyphicons-halflings.png' => ['./lib/twitter-bootstrap/img/glyphicons-halflings.png'] do
  cp './lib/twitter-bootstrap/img/glyphicons-halflings.png', './css/images/glyphicons-halflings.png'
end

file './javascript/events.js' => ['./javascript'] + EVENTS_JAVASCRIPT_FILES do
  sh "java -jar lib/googleclosurecompiler/compiler.jar --js #{EVENTS_JAVASCRIPT_FILES.join(' --js ')} > ./javascript/events.js"
end

file './javascript/homepage.js' => ['./javascript'] + HOMEPAGE_JAVASCRIPT_FILES do
  sh "java -jar lib/googleclosurecompiler/compiler.jar --js #{HOMEPAGE_JAVASCRIPT_FILES.join(' --js ')} > ./javascript/homepage.js"
end

file './javascript/blog.js' => ['./javascript'] + BLOG_JAVASCRIPT_FILES do
  sh "java -jar lib/googleclosurecompiler/compiler.jar --js #{BLOG_JAVASCRIPT_FILES.join(' --js ')} > ./javascript/blog.js"
end

file './javascript/website.js' => ['./javascript'] + JAVASCRIPT_FILES do
  sh "java -jar lib/googleclosurecompiler/compiler.jar --js #{JAVASCRIPT_FILES.join(' --js ')} > ./javascript/website.js"
end

rule(/^\.\/css\/fonts\/fontawesome-webfont\./ => [proc {|t| t.pathmap('./lib/font-awesome/font/%f')}]) do |t|
	cp t.source, t.name
end

rule(/\.css$/ => [proc {|t| t.pathmap('%{^./css,./src/themes}X.less')}]) do |t|
  tempCssName = t.name.pathmap('%{^./css,./_temp/css}X.css')
  sh "lessc #{t.source} #{tempCssName}"
  sh "java -jar lib/yuicompressor/build/yuicompressor-2.4.8pre.jar --type css #{tempCssName} > #{t.name}"
end

rule(/^\.\/_temp\/templates\// => [proc {|t| t.pathmap('%{^./_temp,./src}X.handlebars')}]) do |t|
  sh "handlebars #{t.source} -f #{t.name}"
end

rule(/^\.\/javascript\/jstree\// => [proc {|t| t.pathmap('%{^./javascript,./lib}p')}]) do |t|
  cp t.source, t.name
end
