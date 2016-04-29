require_relative "semantic/error.rb"

class Program                   < Struct.new(:nodes)
    def check_semantics env
        nodes.each do |node|
            node.check_semantics env
        end
        return true
    end
end

class VarDeclaration            < Struct.new(:type, :name)
    def get_type env
        type
    end
    def check_semantics env
        env[name] = {:class => :VARIABLE, :type => type}
    end
end
class ArrayDeclaration          < Struct.new(:type, :name, :num_elements)
    def get_type env
        "#{type}_ARRAY".to_sym
    end
    def check_semantics env
        env[name] =  {:class => :ARRAY, :type => type }
    end
end
class ExternFunctionDeclaration < Struct.new(:type, :name, :formals)
    def check_semantics env
        if env.defined? name
            raise SemanticError "'#{name}' already defined as #{type_to_s env[name][:class]}"
        else
            env[name] =  {:class => :FUNCTION, :type => type, :formals => formals, :num_formals => formals.count, :implemented => false}
        end
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
    end
end

class Constant                  < Struct.new(:type, :value)
    def get_type env
        type
    end
    def check_semantics env
        true
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
end
class Not                       < Struct.new(:expr); end

class BinaryOperator            < Struct.new(:left, :right)
    def get_type env
        left_type = left.get_type env
        right_type = right.get_type env
        if left_type == right_type
            return right_type
        else
            raise SemanticError.new "#{type_to_s left_type} #{self} #{type_to_s right_type} is not defined"
        end
    end
    def check_semantics env
        get_type env
    end
end


class AritmeticOperator < BinaryOperator
    def get_type env
        left_type = left.get_type env
        right_type = right.get_type env
        allowed_types = [:INT, :CHAR]
        if left_type == right_type and allowed_types.include?(right_type)
            return right_type
        else
            raise SemanticError.new "#{type_to_s left_type} #{self} #{type_to_s right_type} is not defined"
        end
    end
    def check_semantics env
        get_type env
    end
end
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

class AssignNode                < BinaryOperator
    def check_semantics env
        if (left.instance_of?(Identifier) and env[left.name][:class] == :VARIABLE) or left.instance_of? ArrayLookup
            if left.get_type(env) == right.get_type(env)
                # ok
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
class While                     < Struct.new(:condition, :block); end
class If                        < Struct.new(:condition, :then_block, :else_block)
    def check_semantics env
        condition.check_semantics env
        then_block.each { |stmt| stmt.check_semantics env }
        else_block.each { |stmt| stmt.check_semantics env } if else_block
    end
end
