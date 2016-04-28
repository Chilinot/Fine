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

