require 'orthoses'
require 'rgot/cli'
require 'yard'
require 'orthoses-yard'

# build cache
Orthoses::Utils.rbs_environment(collection: true)

Orthoses.logger.level = :warn

exit Rgot::Cli.new(["-v", *ARGV]).run
