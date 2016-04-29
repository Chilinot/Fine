require_relative "error.rb"

class Environment
    def initialize
        @stack = [Scope.new]
    end
    def defined? name
        @stack.reverse_each do |scope|
            return true if scope.defined? name
        end
        return false
    end
    def [] name
        lookup name
    end
    def []= name, value
        add name, value
    end
    def lookup name
        @stack.reverse_each do |scope|
            return scope[name] if scope.defined? name
        end
        raise SemanticError.new "'#{name}' was not defined"
    end
    def add name, type
        unless @stack.last.defined? name
            @stack.last[name] = type
        else
            raise SemanticError.new "'#{name}' already defined as #{lookup(name)[:class].to_s.downcase}"
        end
    end
    def push_scope return_type=nil
        @stack.push Scope.new return_type
    end
    def pop_scope
        @stack.pop
    end

    def current_return_type
        @stack.reverse_each do |scope|
            return scope.return_type if scope.return_type
        end
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
