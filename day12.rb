require_relative 'toolbox'

# plan:
#  [X] figure out how to manage rules
#  [X] test harness to read file
#  [X] cave garden class. takes initial state and rules
#  [X] idea: can just do array equality as check for growth?
#  [X] method for line at generation n
#  [X] method for sum plants at generation n

class Tunnel
  PLANT = 1
  EMPTY = nil

  attr_reader :pots, :offset
  def initialize(pots, initial_offset = 0)
    @pots, @offset = _normalize(pots, initial_offset)
  end

  def total_plants
    @pots.map(&:to_i).reduce(:+)
  end

  def sum
    @pots.each_index.select {|i| @pots[i] == PLANT }.map {|i| i + @offset }.reduce(:+).to_i
  end

  def self.from_string(state, initial_offset = 0)
    Tunnel.new(_parse(state), initial_offset)
  end

  private

  def self._parse(state)
    state.chars.map {|p| p == '#' ? PLANT : EMPTY }
  end
  
  # ensures:
  #  * caves are at least 5 pots long
  #  * strictly four empty pots before first plant
  #  * strictly four empty pots after last plant
  def _normalize(pots, initial_offset)
    offset = initial_offset
    first_plant_index = pots.index(PLANT)

    if first_plant_index.nil?
      # empty pots. nothing to do
      pots = Array.new(5, EMPTY)
      offset = 0
    else
      # we have at least one plant
      while pots.index(PLANT) < 4
        pots.unshift(EMPTY)
        offset -= 1
      end

      while 4 < pots.index(PLANT)
        pots.shift
        offset += 1
      end

      while pots.reverse.index(PLANT) < 4
        pots.push(EMPTY)
      end

      while 4 < pots.reverse.index(PLANT)
        pots.pop
      end
    end
    [pots, offset]
  end

end

class Rule
  attr_reader :match, :result
  def initialize(args)
    @match, @result = *args
  end

  def self.from(rule)
    Rule.new(_parse(rule))
  end

  private

  def self._parse(rule)
    raw_match, raw_result = rule.split(' => ')
    match = raw_match.chars.map {|c| c == '#' ? 1 : nil }
    result = raw_result == '#' ? 1 : nil

    [match, result]
  end

end

class CaveGarden
  def initialize(initial_state, rules)
    @initial_state = Tunnel.from_string(initial_state)
    @rules = rules
  end

  def total_plants_at(generation)
    tunnel_at(generation).total_plants
  end

  def sum(generation)
    tunnel_at(generation).sum
  end

  def tunnel_at(generation)
    return @initial_state if generation == 0
    prev_pots = []
    tunnel = @initial_state
    iter = 0
    loop do
      pots = []

      # grow the plants
      tunnel.pots.each_cons(5).each_with_index do |shelf, index|
        real_index = index + 2
        @rules.each do |rule|
          if shelf == rule.match
            pots[real_index] = rule.result
          end
        end
      end

      prev_offset = tunnel.offset
      tunnel = Tunnel.new(pots, tunnel.offset)

      # have we converged?
      if prev_pots == tunnel.pots
        offset = (generation - iter) + prev_offset
        tunnel = Tunnel.new(tunnel.pots, offset)
        break
      end

      prev_pots = tunnel.pots
      iter += 1
      break if iter == generation
    end
    tunnel
  end
end

def load_cave_garden(f)
  raw_lines = raw_lines(f)
  initial_state = raw_lines.shift.split(' ').last
  raw_lines.shift
  rules = raw_lines.map {|l| Rule.from(l) }
  CaveGarden.new(initial_state, rules)
end

def run_tests
  puts "testing:"

  t = Tunnel.from_string('..#..')
  test([nil, nil, nil, nil, 1, nil, nil, nil, nil], t.pots)
  test(-2, t.offset)
  test(1, t.total_plants)
  test(2, t.sum)

  t = Tunnel.from_string('#..')
  test([nil, nil, nil, nil, 1, nil, nil, nil, nil], t.pots)
  test(-4, t.offset)
  test(1, t.total_plants)
  test(0, t.sum)

  t = Tunnel.from_string('.')
  test([nil, nil, nil, nil, nil], t.pots)
  test(0, t.offset)
  test(0, t.total_plants)
  test(0, t.sum)

  t = Tunnel.from_string('#....##....#####...#######....#.#..##', -2)
  test(325, t.sum)

  cg = load_cave_garden('data/day12_test_cave_garden.txt')
  test(11, cg.total_plants_at(0))
  test(7, cg.total_plants_at(1))
  test(325, cg.sum(20))

  puts "\ntesting complete!"
end

def part1(cave_garden)
  cave_garden.sum(20)
end

def part2(cave_garden)
  cave_garden.sum(50000000000)
end

run_tests

cg = load_cave_garden('data/day12_production_cave_garden.txt')
puts "Part 1: After 20 generations, what is the sum of the numbers of all pots which contain a plant?"
puts "Answer: #{part1(cg)}"

puts "Part 2: After fifty billion (50000000000) generations, what is the sum of the numbers of all pots which contain a plant?"
puts "Answer: #{part2(cg)}"


















