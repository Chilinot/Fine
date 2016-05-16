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
