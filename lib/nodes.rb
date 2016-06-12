require_relative "semantic/error.rb"

class ProgramNode < Struct.new(:nodes)
    def check_semantics env
        nodes.each do |node|
            node.check_semantics env
        end
        return true
    end
    def generate_ir ir
        nodes.each do |node|
            if node.instance_of? VariableDeclarationNode or node.instance_of? ArrayDeclarationNode
                node.generate_ir ir, true # generate global declarations
            else
                node.generate_ir ir
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
    def generate_ir ir, global = false
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
        env[name] =  {:class => :ARRAY, :type => type, :num_elements => num_elements}
        return true
    end
    def generate_ir ir, global = false
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
    def generate_ir ir
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
    def generate_ir ir
        ir_formals = []
        formals.each do |f|
            ir_formals << {:name => f.name, :type => f.get_type(:no_environment)}
        end

        ir_declarations = []
        body.declarations.each do |d|
            d.generate_ir ir_declarations
        end

        ir_statments = []
        body.statments.each do |s|
            s.generate_ir ir_statments, Allocator.new
        end

        ir << Function.new(name, type, ir_formals, ir_declarations, ir_statments)
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
        return true
    end
    def generate_ir ir, _
        Constant.new(value.ord)
    end
end

class IdentifierNode < Struct.new(:name)
    def get_type env
        if [:ARRAY, :FUNCTION].include? env[name][:class]
            "#{env[name][:type]}_#{env[name][:class]}".to_sym
        else
            env[name][:type]
        end
    end
    def check_semantics env
        env.defined? name
    end
    def generate_ir ir, allocator
        Id.new(name)
    end
end

class ArrayLookupNode < Struct.new(:name, :expr)
    def get_type env
        @type = env[name][:type]
        check_semantics env
        @type
    end
    def check_semantics env
        @num_elements = env[name][:num_elements]
        raise SemanticError.new "'#{name}' is not an array" unless env[name][:class] == :ARRAY
        return true
    end
    def generate_ir ir, allocator
        case @type
        when :INT
            IntArrayElement.new(name, @num_elements, expr.generate_ir(ir, allocator))
        when :CHAR
            CharArrayElement.new(name, @num_elements, expr.generate_ir(ir, allocator))
        else
            raise "unable to generate ir array of type #{type}"
        end
    end
end

class UnaryMinusNode < Struct.new(:expr)
    def get_type env
        expr.get_type env
    end
    def check_semantics env
        expr.check_semantics env
    end
    def generate_ir ir, allocator
        e = expr.generate_ir(ir, allocator)
        binop = Sub.new(Constant.new(0), e)

        temp = allocator.new_temporary
        ir << Eval.new(temp, binop)
        temp
    end
end

class NotNode < Struct.new(:expr)
    def get_type env
        expr.get_type env
    end
    def check_semantics env
        expr.check_semantics env
    end
    def generate_ir ir, allocator
        not_expr = Not.new(expr.generate_ir(ir, allocator))
        temp = allocator.new_temporary
        ir << Eval.new(temp, not_expr)
        temp
    end
end

class BinaryOperator < Struct.new(:left, :right)
    def get_type env
        right_type = right.get_type(env)
        if left.get_type(env) == right_type
            return right_type
        else
            raise SemanticError.new "#{type_to_s left.get_type(env)} #{self} #{type_to_s right.get_type(env)} is not defined"
        end
    end
    def check_semantics env
        get_type env
        return true
    end
    def generate_ir ir, allocator
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
        left_temp = left.generate_ir ir, allocator
        right_temp = right.generate_ir ir, allocator
        binop = ast_nodes[self.class].new(left_temp, right_temp)

        temp = allocator.new_temporary
        ir << Eval.new(temp, binop)
        temp
    end
end
class AritmeticOperator < BinaryOperator; end

class AddNode                   < AritmeticOperator; def to_s; "+" end end
class SubNode                   < AritmeticOperator; def to_s; "-" end end
class MulNode                   < AritmeticOperator; def to_s; "*" end end
class DivNode                   < AritmeticOperator; def to_s; "/" end end
class LessThenNode              < BinaryOperator; def to_s; "<" end end
class GreaterThenNode           < BinaryOperator; def to_s; ">" end end
class LessEqualNode             < BinaryOperator; def to_s; "<=" end end
class GreaterEqualNode          < BinaryOperator; def to_s; ">=" end end
class NotEqualNode              < BinaryOperator; def to_s; "!=" end end
class EqualNode                 < BinaryOperator; def to_s; "==" end end
class AndNode                   < BinaryOperator; def to_s; "&&" end end
class OrNode                    < BinaryOperator; def to_s; "||" end end

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
    def generate_ir ir, allocator
        if type == @expr_type # discard if same type
            return expr.generate_ir(ir, allocator)
        end
        cast =  Cast.new(expr.generate_ir(ir, allocator), @expr_type, type)

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
    def generate_ir ir, allocator
        ir << Store.new(@left_type, left.generate_ir(ir, allocator), right.generate_ir(ir, allocator))
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
        num_args = args.count

        raise SemanticError.new "'#{name}' expected #{num_formals} arguments, but got #{args.count}" if num_args != num_formals

        formals = info[:formals]
        num_args.times do |i|
            if formals[i].get_type(env) != args[i].get_type(env)
                raise SemanticError.new "'#{name}' expected argument at position #{i+1} to be of type #{type_to_s formals[i].get_type(env)}, but got type #{type_to_s args[i].get_type(env)}"
            end
        end

        return true
    end
    def generate_ir ir, allocator
        argument_list = args.map do |expr|
            expr.generate_ir ir, allocator
        end
         call = Call.new(Id.new(name), argument_list)

        temp = allocator.new_temporary
        ir << Eval.new(temp, call)
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
    def generate_ir ir, temp_allocator
        if expr == :VOID
            ir << Return.new(llvm_type(@type), :VOID)
        else
            ir << Return.new(llvm_type(@type), expr.generate_ir(ir, temp_allocator))
        end
    end
end
class WhileNode < Struct.new(:condition, :body)
    def check_semantics env
        condition.check_semantics env
        body.each { |stmt| stmt.check_semantics env }
        return true
    end
    def generate_ir ir, allocator
        while_start = allocator.new_label "while_start"
        while_body = allocator.new_label "while_body"
        while_end = allocator.new_label "while_end"

        ir << Jump.new(while_start)
        ir << while_start
            cond = condition.generate_ir ir, allocator
            ir << Branch.new(cond, while_body, while_end)
        ir << while_body

            body.each do |stmt|
                stmt.generate_ir ir, allocator
            end

            ir << Jump.new(while_start)
        ir << while_end
    end
end
class IfNode < Struct.new(:condition, :then_block, :else_block)
    def check_semantics env
        condition.check_semantics env
        then_block.each { |stmt| stmt.check_semantics env }
        else_block.each { |stmt| stmt.check_semantics env } if else_block
        return true
    end
    def generate_ir ir, allocator
        if_then = allocator.new_label "if_then"
        if_else = allocator.new_label "if_else" if else_block
        if_end = allocator.new_label "if_end"

        # if condition
        cond = condition.generate_ir ir, allocator
        if else_block
            ir << Branch.new(cond, if_then, if_else)
        else
            ir << Branch.new(cond, if_then, if_end)
        end

        # then block
        ir << if_then
        then_block.each do |stmt|
            stmt.generate_ir ir, allocator
        end
        ir << Jump.new(if_end)

        # else block
        if else_block
            ir << if_else
            else_block.each do |stmt|
                stmt.generate_ir ir, allocator
            end
            ir << Jump.new(if_end)
        end

        ir << if_end
    end
end
