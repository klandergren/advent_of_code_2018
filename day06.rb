require_relative 'toolbox'

class Grid
  def initialize(coordinates)
    @coordinates = coordinates
    _create_grid
    _fill_grid
  end

  def max_x
    @grid.size - 1
  end

  def max_y
    @grid.first.size - 1
  end

  # returns array of letters that are infinite
  def infinite_areas
    infs = []
    (0..max_x).each do |x|
      infs << @grid[x][0]
      infs << @grid[x][max_y]
    end

    (0..max_y).each do |y|
      infs << @grid[0][y]
      infs << @grid[max_x][y]
    end

    infs.uniq.reject {|x| x == "." }.sort
  end

  def area_sizes
    infs = infinite_areas
    sizes = Hash.new(0)
    (0..max_x).each do |x|
      (0..max_y).each do |y|
        letter = @grid[x][y]
        next if letter == "."
        next if infs.any? {|x| x == letter }
        sizes[letter] += 1
      end
    end
    sizes
  end

  def maximum_area
    area_sizes.values.max
  end

  def safe_zone_size(minimum_distance)
    safe_area = 0
    (0..max_x).each do |x|
      (0..max_y).each do |y|
        c1 = [x, y]
        sum_distances = @coordinates.map {|c2| taxi_distance(c1, c2) }.reduce(:+)

        next unless sum_distances < minimum_distance
        safe_area += 1
      end
    end
    safe_area
  end

  private

  def _create_grid
    max_x = @coordinates.flat_map {|c| c.first }.max
    max_y = @coordinates.flat_map {|c| c.last }.max
    @grid = Array.new(max_x + 1) { Array.new(max_y + 1, 0) }
  end

  def _fill_grid
    (0..max_x).each do |x|
      (0..max_y).each do |y|
        c1 = [x, y]
        distances = Hash.new { |h, k| h[k] = Array.new }
        @coordinates.each_with_index do |c2, i|
          distances[taxi_distance(c1, c2)] << _lookup(i)
        end

        # possible states: 1. is a coordinate. 2. one coord is minimum. 3. two coords minim
        min = distances.keys.min
        dup = distances[min].size != 1
        letter = dup ? "." : distances[min].first

        @grid[x][y] = letter
      end
    end
  end

  def _lookup(i)
    (("a".."z").to_a + ("A".."Z").to_a)[i]
  end

end

def taxi_distance(c1, c2)
  x1 = c1.first
  y1 = c1.last

  x2 = c2.first
  y2 = c2.last

  (x2 - x1).abs + (y2 - y1).abs
end

def create_coordinates(f)
  raw_lines(f).map {|x| x.split(', ').map(&:to_i) }
end

def run_tests
  test_data_file = "data/day06_test_coordinates.txt"
  puts "Part 1: testing..."
  g = Grid.new(create_coordinates(test_data_file))

  test(8, g.max_x)
  test(9, g.max_y)

  test_values = [
    [1, [0,0], [0,1]],
    [1, [0,0], [1,0]],
    [1, [0,1], [0,0]],
    [1, [1,0], [0,0]],
    [5, [1,1], [1,6]],
    [9, [1,1], [8,3]],
    [5, [1,1], [3,4]],
    [6, [4,3], [1,6]],
    [4, [4,3], [8,3]],
    [2, [4,3], [3,4]],
    [3, [4,3], [5,5]],
    [10, [4,3], [8,9]],
  ]
  test_values.each do |actual, arg1, arg2|
    test(actual, taxi_distance(arg1, arg2))
  end

  test("abcf", g.infinite_areas.join)
  test(17, g.maximum_area)
  test(16, g.safe_zone_size(32))
end

run_tests

production_data_file = 'data/day06_production_coordinates.txt'
g = Grid.new(create_coordinates(production_data_file))

puts "Part 1: What is the size of the largest area that isn't infinite?"
puts "Answer: #{g.maximum_area}"

puts "Part 2: What is the size of the region containing all locations which have a total distance to all given coordinates of less than 10000?"
puts "Answer: #{g.safe_zone_size(10000)}"
