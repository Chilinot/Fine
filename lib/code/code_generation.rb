
def llvm_type type
    map = {
        :INT  => :i32,
        :CHAR => :i8,
        :VOID => :void
    }
    raise "no llvm type for '#{type}'" unless map.include? type

    return map[type]
end

def llvm_type_size type
    map = {
        :i32 => 32,
        :i8 => 8,
        :i1 => 1,
    }
    raise "no size for type for '#{type}'" unless map.include? type
    return map[type]
end

def generate_llvm ir
    ir.generate_llvm
end
