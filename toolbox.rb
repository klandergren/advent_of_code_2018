require 'logger'

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::INFO

def raw_lines(f)
  IO.readlines(f, chomp: true)
end

def test(actual, expected)
  print actual == expected ? "." : "fail, got #{expected} instead of #{actual}"
  actual == expected
end

