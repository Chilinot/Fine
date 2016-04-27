def read_file filename
    content = File.read(filename)
    if content.valid_encoding?
        content
    else
        raise EncodingError.new
    end
end

def ast_to_string str
    # str.gsub(/#<struct /, "\n(").gsub(">", ")").gsub(",", "").gsub("[", "\n").gsub("]", "")
    str.gsub(/#<struct /, "\n<").gsub(",", "").gsub("[", "[").gsub("]", "]\n")
end

def make_function_type type
    map = {:CHAR => :CHAR_FUNCTION, :INT => :INT_FUNCTION, :VOID => :VOID_FUNCTION}
    map[type] or raise "#{type} is not a function type"
end

def make_array_type type
    map = {:CHAR => :CHAR_ARRAY, :INT => :INT_ARRAY}
    map[type] or raise "#{type} is not a array type"
end
