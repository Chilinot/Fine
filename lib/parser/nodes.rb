class Program                   < Struct.new(:nodes); end

class VarDeclaration            < Struct.new(:type, :name); end
class ArrayDeclaration          < Struct.new(:type, :name, :num_elements); end
class ExternFunctionDeclaration < Struct.new(:type, :name, :formals); end

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
    if expr.get_type == :INT
        return :INT
    else
        raise SemanticError.new ""
    end
end
class Not                       < Struct.new(:expr); end

class BinaryOperator            < Struct.new(:left, :right); end
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
