require 'yard'

YARD::Registry.root.children.each do |child|
  child.name(false)
  child.docstring.all
end
