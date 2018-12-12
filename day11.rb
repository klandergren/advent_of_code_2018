require_relative 'toolbox'


# plan:
#   [X] method for calculating each component of power
#   [X] method for calculating power
#   [X] grid class (300 x 300). will part 2 increase size?
#   [X] ability to extract shifted ranges for testing
#   [X] method for largest total power. think on what largest total power means?

class FuelCell
  attr_reader :rack_id, :initial_power_level
  def initialize(coordinate)
    x, y = *coordinate
    @rack_id = x + 10
    @initial_power_level = @rack_id * y
  end
end

class PowerMeter
  def self.power_level(fuel_cell, grid_serial_number)
    p = fuel_cell.initial_power_level
    p += grid_serial_number
    p *= fuel_cell.rack_id
    hundreds_place = p.to_s.chars.reverse[2].to_i
    p = hundreds_place - 5
    p
  end
end

class Grid
  SIZE = 300
  GRID_MAX = SIZE + 1

  def initialize(serial_number)
    @serial_number = serial_number
    _fill_grid
    @power_memo = Array.new(GRID_MAX) { Array.new(GRID_MAX) { Array.new(GRID_MAX) } }
  end

  def max_power_at(x, y, size)
    return 0 if x == 0 || y == 0
    return 0 if size == 0
    return @grid[x][y] if size == 1
    return @power_memo[x][y][size] unless @power_memo[x][y][size].nil?

    power = max_power_at(x, y, size - 1)

    max_x = (x - 1) + (size - 1)
    (x..max_x).each do |xn|
      y_max = y + (size - 1)
      power += max_power_at(xn, y_max, 1)
    end

    max_y = (y - 1) + size
    (y..max_y).each do |yn|
      x_max = x + (size - 1)
      power += max_power_at(x_max, yn, 1)
    end
    @power_memo[x][y][size] = power
    power
  end

  def max_power(grid_size_limit = 300)
    max_coordinate = [0,0]
    max_power = 0
    max_size = 0
    (1..grid_size_limit).each do |size|
      max_x = GRID_MAX - size
      max_y = GRID_MAX - size

      (1..max_x).each do |x|
        (1..max_y).each do |y|
          coordinate = [x,y]
          power = max_power_at(x, y, size)
          max_power, max_coordinate, max_size = power, coordinate, size if max_power < power
        end
      end
    end

    [max_power, max_coordinate, max_size]
  end

  # for testing
  def shifted_extract_region(coordinate, length)
    grid = _extract_region(coordinate, length)
    shifted_grid = [[]]
    (0...grid.size).each do |i|
      shifted_grid[i] = grid.map {|n| n[i] }.flatten
    end
    shifted_grid
  end

  private

  def _fill_grid
    x_max = SIZE + 1
    y_max = x_max

    @grid = Array.new(x_max) { Array.new(y_max) }
    (1...x_max).each do |x|
      (1...y_max).each do |y|
        @grid[x][y] = PowerMeter.power_level(FuelCell.new([x,y]), @serial_number) 
      end
    end
  end

  def _extract_region(coordinate, size)
    x_min, y_min = *coordinate

    @grid.slice(x_min, size).map {|col| col.slice(y_min, size) }
  end

end
       
def run_tests
  puts "testing:"
  power_truth = [
    [    [3, 5],  8,  4],
    [ [122, 79], 57, -5],
    [[217, 196], 39,  0],
    [[101, 153], 71,  4],
  ]

  power_truth.each do |data|
    coordinate, grid_serial_number, power_level = *data
    test(power_level, PowerMeter.power_level(FuelCell.new(coordinate), grid_serial_number))
  end

  region_truth = [
    [
      18,
      [33, 45],
      29,
      "33,45",
      [90,269],
      16,
      113,
      "90,269,16",
      "-2  -4   4   4   4",
      "-4   4   4   4  -5",
      "4   3   3   4  -4",
      "1   1   2   4  -3",
      "-1   0   2  -5  -2",
    ], [
      42,
      [21, 61],
      30,
      "21,61",
      [232,251],
      12,
      119,
      "232,251,12",
      "-3   4   2   2   2",
      "-4   4   3   3   4",
      "-5   3   3   4  -4",
      " 4   3   3   4  -3",
      " 3   3   3  -5  -1",
    ]

  ]
  region_truth.each do |data|
    grid_serial_number, coordinate_3_by_3, total_power_3_by_3, part1_answer, unbounded_coordinate, unbounded_size, unbounded_total_power, part2_answer, *rows = data

    g = Grid.new(grid_serial_number)
    five_by_five_coordinate = [coordinate_3_by_3[0] - 1, coordinate_3_by_3[1] - 1]
    region = g.shifted_extract_region(five_by_five_coordinate, rows.size)

    rows.each_with_index do |row, i|
      normalized_row = row.split(' ').map(&:to_i)
      test(normalized_row, region[i])
    end

    max_power_3_by_3, max_coordinate_3_by_3, max_size = g.max_power(3)
    test(total_power_3_by_3, max_power_3_by_3)
    test(coordinate_3_by_3, max_coordinate_3_by_3)
    test(part1_answer, part1(g))
    test(part2_answer, part2(g))
  end

  puts
end

def part1(grid)
  max_power, max_coordinate, max_size = grid.max_power(3)
  max_coordinate.join(',')
end

def part2(grid)
  max_power, max_coordinate, max_size = grid.max_power
  (max_coordinate + [max_size]).flatten.join(',')
end

run_tests

grid = Grid.new(8561)
puts "Part 1: What is the X,Y coordinate of the top-left fuel cell of the 3x3 square with the largest total power?"
puts "Answer: #{part1(grid)}"

puts "What is the X,Y,size identifier of the square with the largest total power?"
puts "Answer: #{part2(grid)}"
