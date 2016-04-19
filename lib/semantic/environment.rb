class Environment
    def initialize
        @stack = [{}]
    end
    def lookup name# => type
        @stack.reverse_each do env
            return env[name] if env.has_key? name
        end
        raise SemanticError.new "#{name} was not defined"
    end
    def add name, type
        unless @stack.last.has_key? name
            @stack.last[name] = type
        else
            raise SemanticError.new "#{name} already defined"
        end
    end
    def push
        @stack.push {}
    end
    def pop
        @stack.pop
    end
end
