class SemanticError < StandardError
    def initialize(message)
        @message = message
        puts self
    end
    def to_s
        "Semantic error: #{@message}"
    end
end
