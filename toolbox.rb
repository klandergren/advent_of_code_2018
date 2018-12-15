require 'logger'

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::WARN

def raw_lines(f)
  IO.readlines(f, chomp: true)
end

def test(actual, expected)
  print actual == expected ? "." : "fail, got #{expected} instead of #{actual}"
end

