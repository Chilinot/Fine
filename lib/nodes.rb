require_relative "semantic/error.rb"
require_relative "code/code_generation.rb"

class ProgramNode < Struct.new(:nodes)
    def check_semantics env
        nodes.each do |node|
            node.check_semantics env
        end
        return true
    end
    def generate_ir builtin, ir
        nodes.each do |node|
            if node.instance_of? VariableDeclarationNode or node.instance_of? ArrayDeclarationNode
               node.generate_ir builtin, ir, true # generate global declarations
            else
                node.generate_ir builtin, ir
            end
        end
        return ir
    end
end

class VariableDeclarationNode < Struct.new(:type, :name)
    def get_type env
        type
    end
    def check_semantics env
        env[name] = {:class => :VARIABLE, :type => type}
        return true
    end
    def generate_ir builtin, ir, global = false
        case type
        when :INT
            if global
            then ir << GlobalInt.new(name)
            else ir << LocalInt.new(name)
            end
        when :CHAR
            if global
            then ir << GlobalChar.new(name)
            else ir << LocalChar.new(name)
            end
        else
            raise "unable to generate ir for type #{type}"
        end
    end
end
class ArrayDeclarationNode < Struct.new(:type, :name, :num_elements)
    def get_type env
        "#{type}_ARRAY".to_sym
    end
    def check_semantics env
        get_type env
        env[name] =  {:class => :ARRAY, :type => type, :num_elements => num_elements}
        return true
    end
    def generate_ir builtin, ir, global = false
        case type
        when :INT
            if global
            then ir << GlobalIntArray.new(name, num_elements)
            else ir << LocalIntArray.new(name, num_elements)
            end
        when :CHAR
            if global
            then ir << GlobalCharArray.new(name, num_elements)
            else ir << LocalCharArray.new(name, num_elements)
            end
        else
            raise "unable to generate ir for array of type #{type}"
        end
        return ir
    end
end
class ExternFunctionDeclarationNode < Struct.new(:type, :name, :formals)
    def check_semantics env
        if env.defined? name
            raise SemanticError.new "'#{name}' already defined as #{type_to_s env[name][:class]}"
        else
            env[name] =  {:class => :FUNCTION, :type => type, :formals => formals, :num_formals => formals.count, :implemented => false}
        end
        return true
    end
    def generate_ir builtin, ir
        if builtin.is_built_in? self
            builtin.include_builtin(name)
        end
        return ir
    end
end

class FunctionDeclarationNode < Struct.new(:type, :name, :formals, :body)
    def check_semantics env
        if env.defined? name
            if env[name][:class] != :FUNCTION
                    raise SemanticError.new "'#{name}' already defined as #{type_to_s env[name][:class]}"
            elsif env[name][:implemented]
                    raise SemanticError.new "function '#{name}' already implemented"
            else
                # TODO: check if formals match!!
                env[name][:implemented] = true

                extern_formals = env[name][:formals]
                extern_formals.each_with_index do |formal,i|
                    if formals[i].get_type(env) != formal.get_type(env)
                        raise SemanticError.new "'#{name}' expected formal at position #{i+1} to be of type #{type_to_s formal.get_type(env)}, but was type #{type_to_s formals[i].get_type(env)}"
                    end
                end
            end
        else
            env[name] = {:class => :FUNCTION, :type => type, :formals => formals, :num_formals => formals.count, :implemented => true}
        end

        # Check body
        env.push_scope type, name
            formals.each do |formal|
                formal.check_semantics env
            end
            body.check_semantics env
        env.pop_scope
        return true
    end
    def generate_ir builtin, ir
        ir_formals = []
        allocator = Allocator.new
        formals.each do |f|
            if f.class == ArrayDeclarationNode
                ir_formals << FormalArgument.new(f.name, llvm_type(f.get_type(:no_environment)), :YOU_SHALL_NOT_GENERATE_ALLOCATIONS)
            else
                ir_formals << FormalArgument.new(f.name, llvm_type(f.get_type(:no_environment)), allocator.new_temporary)
            end
        end

        ir_declarations = []
        body.declarations.each do |d|
            d.generate_ir builtin, ir_declarations
        end

        ir_statments = []
        body.statments.each do |s|
            s.generate_ir builtin, ir_statments, allocator
        end
        ir_statments << Return.new(:void) if type == :VOID and ir_statments.last.class != Return

        ir << Function.new(name, llvm_type(type), ir_formals, ir_declarations, ir_statments)
    end
end

class FunctionBodyNode < Struct.new(:declarations, :statments)
    def check_semantics env
        declarations.each do |decl|
            decl.check_semantics env
        end
        statments.each do |stmt|
            env.found_return_in_current_scope if stmt.instance_of? ReturnNode
            stmt.check_semantics env
        end
        return true
    end
end

class ConstantNode < Struct.new(:type, :value)
    def get_type env
        type
    end
    def check_semantics env
        get_type env
        return true
    end
    def generate_ir builtin, ir, _
        Constant.new(llvm_type(type), value.ord)
    end
end

class IdentifierNode < Struct.new(:name)
    def get_type env
        # @type = env[name][:type]
        @identifier_type = env[name][:class]
        if :ARRAY == env[name][:class]
            @num_elements = env[name][:num_elements]
            @plain_type = env[name][:type]
        end
        if [:ARRAY, :FUNCTION].include? env[name][:class]
            @type = "#{env[name][:type]}_#{env[name][:class]}".to_sym

        else
            @type = env[name][:type]
        end
        @type
    end
    def check_semantics env
        get_type env
        env.defined? name
    end
    def generate_ir builtin, ir, allocator
        # puts @identifier_type
        if @identifier_type == :ARRAY

            temp = allocator.new_temporary
            ir << Eval.new(temp, ArrayElement.new(llvm_type(@plain_type), name, @num_elements, Constant.new(:i32, 0)))
            temp
        else
            temp = allocator.new_temporary
            ir << Eval.new(temp, Load.new(llvm_type(@type), Id.new(name)))
            temp
        end
    end
end

class ArrayLookupNode < Struct.new(:name, :expr)
    def get_type env
        @type = env[name][:type]
        check_semantics env
        @type
    end
    def check_semantics env
        @type = env[name][:type]
        @num_elements = env[name][:num_elements]
        expr.check_semantics env
        raise SemanticError.new "'#{name}' is not an array" unless env[name][:class] == :ARRAY
        return true
    end
    def generate_address_ir builtin, ir, allocator
        index = expr.generate_ir(builtin, ir, allocator)
        temp = allocator.new_temporary
        ir << Eval.new(temp, ArrayElement.new(llvm_type(@type), name, @num_elements, index))
        return temp
    end
    def generate_ir builtin, ir, allocator
        element_pointer = generate_address_ir builtin, ir, allocator
        temp = allocator.new_temporary
        ir << Eval.new(temp, Load.new(llvm_type(@type), element_pointer))
        return temp
    end
end

class UnaryMinusNode < Struct.new(:expr)
    def get_type env
        expr.get_type env
    end
    def check_semantics env
        expr.check_semantics env
    end
    def generate_ir builtin, ir, allocator
        e = expr.generate_ir(builtin, ir, allocator)
        binop = Sub.new(:i32, Constant.new(:i32, 0), e)

        temp = allocator.new_temporary
        ir << Eval.new(temp, binop)
        temp
    end
end

class NotNode < Struct.new(:expr)
    def get_type env
        @type = expr.get_type env
        @type
    end
    def check_semantics env
        get_type env
        expr.check_semantics env
    end
    def generate_ir builtin, ir, allocator
        not_expr = expr.generate_ir(builtin, ir, allocator)
        not_temp = allocator.new_temporary
        zero_extend_temp = allocator.new_temporary

        ir << Eval.new(not_temp, Not.new(llvm_type(@type), not_expr))
        ir << Eval.new(zero_extend_temp, ZeroExtend.new(not_temp, :i1, llvm_type(@type)))
        zero_extend_temp
    end
end

class BinaryOperator < Struct.new(:left, :right)
    def get_type env
        right_type = right.get_type(env)
        left_type = left.get_type(env)
        if left_type and right_type and left_type == right_type
            @type = right_type
            return right_type
        else
            raise SemanticError.new "#{type_to_s left.get_type(env)} #{self} #{type_to_s right.get_type(env)} is not defined"
        end
    end
    def check_semantics env
        get_type env
        @type = right.get_type env
        return true
    end
    def generate_ir builtin, ir, allocator
        ast_nodes = {
                AddNode          => Add,
                SubNode          => Sub,
                MulNode          => Mul,
                DivNode          => Div,
                LessThenNode     => LessThen,
                GreaterThenNode  => GreaterThen,
                LessEqualNode    => LessEqual,
                GreaterEqualNode => GreaterEqual,
                NotEqualNode     => NotEqual,
                EqualNode        => Equal,
                AndNode          => And,
                OrNode           => Or
        }
        left_temp = left.generate_ir builtin, ir, allocator
        right_temp = right.generate_ir builtin, ir, allocator
        binop = ast_nodes[self.class].new(llvm_type(@type), left_temp, right_temp)



        if self.instance_of? OrNode

            or_temp = allocator.new_temporary
            compare_temp = allocator.new_temporary
            cast_temp = allocator.new_temporary

            ir << Eval.new(or_temp, Or.new(llvm_type(@type), left_temp, right_temp))
            ir << Eval.new(compare_temp, Compare.new(llvm_type(@type), or_temp))
            ir << Eval.new(cast_temp, ZeroExtend.new(compare_temp, :i1, llvm_type(@type)))
            return cast_temp

        elsif self.instance_of? AndNode

            left_compare = allocator.new_temporary
            right_compare = allocator.new_temporary
            and_temp = allocator.new_temporary
            cast_temp = allocator.new_temporary

            ir << Eval.new(left_compare, Compare.new(llvm_type(@type), left_temp))
            ir << Eval.new(right_compare, Compare.new(llvm_type(@type), right_temp))
            ir << Eval.new(and_temp, And.new(:i1, left_compare, right_compare))
            ir << Eval.new(cast_temp, ZeroExtend.new(and_temp, :i1, llvm_type(@type)))
            return cast_temp
        end

        temp = allocator.new_temporary
        ir << Eval.new(temp, binop)
        if self.is_a? BooleanOperator
            cast_temp = allocator.new_temporary
            ir << Eval.new(cast_temp, ZeroExtend.new(temp, :i1, llvm_type(@type)))
            cast_temp
        else
            temp
        end
    end
end
class AritmeticOperator < BinaryOperator; end
class BooleanOperator < BinaryOperator; end
class LogicOperator < BinaryOperator; end

class AddNode                   < AritmeticOperator; def to_s; "+" end end
class SubNode                   < AritmeticOperator; def to_s; "-" end end
class MulNode                   < AritmeticOperator; def to_s; "*" end end
class DivNode                   < AritmeticOperator; def to_s; "/" end end
class LessThenNode              < BooleanOperator; def to_s; "<" end end
class GreaterThenNode           < BooleanOperator; def to_s; ">" end end
class LessEqualNode             < BooleanOperator; def to_s; "<=" end end
class GreaterEqualNode          < BooleanOperator; def to_s; ">=" end end
class NotEqualNode              < BooleanOperator; def to_s; "!=" end end
class EqualNode                 < BooleanOperator; def to_s; "==" end end
class AndNode                   < LogicOperator; def to_s; "&&" end end
class OrNode                    < LogicOperator; def to_s; "||" end end

class TypeCastNode < Struct.new(:type, :expr)
    def get_type env
         @expr_type = expr.get_type(env)
        if [:INT, :CHAR].include? @expr_type
            return type
        else
            raise SemanticError.new "can not cast expression of type #{type_to_s expr.get_type(env)} to type #{type_to_s type}"
        end
    end
    def check_semantics env
        get_type(env) == type
    end
    def generate_ir builtin, ir, allocator
        if type == @expr_type # discard if same type
            return expr.generate_ir(builtin, ir, allocator)
        end
        cast =  Cast.new(expr.generate_ir(builtin, ir, allocator), llvm_type(@expr_type), llvm_type(type))

        temp = allocator.new_temporary
        ir << Eval.new(temp, cast)
        temp
    end
end

class AssignNode                < BinaryOperator
    def check_semantics env
        if (left.instance_of?(IdentifierNode) and env[left.name][:class] == :VARIABLE) or left.instance_of?(ArrayLookupNode)
            @left_type = left.get_type env
            @right_type = right.get_type env
            if @left_type == @right_type
                return true
            else
                # error : type mismatch
                raise SemanticError.new "can not assign #{type_to_s @right_type} to variable of type #{type_to_s @left_type}"
            end
        end

        # error : can not be assigned
        if left.instance_of? IdentifierNode
            raise SemanticError.new "can not assign to #{type_to_s env[left.name][:class]} reference '#{left.name}'"
        else
            raise SemanticError.new "can not assign to expression"
        end
    end
    def generate_ir builtin, ir, allocator
        if left.instance_of? IdentifierNode
            ir << Store.new(llvm_type(@left_type), Id.new(left.name), right.generate_ir(builtin, ir, allocator))
        elsif left.instance_of? ArrayLookupNode
            ir << Store.new(llvm_type(@left_type), left.generate_address_ir(builtin, ir, allocator), right.generate_ir(builtin, ir, allocator))
        end
    end
end

class CallNode < Struct.new(:name, :args)
    def get_type env
        info = env.lookup name
        check_semantics env
        raise SemanticError.new "function #{name} does not return a value" if info[:type] == :VOID
        info[:type]
    end
    def check_semantics env
        raise SemanticError.new "'#{name}' is not a function or procedure" unless env[name][:class] == :FUNCTION

        info = env.lookup name
        num_formals = info[:num_formals]
        @type = info[:type]
        num_args = args.count

        raise SemanticError.new "'#{name}' expected #{num_formals} arguments, but got #{args.count}" if num_args != num_formals

        formals = info[:formals]
        @formal_types = args.map { |a| a.get_type(env) }
        num_args.times do |i|
            if formals[i].get_type(env) != args[i].get_type(env)
                raise SemanticError.new "'#{name}' expected argument at position #{i+1} to be of type #{type_to_s formals[i].get_type(env)}, but got type #{type_to_s args[i].get_type(env)}"
            end
        end

        return true
    end
    def generate_ir builtin, ir, allocator
        # puts @formal_types.inspect
        argument_list = args.each_with_index.map do |expr, i|
            id = expr.generate_ir builtin, ir, allocator
            {:type => llvm_type(@formal_types[i]), :id => id}
        end

         call = Call.new(llvm_type(@type), Id.new(name), argument_list)

        temp = allocator.new_temporary
        if @type != :VOID
            ir << Eval.new(temp, call)
        else
            ir << call
        end
        temp
    end
end

class ReturnNode < Struct.new(:expr)
    def get_type env
        if expr != :VOID
            return expr.get_type env
        end
        return :VOID
    end
    def check_semantics env
        return_type = env.current_return_type
        @type = return_type

        if return_type == :VOID and expr != :VOID
            raise SemanticError.new "attempt to return value from procedure"
        elsif return_type != :VOID and expr == :VOID
            raise SemanticError.new "void return from function"
        elsif expr != :VOID and expr.get_type(env) != return_type
            raise SemanticError.new "expression does not match return type"
        end
        return true
    end
    def generate_ir builtin, ir, allocator
        if expr == :VOID
            ir << Return.new(llvm_type(@type))
        else
            ir << Return.new(llvm_type(@type), expr.generate_ir(builtin, ir, allocator))
        end
        allocator.new_temporary # allocate temporary for implicit basic block
    end
end
class WhileNode < Struct.new(:condition, :body)
    def check_semantics env
        condition.check_semantics env
        @type = condition.get_type env
        body.each { |stmt| stmt.check_semantics env }
        return true
    end
    def generate_ir builtin, ir, allocator
        while_start = allocator.new_label "while_start"
        while_body = allocator.new_label "while_body"
        while_end = allocator.new_label "while_end"

        ir << Jump.new(while_start)
        ir << while_start
            cond = condition.generate_ir builtin, ir, allocator
            temp = allocator.new_temporary
            ir << Eval.new(temp, Compare.new(llvm_type(@type), cond))
            ir << Branch.new(temp, while_body, while_end)
        ir << while_body

            body.each do |stmt|
                stmt.generate_ir builtin, ir, allocator
            end

            ir << Jump.new(while_start)
        ir << while_end
    end
end
class IfNode < Struct.new(:condition, :then_block, :else_block)
    def check_semantics env
        condition.check_semantics env
        @type = condition.get_type env
        then_block.each { |stmt| stmt.check_semantics env }
        else_block.each { |stmt| stmt.check_semantics env } if else_block
        return true
    end
    def generate_ir builtin, ir, allocator
        if_then = allocator.new_label "if_then"
        if_else = allocator.new_label "if_else" if else_block
        if_end = allocator.new_label "if_end"

        # if condition
        cond = condition.generate_ir builtin, ir, allocator
        temp = allocator.new_temporary
        ir << Eval.new(temp, Compare.new(llvm_type(@type), cond))
        if else_block
            ir << Branch.new(temp, if_then, if_else)
        else
            ir << Branch.new(temp, if_then, if_end)
        end

        # then block
        ir << if_then
        then_block.each do |stmt|
            stmt.generate_ir builtin, ir, allocator
        end
        ir << Jump.new(if_end)

        # else block
        if else_block
            ir << if_else
            else_block.each do |stmt|
                stmt.generate_ir builtin, ir, allocator
            end
            ir << Jump.new(if_end)
        end

        ir << if_end
    end
end
