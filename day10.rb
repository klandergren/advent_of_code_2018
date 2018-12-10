require_relative 'toolbox'

class Point
  def initialize(position, velocity)
    @initial_position = position
    @velocity = velocity
  end

  def position_at(t)
    position = @initial_position.dup
    position[0] += @velocity[0] * t
    position[1] += @velocity[1] * t
    position
  end
end

# assumptions:
#  * grid will be its largest size at start
#  * grid will be at its smallest at message presentation (potentially wrong)
#
# plan
#  [X] verify parsing / math
#  [X] add grid access for testing
#  [X] create star map with print function
#  [X] method to return positions at time t
#  [X] method to check whether arr of positions has likely message
#  [X] method to return "shrunken grid" based on arr of positions

class StarMap

  # takes an array of Points
  def initialize(points)
    @points = points
    min_x = @points.map {|p| p.position_at(0)[0] }.min
    max_x = @points.map {|p| p.position_at(0)[0] }.max
    min_y = @points.map {|p| p.position_at(0)[1] }.min
    max_y = @points.map {|p| p.position_at(0)[1] }.max

    @width = 1 + max_x - min_x
    @height = 1 + max_y - min_y

    @normalization_x = 0 - min_x
    @normalization_y = 0 - min_y
  end

  def grid_at(t)
    grid = Array.new(@width) { Array.new(@height, ".") }

    @points.each do |point|
      p = point.position_at(t)
      # normalize
      x = p[0] + @normalization_x
      y = p[1] + @normalization_y
      grid[x][y] = "#"
    end

    grid
  end

  # this is a shifted array of arrays so that I can test line by line
  def shifted_grid_at(t)
    grid = grid_at(t)
    shifted_grid = [[]]

    (0...@height).each do |i|
      shifted_grid[i] = grid.map {|n| n[i] }.flatten
    end
    shifted_grid
  end

  def positions_at(t)
    @points.map{|p| p.position_at(t) }
  end

  def shrunken_area(positions)
    min_x = positions.map {|p| p[0] }.min
    max_x = positions.map {|p| p[0] }.max
    min_y = positions.map {|p| p[1] }.min
    max_y = positions.map {|p| p[1] }.max

    width = 1 + max_x - min_x
    height = 1 + max_y - min_y
    width * height
  end

  def shrunken_grid(positions)
    min_x = positions.map {|p| p[0] }.min
    max_x = positions.map {|p| p[0] }.max
    min_y = positions.map {|p| p[1] }.min
    max_y = positions.map {|p| p[1] }.max

    width = 1 + max_x - min_x
    height = 1 + max_y - min_y

    normalization_x = 0 - min_x
    normalization_y = 0 - min_y
    
    grid = Array.new(width) { Array.new(height, " ") }

    positions.each do |p|
      # normalize
      x = p[0] + normalization_x
      y = p[1] + normalization_y
      grid[x][y] = "#"
    end

    shifted_grid = [[]]

    (0...height).each do |i|
      shifted_grid[i] = grid.map {|n| n[i] }.flatten
    end
    shifted_grid
  end

  def likely_message
    max = 10_000_000
    minimum_area = 100_000_000_000_000
    i = 0
    loop do
      positions = positions_at(i)
      area = shrunken_area(positions)

      if area < minimum_area
        minimum_area = area
      else
        # area started to increase. last iter was minimum area
        positions = positions_at(i - 1)
        grid = shrunken_grid(positions)
        grid.each do |row|
          puts row.join
        end
        return i - 1
      end

      i += 1
      break if i == max
    end
  end

end

def parse(line)
  vector = line.scan(/\<(.*?)\>/).map {|n| n.first.split(',').map(&:to_i) }
  Point.new(vector[0], vector[1])
end

def load_points(f)
  raw_lines(f).map {|l| parse(l) }
end

def run_tests
  f = 'data/day10_test_points.txt'
  l = raw_lines(f).first
  p0 = parse(l)
  test([9,1], p0.position_at(0))

  p1 = Point.new([3,9],[1,-2])
  [[3,9], [4,7], [5,5], [6,3]].each_with_index do |pos, i|
    test(pos, p1.position_at(i))
  end

  sm = StarMap.new(load_points(f))
  (0..4).each do |t|
    grid = sm.shifted_grid_at(t)
    test_file = "data/day10_test_map_#{t}.txt"
    raw_lines(test_file).each_with_index do |line, i|
      test(line.strip, grid[i].join)
    end
  end

  puts "\nextracted test message:"
  sm.likely_message

  puts
end

def part1
  sm = StarMap.new(load_points('data/day10_production_points.txt'))
  sm.likely_message
end

run_tests

puts "Part 1: What message will eventually appear in the sky?"
puts "Answer:"
seconds = part1

puts "Part 2: ...exactly how many seconds would they have needed to wait for that message to appear?"
puts "Answer: #{seconds}"











