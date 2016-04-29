require_relative "error.rb"

class Environment
    def initialize
        @stack = [Scope.new(:VOID,"global")]
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
    def push_scope return_type, name
        @stack.push Scope.new return_type, name
    end
    def pop_scope
        scope = @stack.pop
        raise SemanticError.new "missing return in '#{scope.name}'" if scope.need_return
    end

    def found_return_in_current_scope
        @stack.last.need_return = false
    end

    def current_return_type
        @stack.reverse_each do |scope|
            return scope.return_type if scope.return_type
        end
    end

    class Scope
        attr_reader :return_type, :name
        attr_accessor :need_return
        def initialize return_type, name
            @name = name
            @return_type = return_type
            @need_return = return_type != :VOID
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
