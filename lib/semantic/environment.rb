require_relative "error.rb"

class Environment
    def initialize
        @stack = [Scope.new]
    end
    def [] name
        lookup name
    end
    def []= name, value
        add name, value
    end
    def lookup name# => type
        @stack.reverse_each do |scope|
            return scope[name] if scope.defined? name
        end
        raise SemanticError.new "#{name} was not defined"
    end
    def add name, type
        unless @stack.last.defined? name
            @stack.last[name] = type
        else
            raise SemanticError.new "#{name} already defined"
        end
    end
    def push_scope return_type=nil
        @stack.push Scope.new return_type
    end
    def pop_scope
        @stack.pop # TODO: check returns?
    end

    def valid_return? type
        @stack.last.return_type == type
    end

    class Scope
        attr_reader :return_type
        def initialize return_type = nil
            @return_type = return_type
            @definitions = {}
        end
        def [] name
            @definitions[name]
        end
        def []= name, value
            @definitions[name] = value
        end
        def defined? name
            @definitions.has_key? name
        end
    end
end
