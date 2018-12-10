DEBUG=false

def raw_lines(f)
  IO.readlines(f, chomp: true)
end

def debug(s)
  puts "debug:   #{s}" if DEBUG
end

def test(actual, expected)
  print actual == expected ? "." : "fail, got #{expected} instead of #{actual}"
end

