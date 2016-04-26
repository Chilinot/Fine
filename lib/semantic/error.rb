class SemanticError < StandardError
    def initialize(message)
        @message = message
    end
    def to_s
        "Semantic error: #{@message}"
    end
end
