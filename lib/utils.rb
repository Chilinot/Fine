def read_file filename
    content = File.read(filename)
    if content.valid_encoding?
        content
    else
        raise EncodingError.new
    end
end

def write_file filename, content
    File.open(filename, "w") do |file|
        file.write(content)
    end
end

def type_to_s type
    type.to_s.downcase.gsub("_","-")
end
