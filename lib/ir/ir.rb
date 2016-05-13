def generate_ir ast
    Ir.new []
end

class Ir < Struct.new(:definitions)
end
