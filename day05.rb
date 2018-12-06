require_relative 'toolbox'

# loop of single passes through polymer replacing polar pairs with nil
def reduce_polymer(polymer)
  loop do
    polymer.compact!

    # hack to get each_cons() to return all elements to map
    polymer << nil if polymer.size % 2 == 0

    delete_next = false
    polymer = polymer.each_cons(2).map do |a, b|
      if delete_next
        delete_next = false
        next
      end

      if a != b && (a.upcase == b || a.downcase == b)
        delete_next = true
        next
      end
      a
    end
    break unless polymer.any? {|e| e.nil? }
  end
  polymer
end

def extract_polymer_from_file(f)
  raw_lines(f).first.chars
end

def part1(f)
  reduce_polymer(extract_polymer_from_file(f)).size
end

# brute force
def part2(f)
  polymer = extract_polymer_from_file(f)
  min = 100_000_000
  ("a".."z").each do |l|
    modified_polymer = polymer.reject {|u| u == l || u == l.upcase }
    num = reduce_polymer(modified_polymer).size
    min = num if num < min
  end
  min
end

def run_tests
  test_data_file = "data/day05_test_polymer.txt"
  puts "Part 1: testing..."
  expected = [10]
  (0...expected.size).each do |n|
    actual = part1(test_data_file)
    if actual == expected[n]
      puts "test #{n} passed"
    else
      puts "test #{n} failed! got #{actual} and expected #{expected[n]}"
    end
  end
  puts "Part 2: testing..."
  expected = [4]
  (0...expected.size).each do |n|
    actual = part2(test_data_file)
    if actual == expected[n]
      puts "test #{n} passed"
    else
      puts "test #{n} failed! got #{actual} and expected #{expected[n]}"
    end
  end
end

run_tests

production_data_file = 'data/day05_production_polymer.txt'
puts "Part 1: How many units remain after fully reacting the polymer you scanned?"
puts "Answer: #{part1(production_data_file)}"

puts "Part 2: What is the length of the shortest polymer you can produce by removing all units of exactly one type and fully reacting the result?"
puts "Answer: #{part2(production_data_file)}"

