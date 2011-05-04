libdir = File::dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'ecore/repository'
require 'ecore/node'
require 'ecore/node/asset'
require 'ecore/security/session'

