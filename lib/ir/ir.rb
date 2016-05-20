class Temporary
    attr_reader :index
    def initialize index
        @index = index
    end
    def to_s
        "##{index}"
    end
    def == temporary
        @index == temporary.index
    end
end

class Id
    attr_reader :name
    def initialize name
        @name = name
    end
    def inspect
        to_s
    end
    def to_s
        "##{name}"
    end
    def == id
        @name == id.name
    end
end

class Constant
    attr_reader :value
    def initialize value
        @value = value
    end
    def to_s
        "#{value}"
    end
    def == constant
        @value == constant.value
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

class Binop < Struct.new(:destination, :left, :right); end

class Add          < Binop; end
class Sub          < Binop; end
class Mul          < Binop; end
class Div          < Binop; end
class LessThan     < Binop; end
class GreaterThan  < Binop; end
class LessEqual    < Binop; end
class GreaterEqual < Binop; end
class NotEqual     < Binop; end
class Equal        < Binop; end
class And          < Binop; end
class Or           < Binop; end

class ArrayElement < Struct.new(:name, :index); end
class IntArrayElement < ArrayElement; end
class CharArrayElement < ArrayElement; end

