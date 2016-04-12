class Program < Struct.new(:nodes)
    # def to_s; "(Program #{nodes.join("\n")})"; end
end

class VarDeclaration < Struct.new(:type, :name)
    # def to_s; "#{type.to_s.downcase} #{name};" end
end
class ArrayDeclaration < Struct.new(:type, :name, :num_elements)
    # def to_s; "#{type} #{name}[#{num_elements ? num_elements : ""}];" end
end
class ExternFunctionDeclaration < Struct.new(:type, :name, :formals)
    # def to_s; "#{type.to_s.downcase} #{name} (#{formals.join(", ")});" end
end

class FunctionDeclaration < Struct.new(:type, :name, :formals, :body)
    # def to_s; "#{type.to_s.downcase} #{name} (#{formals.join ", " }) {\n#{body}\n}" end
end
class FunctionBody < Struct.new(:declarations, :statments)
    # def to_s; "#{declarations.join "\n"}#{statments.join "\n"}" end
end

class Constant < Struct.new(:type, :value)
    # def to_s; "#{type == :INT ? value : "'#{value}'"}" end
end
class Identifier < Struct.new(:name)
    # def to_s; name end
end

class ArrayLookup < Struct.new(:name, :expr)
    # def to_s; "#{type} #{name}[#{expr}]" end
end
class UnaryMinus < Struct.new(:expr)
    # def to_s; "-#{expr}" end
end
class Not < Struct.new(:expr)
    # def to_s; "!#{expr}" end
end

class BinaryOperator < Struct.new(:left, :right); end
class AddNode < BinaryOperator
    # def to_s; "#{left} + #{right}" end
end
class SubNode < BinaryOperator
    # def to_s; "#{left} - #{right}" end
end
class MulNode < BinaryOperator
    # def to_s; "#{left} * #{right}" end
end
class DivNode < BinaryOperator
    # def to_s; "#{left} / #{right}" end
end
class LessThanNode < BinaryOperator
    # def to_s; "#{left} < #{right}" end
end
class GreaterThanNode < BinaryOperator
    # def to_s; "#{left} > #{right}" end
end
class LessEqualNode < BinaryOperator
    # def to_s; "#{left} <= #{right}" end
end
class GreaterEqualNode < BinaryOperator
    # def to_s; "#{left} >= #{right}" end
end
class NotEqualNode < BinaryOperator
    # def to_s; "#{left} != #{right}" end
end
class EqualNode < BinaryOperator
    # def to_s; "#{left} == #{right}" end
end
class AndNode < BinaryOperator
    # def to_s; "#{left} && #{right}" end
end
class AssignNode < BinaryOperator
    # def to_s; "#{left} = #{right}" end
end
class FunctionCall < Struct.new(:name, :args)
    # def to_s; "#{name}(#{args.join ", "})" end
end

class Return < Struct.new(:expr)
    # def to_s; "return #{expr ? expr : ""};" end
end
class While < Struct.new(:condition, :block)
    # def to_s; "while (#{condition}) {\n #{block.join "\n"}\n}" end
end
class If < Struct.new(:condition, :then_block, :else_block)
    # def to_s
    #     str = "if (#{condition}) {\n #{then_block.join "\n"}\n}"
    #     str += "else {\n#{else_block.join "\n"}\n}" if else_block
    # end
end
