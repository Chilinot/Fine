
class Temporary < Struct.new(:index)
    def fix_globals locals; end
    def to_s
        "%#{index}"
    end
end

class Label < Struct.new(:name, :index)
    def fix_globals locals; end
    def to_s
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
    def to_s
        if global
            "@#{name}"
        else
            "%#{name}"
        end
    end
end

class Constant < Struct.new(:value)
    def fix_globals locals; end
    def to_s
        value.to_s
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
    puts ir.to_s
    ir
end

class Ir < Struct.new(:definitions)
    def to_s
        string = ""
        definitions.each do |d|
            string << definitions.to_s
        end
    end
end

class Eval < Struct.new(:destination, :expression);
    def fix_globals locals;
        destination.fix_globals locals
        expression.fix_globals locals
    end
    def to_s
        "#{destination} = #{expression}"
    end
end

class GlobalVariable < Struct.new(:name); end
class GlobalInt < GlobalVariable; def to_s; "global i32 #{name}" end end
class GlobalChar < GlobalVariable; def to_s; "global i8 #{name}" end end

class LocalVariable < Struct.new(:name); end
class LocalInt < LocalVariable; def to_s; "local i32 #{name}" end end
class LocalChar < LocalVariable; def to_s; "local i8 #{name}" end end

class GlobalArray < Struct.new(:name, :size); end
class GlobalIntArray < GlobalArray; def to_s; "global [i32 * #{size}] #{name}" end end
class GlobalCharArray < GlobalArray; def to_s; "global [i8 * #{size}] #{name}" end end

class LocalArray < Struct.new(:name, :size); end
class LocalIntArray < LocalArray; def to_s; "local [i8 * #{size}] #{name}" end end
class LocalCharArray < LocalArray; def to_s; "local [i8 * #{size}] #{name}" end end


class Function < Struct.new(:name, :type, :formals, :declarations, :instructions)
    def to_s
        formal_list = ""
        formals.each do |f|
            formal_list += ", " unless formal_list.empty?
            formal_list += "#{f[:type]} #{f[:name]}"
        end
        header = "def #{type} #{name}(#{formal_list}) {\n"

        declaration_list = ""
        declarations.each do |d|
            declaration_list += "  " + d.to_s + "\n"
        end

        instruction_list = ""
        instructions.each do |i|
            extra_indent = "  " unless i.instance_of? Label
            instruction_list += "  #{extra_indent}" + i.to_s + "\n"
        end

        header + declaration_list + instruction_list + "}"
    end
end

class Return < Struct.new(:op)
    def fix_globals locals
        op.fix_globals locals unless op == :VOID
    end
    def to_s
        "ret #{op}"
    end
end

class Binop < Struct.new(:op1, :op2)
    def fix_globals locals
        op1.fix_globals locals
        op2.fix_globals locals
    end
    def to_s
        "#{self.class.to_s.downcase} #{op1} #{op2}"
    end
end

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


class ArrayElement < Struct.new(:name, :index)
    def fix_globals locals
        global = locals.include? name
    end
    def to_s
        "#{name}[#{index}]"
    end
end
class IntArrayElement < ArrayElement; end
class CharArrayElement < ArrayElement; end

class Not < Struct.new(:op)
    def fix_globals locals
        op.fix_globals locals
    end
    def to_s
        "not #{op}"
    end
end
class Cast < Struct.new(:op, :from, :to)
    def fix_globals locals
        op.fix_globals locals
    end
    def to_s
        "cast #{to} #{op}"
    end
end
class Store < Struct.new(:type, :destination, :source);
    def fix_globals locals
        destination.fix_globals locals
        source.fix_globals locals
    end
    def to_s
        "store #{type} #{destination} #{source}"
    end
end
class Call < Struct.new(:name, :argument_list)
    def fix_globals locals;
         name.fix_globals locals
    end
    def to_s
        "call #{name} #{argument_list.map { |a| a.to_s }.join(" ")}"
    end
end

class Jump < Struct.new(:label)
    def fix_globals locals; end
    def to_s
        "jump #{label}"
    end
end
class Branch < Struct.new(:condition, :true_branch, :false_branch)
    def fix_globals locals
        condition.fix_globals locals
    end
    def to_s
        "br #{condition} #{true_branch} #{false_branch}"
    end
end
