require_relative "semantic/error.rb"

class Program                   < Struct.new(:nodes)
    def check_semantics env
        nodes.each do |node|
            node.check_semantics env
        end
        return true
    end
    def generate_ir ir
        nodes.each do |node|
            node.generate_ir ir
        end
        return ir
    end
end

class VarDeclaration            < Struct.new(:type, :name)
    def get_type env
        type
    end
    def check_semantics env
        env[name] = {:class => :VARIABLE, :type => type}
        return true
    end
    def generate_ir ir
        case type
        when :INT then ir << GlobalInt.new(name)
        when :CHAR then ir << GlobalChar.new(name)
        else raise "unable to generate ir for type #{type}"
        end
    end
end
class ArrayDeclaration          < Struct.new(:type, :name, :num_elements)
    def get_type env
        "#{type}_ARRAY".to_sym
    end
    def check_semantics env
        env[name] =  {:class => :ARRAY, :type => type }
        return true
    end
end
class ExternFunctionDeclaration < Struct.new(:type, :name, :formals)
    def check_semantics env
        if env.defined? name
            raise SemanticError.new "'#{name}' already defined as #{type_to_s env[name][:class]}"
        else
            env[name] =  {:class => :FUNCTION, :type => type, :formals => formals, :num_formals => formals.count, :implemented => false}
        end
        return true
    end
end

class FunctionDeclaration       < Struct.new(:type, :name, :formals, :body)
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
end

class FunctionBody              < Struct.new(:declarations, :statments)
    def check_semantics env
        declarations.each do |decl|
            decl.check_semantics env
        end
        statments.each do |stmt|
            env.found_return_in_current_scope if stmt.instance_of? Return
            stmt.check_semantics env
        end
        return true
    end
end

class Constant                  < Struct.new(:type, :value)
    def get_type env
        type
    end
    def check_semantics env
        return true
    end
end
class Identifier                < Struct.new(:name)
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
end

class ArrayLookup               < Struct.new(:name, :expr)
    def get_type env
        check_semantics env
        env[name][:type]
    end
    def check_semantics env
        raise SemanticError.new "'#{name}' is not an array" unless env[name][:class] == :ARRAY
        return true
    end
end
class UnaryMinus                < Struct.new(:expr)
    def get_type env
        expr.get_type env
    end
    def check_semantics env
        expr.check_semantics env
    end
end
class Not                       < Struct.new(:expr)
    def get_type env
        expr.get_type env
    end
    def check_semantics env
        expr.check_semantics env
    end
end

class BinaryOperator            < Struct.new(:left, :right)
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
end
class AritmeticOperator < BinaryOperator; end

class AddNode                   < AritmeticOperator; def to_s; "+" end end
class SubNode                   < AritmeticOperator; def to_s; "-" end end
class MulNode                   < AritmeticOperator; def to_s; "*" end end
class DivNode                   < AritmeticOperator; def to_s; "/" end end
class LessThanNode              < BinaryOperator; def to_s; "<" end end
class GreaterThanNode           < BinaryOperator; def to_s; ">" end end
class LessEqualNode             < BinaryOperator; def to_s; "<=" end end
class GreaterEqualNode          < BinaryOperator; def to_s; ">=" end end
class NotEqualNode              < BinaryOperator; def to_s; "!=" end end
class EqualNode                 < BinaryOperator; def to_s; "==" end end
class AndNode                   < BinaryOperator; def to_s; "&&" end end
class OrNode                    < BinaryOperator; def to_s; "||" end end
class TypeCast                  < Struct.new(:type, :expr)
    def get_type env
        if [:INT, :CHAR].include? expr.get_type(env)
            return type
        else
            raise SemanticError.new "can not cast expression of type #{type_to_s expr.get_type(env)} to type #{type_to_s type}"
        end
    end
    def check_semantics env
        get_type(env) == type
    end
end

class AssignNode                < BinaryOperator
    def check_semantics env
        if (left.instance_of?(Identifier) and env[left.name][:class] == :VARIABLE) or left.instance_of?(ArrayLookup)
            if left.get_type(env) == right.get_type(env)
                return true
            else
                # error : type mismatch
                raise SemanticError.new "can not assign #{type_to_s right.get_type(env)} to variable of type #{type_to_s left.get_type(env)}"
            end
        end

        # error : can not be assigned
        if left.instance_of? Identifier
            raise SemanticError.new "can not assign to #{type_to_s env[left.name][:class]} reference '#{left.name}'"
        else
            raise SemanticError.new "can not assign to expression"
        end
    end
end

class FunctionCall              < Struct.new(:name, :args)
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
end

class Return                    < Struct.new(:expr)
    def check_semantics env
        return_type = env.current_return_type

        if return_type == :VOID and expr != :VOID
            raise SemanticError.new "attempt to return value from procedure"
        elsif return_type != :VOID and expr == :VOID
            raise SemanticError.new "void return from function"
        elsif expr.get_type(env) != return_type
            raise SemanticError.new "expression does not match return type"
        end
        return true
    end
end
class While                     < Struct.new(:condition, :body)
    def check_semantics env
        condition.check_semantics env
        body.each { |stmt| stmt.check_semantics env }
        return true
    end
end
class If                        < Struct.new(:condition, :then_block, :else_block)
    def check_semantics env
        condition.check_semantics env
        then_block.each { |stmt| stmt.check_semantics env }
        else_block.each { |stmt| stmt.check_semantics env } if else_block
        return true
    end
end
