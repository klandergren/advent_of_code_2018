require_relative 'toolbox'

# how to detect collisions? m x n matrix of 0s. process each and increment. count number of cells greater than two
class Matrix

  def self.from_file(f)
    m = Matrix.new

    raw_lines(f).each do |l|
      entry = DataLine.new(l)
      m.fill(entry.x, entry.y, entry.w, entry.l)
    end
    m
  end

  def initialize
    @grid = [[]]
  end

  def set(x,y,v)
    @grid[x] = [] if @grid[x].nil?
    @grid[x][y] = v
  end

  def get(x,y)
    return 0 if @grid[x].nil?
    return 0 if @grid[x][y].nil?
    @grid[x][y]
  end

  def increment(x,y)
    v = self.get(x,y)
    v += 1
    self.set(x,y,v)
  end

  def fill(x,y,w,l)
    x2 = x + w
    y2 = y + l

    (x...x2).each do |x|
      (y...y2).each do |y|
        self.increment(x,y)
      end
    end
  end

  def has_overlap?(x,y,w,l)
    x2 = x + w
    y2 = y + l

    has_overlap = false

    (x...x2).each do |x_prime|
      (y...y2).each do |y_prime|
        has_overlap = true if 1 < self.get(x_prime, y_prime)
      end
    end

    has_overlap
  end

  def more_than_two_claims
    count = 0
    @grid.each do |x|
      x.each do |y|
        count += 1 if 2 <= y.to_i
      end
    end
    count
  end
  
end

class DataLine
  @line
  def initialize(l)
    @line = l
  end

  def x
    @line.split(' ')[2].split(',').first.to_i
  end

  def y
    @line.split(' ')[2].split(',').last.split(':').first.to_i
  end

  def w
    @line.split(' ')[3].split('x').first.to_i
  end

  def l
    @line.split(' ')[3].split('x').last.to_i
  end

  def claim_id
    @line.split(' ')[0].split('#').last.to_i
  end
end

class Checker
  def self.non_overlapping_claim_ids(m, file)
    no_overlap_claim_ids = []

    raw_lines(file).each do |l|
      entry = DataLine.new(l)
      no_overlap_claim_ids << entry.claim_id unless m.has_overlap?(entry.x, entry.y, entry.w, entry.l)
    end

    no_overlap_claim_ids
  end
end

def run_tests
  test_data_file = 'data/day03_test_claims.txt'
  m = Matrix.from_file(test_data_file)
  puts "Part 1: testing..."
  expected = [4]
  (0...expected.size).each do |n|
    actual = m.more_than_two_claims
    if actual == expected[n]
      puts "test #{n} passed"
    else
      puts "test #{n} failed! got #{actual} and expected #{expected[n]}"
    end
  end
  puts "Part 2: testing..."
  expected = [3]
  (0...expected.size).each do |n|
    actual = Checker.non_overlapping_claim_ids(m, test_data_file).first
    if actual == expected[n]
      puts "test #{n} passed"
    else
      puts "test #{n} failed! got #{actual} and expected #{expected[n]}"
    end
  end

end

run_tests

production_data_file = 'data/day03_production_claims.txt'

m = Matrix.from_file(production_data_file)

puts "Part 1: How many square inches of fabric are within two or more claims?"
puts "Answer: #{m.more_than_two_claims}"

puts "Part 2: What is the ID of the only claim that doesn't overlap?"
puts "Answer: #{Checker.non_overlapping_claim_ids(m, production_data_file).first}"



