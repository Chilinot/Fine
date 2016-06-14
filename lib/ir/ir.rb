
class Temporary < Struct.new(:index)
    def fix_globals locals; end
    def generate_llvm
        "%#{index}"
    end
end

class Label < Struct.new(:name, :index)
    def fix_globals locals; end
    def generate_llvm
        "#{name}#{index}:"
    end
end

class Allocator
    def initialize
        @next_temporary = 0
        @next_label = 0
    end
    def new_temporary
        Temporary.new (@next_temporary += 1)
    end
    def new_label name
        Label.new name, (@next_label += 1)
    end
end

class Id < Struct.new(:name, :global)
    def fix_globals locals
        self.global = !locals.include?(name)
    end
    def generate_llvm
        if global
            "@#{name}"
        else
            "%#{name}"
        end
    end
end

class Constant < Struct.new(:value)
    def fix_globals locals; end
    def generate_llvm
        "#{value}"
    end
end



def generate_ir ast
    ir = Ir.new (ast.generate_ir [])
    functions = ir.definitions.select { |d| d.instance_of? Function }
    functions.each do |f|
        formals = f.formals.map {|f| f[:name] }
        locals = f.declarations.map { |d| d[:name] }

        f.instructions.each do |i|
            i.fix_globals locals + formals
        end
    end
    ir
end

class Ir < Struct.new(:definitions)
    def generate_llvm
        code = ""
        definitions.each do |d|
            code << d.generate_llvm
        end
        code
    end
end

class Eval < Struct.new(:destination, :expression);
    def fix_globals locals;
        destination.fix_globals locals
        expression.fix_globals locals
    end
    def generate_llvm
        "#{destination.generate_llvm} = #{expression.generate_llvm}"
    end
end

class GlobalVariable < Struct.new(:name); end
class GlobalInt < GlobalVariable; def generate_llvm; "@#{name} = global i32 zeroinitializer\n" end end
class GlobalChar < GlobalVariable; def generate_llvm; "@#{name} = global i8 zeroinitializer\n" end end

class LocalVariable < Struct.new(:name); end
class LocalInt < LocalVariable; def generate_llvm; "%#{name} = alloca i32\n" end end
class LocalChar < LocalVariable; def generate_llvm; "%#{name} = alloca i8\n" end end

class GlobalArray < Struct.new(:name, :size); end
class GlobalIntArray < GlobalArray; def generate_llvm; "@#{name} = global [#{size} x i32] zeroinitializer\n" end end
class GlobalCharArray < GlobalArray; def generate_llvm; "@#{name} = global [#{size} x i8] zeroinitializer\n" end end

class LocalArray < Struct.new(:name, :size); end
class LocalIntArray < LocalArray; def generate_llvm; "local [#{size} x i32] #{name}\n" end end
class LocalCharArray < LocalArray; def generate_llvm; "local [#{size} x i8] #{name}\n" end end

class FormalArgument < Struct.new(:name, :type, :temporary); end

class Function < Struct.new(:name, :type, :formals, :declarations, :instructions)
    def generate_llvm
        formal_list = ""
        formals.each do |f|
            formal_list += ", " unless formal_list.empty?
            formal_list += "#{llvm_type(f.type)} %#{f.name}"
        end
        header = "\ndefine #{llvm_type(type)} @#{name}(#{formal_list}) {\n"

        declaration_list = ""
        declarations.each do |d|
            declaration_list += "  " + d.generate_llvm + "\n"
        end

        instruction_list = ""
        instructions.each do |i|
            extra_indent = "  " unless i.instance_of? Label
            instruction_list += "  #{extra_indent}" + i.generate_llvm + "\n"
        end

        header + declaration_list + instruction_list + "}"
    end
end

class Return < Struct.new(:type, :op)
    def fix_globals locals
        op.fix_globals locals unless op == :VOID
    end
    def generate_llvm
        unless op == :VOID
            "ret #{type} #{op.generate_llvm}"
        else
            "ret #{type}"
        end
    end
end

class Binop < Struct.new(:op1, :op2)
    def fix_globals locals
        op1.fix_globals locals
        op2.fix_globals locals
    end
    def generate_llvm
        "#{self.class.to_s.downcase} #{op1.generate_llvm} #{op2.generate_llvm}"
    end
end

class Add          < Binop; end
class Sub          < Binop; end
class Mul          < Binop; end
class Div          < Binop; end
class LessThen     < Binop; end
class GreaterThen  < Binop; end
class LessEqual    < Binop; end
class GreaterEqual < Binop; end
class NotEqual     < Binop; end
class Equal        < Binop; end
class And          < Binop; end
class Or           < Binop; end


class ArrayElement < Struct.new(:type, :name, :num_elements, :index)
    def fix_globals locals
        global = locals.include? name
    end
    def generate_llvm
        "#{name}[#{index.generate_llvm}]"
    end
end

class Not < Struct.new(:op)
    def fix_globals locals
        op.fix_globals locals
    end
    def generate_llvm
        "not #{op.generate_llvm}"
    end
end
class Cast < Struct.new(:op, :from, :to)
    def fix_globals locals
        op.fix_globals locals
    end
    def generate_llvm
        "cast #{to} #{op.generate_llvm}"
    end
end

class Load < Struct.new(:type, :source);
    def fix_globals locals
        source.fix_globals locals
    end
    def generate_llvm
        "load #{type} #{source.generate_llvm}"
    end
end

class Store < Struct.new(:type, :destination, :source)
    def fix_globals locals
        destination.fix_globals locals
        source.fix_globals locals
    end
    def generate_llvm
        "store #{type} #{destination.generate_llvm} #{source.generate_llvm}"
    end
end
class Call < Struct.new(:name, :argument_list)
    def fix_globals locals;
        name.fix_globals locals
    end
    def generate_llvm
        "call #{name.generate_llvm} #{argument_list.map { |a| a.generate_llvm }.join(" ")}"
    end
end

class Jump < Struct.new(:label)
    def fix_globals locals; end
    def generate_llvm
        "jump #{label.generate_llvm}"
    end
end
class Branch < Struct.new(:condition, :true_branch, :false_branch)
    def fix_globals locals
        condition.fix_globals locals
    end
    def generate_llvm
        "br #{condition.generate_llvm} #{true_branch.generate_llvm} #{false_branch.generate_llvm}"
    end
end
