require_relative 'toolbox'

require 'set'

# plan:
#  [X] process test data
#  [X] strongest
#  [X] in range

class Bot
  attr_reader :coordinate, :signal_radius

  def initialize(coordinate, signal_radius)
    @coordinate = coordinate
    @signal_radius = signal_radius
  end

  def in_range_of?(other_bot)
    contains?(other_bot.coordinate)
  end

  def intersect_with?(other_bot)
    _taxi_distance(self.coordinate, other_bot.coordinate) <= (self.signal_radius + other_bot.signal_radius)
  end

  def contains?(coordinate)
    _taxi_distance(self.coordinate, coordinate) <= self.signal_radius
  end

  def eql?(o)
    self.hash == o.hash
  end

  def hash
    [@coordinate, @signal_radius].hash
  end

  private

  def _taxi_distance(c1, c2)
    x1, y1, z1 = *c1
    x2, y2, z2 = *c2
  
    (x2 - x1).abs + (y2 - y1).abs + (z2 - z1).abs
  end
end

class Swarm
  attr_reader :max_bot
  def initialize(file)
    @bots = []
    raw_lines(file).each do |l|
      # quick and dirty
      l = l.split('<').last
      coords, radius = *l.split('>')
      coords = *coords.split(',').map(&:to_i)
      signal_radius = radius.split('=').last.to_i
      @bots << Bot.new(coords, signal_radius)
    end

    @max_bot = @bots.sort_by {|b| b.signal_radius }.reverse.first
  end

  def nano_bots_in_range_of_max
    @bots.select {|b| max_bot.in_range_of?(b) }
  end

  # not my approach. used description in solutions thread.
  def shortest_distance
    m = {}

    @bots.each do |bot|
      d = _taxi_distance([0,0,0], bot.coordinate)
      m[[0, d - bot.signal_radius].max] = 1
      m[d + bot.signal_radius] = -1
    end

    count = 0
    result = 0
    max_count = 0

    m.sort.each do |dist, amt|
      count += amt
      if (max_count < count)
        result = dist
        max_count = count
      end
    end
    result
  end

  private

  def _taxi_distance(c1, c2)
    x1, y1, z1 = *c1
    x2, y2, z2 = *c2
  
    (x2 - x1).abs + (y2 - y1).abs + (z2 - z1).abs
  end

end

def run_tests
  puts "testing:"
  f = 'data/day23_test_sweep_01.txt'
  s = Swarm.new(f)
  test(4, s.max_bot.signal_radius)
  test(7, s.nano_bots_in_range_of_max.size)
  puts
end

run_tests

def part1
  f = 'data/day23_production_sweep.txt'
  s = Swarm.new(f)
  s.nano_bots_in_range_of_max.size
end

def part2
  f = 'data/day23_production_sweep.txt'
  s = Swarm.new(f)
  s.shortest_distance
end

puts "Part 1: Find the nanobot with the largest signal radius. How many nanobots are in range of its signals?"
puts "Answer: #{part1}"

puts "Part 2: Find the coordinates that are in range of the largest number of nanobots. What is the shortest manhattan distance between any of those points and 0,0,0?"
puts "Answer: #{part2}"










