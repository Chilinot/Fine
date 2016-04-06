def read_file filename
    content = File.read(filename)
    if content.valid_encoding?
        content
    else
        raise EncodingError.new
    end
end
