DEBUG=false

def raw_lines(f)
  IO.readlines(f, chomp: true)
end

def debug(s)
  puts s if DEBUG
end

def test(actual, expected)
  puts (actual == expected ? "pass" : "fail, got #{expected} instead of #{actual}" )
end

