require 'phantomjs'
Phantomjs.path # => path to a phantom js executable suitable to your current platform. Will install before return when not installed yet.

# Or run phantomjs with the passed arguments:
Phantomjs.run('./path/to/script.js') # => returns stdout

# Also takes a block to receive each line of output:
Phantomjs.run('./path/to/script.js') { |line| puts line }

