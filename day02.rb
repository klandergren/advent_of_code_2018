require_relative 'toolbox'

# checks whether string boxID contains exactly int n repeated characters
def _contains_exactly_n_repeats?(boxID, n)
  letter_groups = boxID.chars.group_by {|v| v} # ex: "aa" becomes {"a"=>["a","a"]}
  letter_counts = letter_groups.flat_map {|k,v| [k, v.size]} # ex: {"a"=>["a","a"]} becomes ["a", 2]

  # not strictly necessary to create hash, but easier for me to think about
  lookup = Hash[*letter_counts]
  lookup.values.include? n
end

# tests whether strings a and b are off by exactly 1 character
def _off_by_one_character?(a,b)
  error = 0
  max = [a.chars.size, b.chars.size].max
  (0..max).each do |i|
    error += 1 unless a[i] == b[i]
  end
  error == 1
end

# takes lines and returns checksum
def checksum(file_name)
  num_two = 0
  num_three = 0
  raw_lines(file_name).each do |boxID|
    if _contains_exactly_n_repeats?(boxID, 2)
      num_two += 1
    end
    if _contains_exactly_n_repeats?(boxID, 3)
      num_three += 1
    end
  end
  num_two * num_three
end

def off_by_one(file_name)
  lines = raw_lines(file_name)

  common_letters = ""

  lines.each_with_index do |a, i|
    i += 1
    (i...lines.size).each do |j|
      b = lines[j]
      if _off_by_one_character?(a,b)
        debug "similar: \n #{a} \n #{b}"
        c = a.chars - (a.chars - b.chars)
        common_letters = c.join
        debug "final: #{common_letters}"
      end
    end
  end
  common_letters
end

def run_tests
  puts "Part 1: testing..."
  expected = [12]
  (0...expected.size).each do |n|
    test_data_file = "data/day02_test_box_ids_part_1_#{n}.txt"
    actual = checksum(test_data_file)
    if actual == expected[n]
      puts "test #{n} passed"
    else
      puts "test #{n} failed! got #{actual} and expected #{expected[n]}"
    end
  end
  puts "Part 2: testing..."
  expected = ["fgij"]
  (0...expected.size).each do |n|
    test_data_file = "data/day02_test_box_ids_part_2_#{n}.txt"
    actual = off_by_one(test_data_file)
    if actual == expected[n]
      puts "test #{n} passed"
    else
      puts "test #{n} failed! got #{actual} and expected #{expected[n]}"
    end
  end
end

run_tests

production_data_file = 'data/day02_production_box_ids.txt'

puts "Part 1: What is the checksum for your list of box IDs?"
puts "Answer: #{checksum(production_data_file)}"

puts "Part 2: What letters are common between the two correct box IDs?"
puts "Answer: #{off_by_one(production_data_file)}"

