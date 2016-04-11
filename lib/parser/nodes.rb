class Program < Struct.new(:nodes); end

class VarDeclaration < Struct.new(:type, :name); end
class ArrayDeclaration < Struct.new(:type, :name, :num_elements); end
class ExternFunctionDeclaration < Struct.new(:type, :name, :formals); end

class FunctionDeclaration < Struct.new(:type, :name, :formals, :body); end
class FunctionBody < Struct.new(:declarations, :statments); end

class Constant < Struct.new(:type, :value); end
class Identifier < Struct.new(:name); end

class ArrayLookup < Struct.new(:name, :expr); end
class UnaryMinus < Struct.new(:expr); end
class Not < Struct.new(:expr); end

class BinaryOperator < Struct.new(:left, :right); end
class AddNode < BinaryOperator; end
class SubNode < BinaryOperator; end
class MulNode < BinaryOperator; end
class DivNode < BinaryOperator; end
class LessThanNode < BinaryOperator; end
class GreaterThanNode < BinaryOperator; end
class LessEqualNode < BinaryOperator; end
class GreaterEqualNode < BinaryOperator; end
class NotEqualNode < BinaryOperator; end
class EqualNode < BinaryOperator; end
class AndNode < BinaryOperator; end
class AssignNode < BinaryOperator; end
