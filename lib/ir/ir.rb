class Temporary
    def initialize index
        @index = index
    end
    def to_s
        "##{index}"
    end
    def == index
        @index == index
    end
end

class Id
    def initialize name
        @name = name
    end
    def to_s
        "##{name}"
    end
    def == name
        @name == name
    end
end

class Constant
    def initialize value
        @value = value
    end
    def to_s
        "#{value}"
    end
    def == value
        @value == value
    end
end

class TempAllocator
    def initialize
        @next = 0
    end
    def new_temporary
        Temporary.new (@next += 1)
    end
end


def generate_ir ast
    Ir.new (ast.generate_ir [])
end

class Ir < Struct.new(:definitions)
end

class GlobalInt < Struct.new(:name)
end

class GlobalChar < Struct.new(:name)
end

class GlobalIntArray < Struct.new(:name, :size)
end

class GlobalCharArray < Struct.new(:name, :size)
end


class LocalInt < Struct.new(:name)
end

class LocalChar < Struct.new(:name)
end

class LocalIntArray < Struct.new(:name, :size)
end

class LocalCharArray < Struct.new(:name, :size)
end

class Function < Struct.new(:name, :type, :formals, :declarations, :instructions)
end

class Return < Struct.new(:register)
end
