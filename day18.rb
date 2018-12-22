require 'set'
require_relative 'toolbox'

# plan:
#  [X] file loader / parser
#  [X] test files saved
#  [X] lot class w/ tick
#  [X] equality
#  [X] test harness for comparing ticks

class Lot
  def self.from_file(f)
    self.new(raw_lines(f))
  end

  def initialize(lines)
    @grid = _build_grid(lines)
  end

  def tick
    dup_grid = Array.new(@grid.first.size) { Array.new(@grid.size, :open) }
    @grid.each_with_index do |col, x|
      col.each_with_index do |square, y|
        neighbors = _neighbors([x, y])
        dup_grid[x][y] = square
        case square
        when :open
          dup_grid[x][y] = :trees if 3 <= neighbors.count(:trees)
        when :trees
          dup_grid[x][y] = :lumberyard if 3 <= neighbors.count(:lumberyard)
        when :lumberyard
          dup_grid[x][y] = (1 <= neighbors.count(:trees) && 1 <= neighbors.count(:lumberyard)) ? :lumberyard : :open
        else
          LOGGER.fatal { "unknown square in tick: #{square}" }
          exit
        end
      end
    end
    @grid = dup_grid
  end
  
  def after(n = 1)
    seen = Set.new
    seen.add(self)
    iter = 0
    hashes = []
    objects = []
    loop do
      break if n == 0
      self.tick

      if !seen.add?(self)
        # start recording scores

        if hashes.include?(self.hash)
          # until we have repeated. then we stop
          n -= 1
          break
        end
        hashes[iter] = self.hash
        objects[iter] = self.dup
        iter += 1
      end
      n -= 1
    end

    return self if hashes.empty?
    remainder = n % hashes.size
    objects[remainder]
  end

  def smart_timer(n = 1)
  end

  def resource_value
    wooded_acres * lumberyards
  end

  def wooded_acres
    @grid.map {|col| col.count(:trees) }.reduce(:+)
  end

  def lumberyards
    @grid.map {|col| col.count(:lumberyard) }.reduce(:+)
  end

  def render
    (0...@grid.first.size).each do |i|
      puts @grid.map {|n| _display(n[i]) }.flatten.join(' ')
    end
  end

  def ==(o)
    o.class == self.class && o.state == state
  end

  alias_method :eql?, :==

  def hash
    state.hash
  end

  protected

  def state
    [@grid]
  end

  private

  def _neighbors(coordinate)
    x, y = *coordinate
    potential_neighbors = [
      [x - 1, y - 1], # north west
      [x    , y - 1], # north
      [x + 1, y - 1], # north east
      [x + 1,     y], # east
      [x + 1, y + 1], # south east
      [x    , y + 1], # south
      [x - 1, y + 1], # south west
      [x - 1,     y], # west
    ]

    neighbors = potential_neighbors.select do |neighbor|
      n_x, n_y = *neighbor
      0 <= n_x && n_x < @grid.size && 0 <= n_y && n_y < @grid.first.size
    end

    neighbors.map {|n| n_x, n_y = *n; @grid[n_x][n_y] }
  end

  def _build_grid(lines)
    width = lines.first.chars.size
    height = lines.size

    grid = Array.new(width) { Array.new(height, :open) }
    lines.each_with_index do |line, y|
      line.chars.each_with_index do |c, x|
        case c
        when '.'
          grid[x][y] = :open
        when '|'
          grid[x][y] = :trees
        when '#'
          grid[x][y] = :lumberyard
        else
          LOGGER.fatal { "unknown acre type: #{c}" }
          exit
        end

      end
    end
    grid
  end

  def _display(x)
    return '.' if x == :open
    return '|' if x == :trees
    return '#' if x == :lumberyard
    LOGGER.fatal { "unknown acre type: #{x}" }
    exit
  end

end

def run_tests
  puts "testing:"
  back_lot = Lot.from_file('data/day18_test_lot_0.txt')
  (0..10).each do |i|
    f = "data/day18_test_lot_#{i}.txt"
    file_lot = Lot.from_file(f)
    test(file_lot.hash, back_lot.hash)
    test(file_lot, back_lot)
    back_lot.tick
  end

  test_lot = Lot.from_file('data/day18_test_lot_0.txt')
  test_lot.after(10)
  test(37, test_lot.wooded_acres)
  test(31, test_lot.lumberyards)
  test(1147, test_lot.resource_value)

  puts
end

def part1
  Lot.from_file('data/day18_production_lot.txt').after(10).resource_value
end

def part2
  Lot.from_file('data/day18_production_lot.txt').after(1000000000).resource_value
end

run_tests

puts "Part 1: What will the total resource value of the lumber collection area be after 10 minutes?"
puts "Answer: #{part1}"

puts "Part 2: What will the total resource value of the lumber collection area be after 1000000000 minutes?"
puts "Answer: #{part2}"


