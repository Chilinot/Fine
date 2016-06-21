
class Pointer
    def initialize type
        @type = type
    end
    def to_s
        "#{@type}*"
    end
end


def llvm_type type
    map = {
        :INT_ARRAY => Pointer.new(:i32),
        :CHAR_ARRAY => Pointer.new(:i8),
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

def llvm_file_to_asm_file llvm_filename, asm_filename
    cmd = "llc -O3 -o #{asm_filename.dump} #{llvm_filename.dump}"
    output = `#{cmd}`

    return $?.exitstatus == 0
end

def asm_file_to_exe_file asm_filename, bin_filename
    cmd = "gcc -o #{bin_filename.dump} #{asm_filename.dump}"
    output = `#{cmd}`

    return $?.exitstatus == 0
end

def llvm_file_to_exe_file llvm_filename, exe_filename
    asm_filename = exe_filename + ".s"
    status = llvm_file_to_asm_file llvm_filename, asm_filename
    status = asm_file_to_exe_file asm_filename, exe_filename if status
    return status
end

def generate_llvm ir
    ir.generate_llvm
end
