require_relative "semantic/error.rb"

class Program                   < Struct.new(:nodes)
    def check_semantics env
        nodes.each do |node|
            env.add node if node.delaration?
        end
        nodes.each do |node|

        end
    end
end

class VarDeclaration            < Struct.new(:type, :name)
    def check_semantics env
        env.add name, type
    end
end
class ArrayDeclaration          < Struct.new(:type, :name, :num_elements)
    def check_semantics env
        env.add name, "#{type}_ARRAY"
    end
end
class ExternFunctionDeclaration < Struct.new(:type, :name, :formals)
    def check_semantics env
        env.add name, type
    end
end

class FunctionDeclaration       < Struct.new(:type, :name, :formals, :body); end
class FunctionBody              < Struct.new(:declarations, :statments); end

class Constant                  < Struct.new(:type, :value)
    def get_type env
        type
    end
end
class Identifier                < Struct.new(:name)
    def get_type env
        env.lookup name
    end
end

class ArrayLookup               < Struct.new(:name, :expr)
    def get_type env
        env.lookup name
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
        return :INT if left.get_type(env) == :INT && right.get_type(env) == :INT
    end
end
class AddNode                   < BinaryOperator; end
class SubNode                   < BinaryOperator; end
class MulNode                   < BinaryOperator; end
class DivNode                   < BinaryOperator; end
class LessThanNode              < BinaryOperator; end
class GreaterThanNode           < BinaryOperator; end
class LessEqualNode             < BinaryOperator; end
class GreaterEqualNode          < BinaryOperator; end
class NotEqualNode              < BinaryOperator; end
class EqualNode                 < BinaryOperator; end
class AndNode                   < BinaryOperator; end
class AssignNode                < BinaryOperator; end
class FunctionCall              < Struct.new(:name, :args); end

class Return                    < Struct.new(:expr); end
class While                     < Struct.new(:condition, :block); end
class If                        < Struct.new(:condition, :then_block, :else_block); end

