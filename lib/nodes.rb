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
    def check_semantics env
        env[name] = {:type => type}
    end
end
class ArrayDeclaration          < Struct.new(:type, :name, :num_elements)
    def check_semantics env
        env[name] =  {:type => make_array_type(type) }
    end
end
class ExternFunctionDeclaration < Struct.new(:type, :name, :formals)
    def check_semantics env
        env[name] =  {:type => make_function_type(type), :return_type => type}
    end
end

class FunctionDeclaration       < Struct.new(:type, :name, :formals, :body)
    def check_semantics env
        env[name] = {:type => make_function_type(type), :return_type => type, :formals => formals, :num_formals => formals.count}
        env.push_scope type
            formals.each do |formal|
                env[formal.name] = {:type => formal.type}
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
            stmt.check_semantics env
        end
    end
end

class Constant                  < Struct.new(:type, :value)
    def get_type env
        type
    end
    def check_semantics env

    end
end
class Identifier                < Struct.new(:name)
    def get_type env
        env[name]
    end
    def check_semantics env
        env[name] and true
    end
end

class ArrayLookup               < Struct.new(:name, :expr)
    def get_type env
        env[name]
    end
    def check_semantics env
        [:INT_ARRAY, :CHAR_ARRAY].include? env[name] or raise SemanticError.new "#{name} is not an array"
    end
end
class UnaryMinus                < Struct.new(:expr)
    def get_type env
        if expr.get_type(env) == :INT
            return :INT
        else
            raise SemanticError.new("")
        end
    end
end
class Not                       < Struct.new(:expr); end

class BinaryOperator            < Struct.new(:left, :right)
    def get_type env
        left_type = left.get_type env
        right_type = right.get_type env
        if left_type == right_type
            return right_type
        else
            raise SemanticError.new "#{left_type.to_s.downcase} #{self} #{right_type.to_s.downcase.gsub("_", "-")} is not defined"
        end
    end
    def check_semantics env
        get_type env
    end
end
class AddNode                   < BinaryOperator; def to_s; "+" end end
class SubNode                   < BinaryOperator; def to_s; "-" end end
class MulNode                   < BinaryOperator; def to_s; "*" end end
class DivNode                   < BinaryOperator; def to_s; "/" end end
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
        if (left.instance_of? Identifier or left.instance_of? ArrayLookup) and right.get_type(env) == env[left.name]
            return true
        else
            left_type = left.get_type env
            case left_type
            when :INT_FUNCTION, :CHAR_FUNCTION
                raise SemanticError.new "can not assign to function"
            when :INT_ARRAY, :CHAR_ARRAY
                raise SemanticError.new "reference to #{left_type.to_s.downcase.gsub("_","-")} can not be modified"
            else
                raise SemanticError.new "invalid assignment"
            end
        end
    end
end
class FunctionCall              < Struct.new(:name, :args)
    def get_type env
        info = env.lookup name
        check_semantics env
        info[:return_type]
    end
    def check_semantics env
        raise SemanticError.new "#{name} is not a function or procedure" unless [:CHAR_FUNCTION, :INT_FUNCTION, :VOID_FUNCTION].include? env[name]

        info = env.lookup name
        num_formals = info[:num_formals]
        num_args = args.count

        raise SemanticError.new "#{name} expected #{num_formals} arguments, but got #{args.count}" if num_args != num_formals

        formals = info[:formals]
        num_args.times do |i|
            if formals[i].type != args[i].get_type(env)
                raise SemanticError.new "#{name} expected argument at position #{i+1} to be of type #{formals[i].type.to_s.downcase}, but got type #{args[i].get_type(env).to_s.downcase}"
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
