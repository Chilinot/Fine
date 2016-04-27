require_relative "error.rb"
require_relative "environment.rb"

def semantic_analysis ast
    ast.check_semantics Environment.new
end
