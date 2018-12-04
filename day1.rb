

def raw_lines(f)
  IO.readlines(f, chomp: true)
end

def int_lines(f)
  raw_lines(f).map(&:to_i)
end

def resulting_frequency(arr)
  arr.reduce(&:+)
end

def search_for_duplicate(f)
  h = Hash.new(0)
  result = 0
  h[result] += 1
  found_duplicate = false
  while found_duplicate == false
    int_lines(f).each do |freq|
      result = result + freq
      h[result] += 1
      if h[result] == 2
        found_duplicate = true
        break
      end
    end
  end
  result
end

def run_tests
  puts "Part 1: testing..."
  expected = [3, 3, 0, -6]
  (0..3).each do |n|
    test_data_file = "data/day01_test_frequencies_part_1_#{n}.txt"
    actual = resulting_frequency(int_lines(test_data_file))
    if actual == expected[n]
      puts "test #{n} passed"
    else
      puts "test #{n} failed! got #{actual} and expected #{expected[n]}"
    end
  end

  puts "Part 2: testing..."
  expected = [2, 0, 10, 5, 14]
  (0..4).each do |n|
    test_data_file = "data/day01_test_frequencies_part_2_#{n}.txt"
    actual = search_for_duplicate(test_data_file)
    if actual == expected[n]
      puts "test #{n} passed"
    else
      puts "test #{n} failed! got #{actual} and expected #{expected[n]}"
    end
  end
end

production_data_file = 'data/day01_production_frequencies.txt'

puts "Part 1: Starting with a frequency of zero, what is the resulting frequency after all of the changes in frequency have been applied?"
puts "Answer: #{resulting_frequency(int_lines(production_data_file))}"

puts "Part 2: What is the first frequency your device reaches twice?"
puts "Answer: #{search_for_duplicate(production_data_file)}"







