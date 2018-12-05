DEBUG=false

def raw_lines(f)
  IO.readlines(f, chomp: true)
end

def debug(s)
  puts s if DEBUG
end
