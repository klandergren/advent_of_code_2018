require_relative 'toolbox'

# plan:
#  [X] keep list of traveled nodes
#  [X] loop through list of nodes
#  [X] check if have valid moves
#  [X] if valid moves found, choose the south most one and do it
#  [X] no moves? game over
#  [X] after move made, fill troughs
#  [X] columns filled are removed from the list of nodes

class Grid
  def initialize(coordinates)
    x_min = coordinates.map(&:first).min
    x_max = coordinates.map(&:first).max

    @y_min = coordinates.map(&:last).min
    @y_max = coordinates.map(&:last).max

    # +1 for the array, then +2 for 1 square overflow on either side
    width = (x_max - x_min) + 1 + 2 
    height = @y_max + 1

    offset = x_min - 1

    LOGGER.debug { "x_min: #{x_min}, x_max: #{x_max}, y_max: #{@y_max}, width: #{width}" }

    @grid = Array.new(width) { Array.new(height, :sand) }
    
    coordinates.each do |x, y|
      x_trans = x - offset
      
      @grid[x_trans][y] = :clay
    end

    @spring_x, @spring_y = 500 - offset, 0
    @grid[@spring_x][@spring_y] = :spring
    @grid_backup = @grid.dup
  end

  def spring
    [@spring_x, @spring_y]
  end

  def render
    (0...@grid.first.size).each do |i|
      puts @grid.map {|n| _display(n[i]) }.flatten.join(' ')
    end
  end

  def at(coordinate)
    x, y = *coordinate
    return nil unless 0 <= x && x < @grid.size
    return nil unless 0 <= y && y < @grid.first.size
    @grid[x][y]
  end

  def set(coordinate, type)
    x, y = *coordinate
    @grid[x][y] = type
  end

  def water_count
    count = 0
    @grid.each_with_index do |col, x|
      col.each_with_index do |square, y|
        next if y < @y_min
        next if @y_max < y
        count += 1 if square == :water || square == :column
      end
    end
    count
  end

  def remaining_water_count
    count = 0
    @grid.each_with_index do |col, x|
      col.each_with_index do |square, y|
        next if y < @y_min
        next if @y_max < y
        count += 1 if square == :water
      end
    end
    count
  end

  def insights
    total_squares = @grid.size * @grid.first.size
    total_water = @grid.map {|col| col.select {|s| s ==:water }.size }.reduce(:+)
    total_columns = @grid.map {|col| col.select {|s| s ==:column }.size }.reduce(:+)
    explored_squares = total_water + total_columns
    puts "explored: #{((explored_squares.to_f / total_squares)*100).round(0)}% water: #{total_water} columns: #{total_columns}"
  end

  def save_run
    File.open('data/day17_last_run.txt', 'w') do |file|
      (0...@grid.first.size).each do |i|
        file.puts(@grid.map {|n| _display(n[i]) }.flatten.join(' '))
      end
    end
  end

  private

  def _display(x)
    case x
    when :sand
      return '.'
    when :clay
      return '#'
    when :column
      return '|'
    when :water
      return '~'
    when :spring
      return '+'
    when nil
      return 'E'
    else
      LOGGER.fatal { "encountered unknown x: #{x}" }
      exit
    end
  end
end

class Water
  def initialize(grid, current_coordinate = nil)
    @grid = grid
    @nodes = []
    @nodes << @grid.spring
  end

  def flow(n = -1)
    filled_troughs_previously = false
    iter = 0
    water_tiles = 0
    loop do
      break if iter == n
      @grid.insights if iter != 0 && iter % 1_000 == 0

      LOGGER.debug { "iter: #{iter}" }

      flowable_nodes = @nodes.select {|n| _has_move?(n) }

      LOGGER.debug { "flow nodes: #{flowable_nodes}" }

      if flowable_nodes.empty?
        # try to fill troughs
        waters = _fill_troughs
        
        # no flow, and no filling, we are done
        break if waters.empty?

        # water is static. remove it from candidate nodes
        waters.each do |c|
          @nodes.delete(c)
        end
        next
      end

      flowable_nodes.each do |flow_node|
        valid_directions = _valid_directions(flow_node)
        loop do
          break if valid_directions.empty?
          flow_direction = valid_directions.shift
          node = _move(flow_node, flow_direction)
          @nodes << node
        end
      end

      iter += 1
    end
    @grid.insights
  end

  private

  def _move(coordinate, direction)
    n = _coordinate_for(direction, coordinate)
    @grid.set(n, :column)
    n
  end

  def _has_move?(from_coordinate)
    !_valid_directions(from_coordinate).empty?
  end

  def _valid_directions(from_coordinate)
    [:south, :west, :east].select {|d| _can_move?(from_coordinate, d) }
  end

  def _can_move?(from_coordinate, direction)
    south = _square_in_direction(:south, from_coordinate)

    case direction
    when :south
      return south == :sand
    when :west
      west = _square_in_direction(:west, from_coordinate)
      return (west == :sand) && (!south.nil? && (south == :clay || south == :water))
    when :east
      east = _square_in_direction(:east, from_coordinate)
      return (east == :sand) && (!south.nil? && (south == :clay || south == :water))
    else
      return false
    end
  end

  def _square_in_direction(direction, from_coordinate)
    @grid.at(_coordinate_for(direction, from_coordinate))
  end

  def _fill_troughs
    waters = []
    candidates = @nodes.dup
    loop do
      LOGGER.debug { "candidates: #{candidates.inspect}" }
      break if candidates.empty?
      coordinate = candidates.shift
      LOGGER.debug { "checking coordinate: #{coordinate.inspect}" }

      x, y = *coordinate

      potential_trough = true
      w_x = x - 1
      w_y = y
      loop do
        western_object = @grid.at([w_x, w_y])
        case western_object
        when :column
          w_x = w_x - 1
          next
        when nil
          potential_trough = false
          break
        when :sand
          potential_trough = false
          break
        when :water
          LOGGER.fatal { "encountered unexpected water at #{coordinate}" }
          @grid.render
          exit
        when :clay
          break
        else
          LOGGER.fatal { "encountered unknown square heading west at #{w_x}, #{w_y}: #{western_object}" }
          @grid.render
          exit
        end
      end

      next unless potential_trough
      LOGGER.debug { "found sufficient western expansion" }

      # now go east
      e_x = x + 1
      e_y = y
      loop do
        eastern_object = @grid.at([e_x, e_y])
        case eastern_object
        when :column
          e_x = e_x + 1
          next
        when nil
          potential_trough = false
          break
        when :sand
          potential_trough = false
          break
        when :water
          LOGGER.fatal { "encountered unexpected water at #{coordinate}" }
          @grid.render
          exit
        when :clay
          break
        else
          LOGGER.fatal { "encountered unknown square heading east at #{e_x}, #{e_y}: #{eastern_object}" }
          @grid.render
          exit
        end
      end

      next unless potential_trough
      LOGGER.debug { "found sufficient eastern expansion" }

      # now check that its held up by clay or water and account for the walls
      trough_start = w_x + 1
      trough_end = e_x - 1
      LOGGER.debug { "checking from #{trough_start}..#{trough_end}" }
      (trough_start..trough_end).each do |c_x|
        c_y = y + 1
        bottom_coordinate = [c_x, c_y]
        bottom = @grid.at(bottom_coordinate)
        LOGGER.debug { "bottom_coordinate: #{bottom} at #{bottom_coordinate}" }
        unless (bottom == :clay || bottom == :water)
          potential_trough = false
          break
        end
      end

      # fill!
      if potential_trough
        LOGGER.debug { "ground support for trough found" }
        (trough_start..trough_end).each do |c_x|
          @grid.set([c_x, y], :water)
          candidates.delete([c_x, y])
          waters << [c_x, y]
        end
      else
        LOGGER.debug { "no ground support for trough" }
      end
    end
    waters
  end

  def _coordinate_for(direction, starting_coordinate)
    x, y = *starting_coordinate
    return [    x, y + 1] if direction == :south
    return [x - 1,     y] if direction == :west
    return [x + 1,     y] if direction == :east
    return [x    , y - 1] if direction == :north

    LOGGER.fatal { "tried to move in bad direction: #{direction}" }
    exit
  end

end

def input_data(f)
  input_data = []
  raw_lines(f).each do |line|
    # extract numbers
    axis, start, finish = *line.scan(/\d+/).map(&:to_i)

    (start..finish).each do |v|
      input_data << (line.chars.index('x') == 0 ? [axis, v] : [v, axis])
    end
  end
  input_data
end

def run_tests
  puts "testing"
  data = input_data('data/day17_test_scan.txt')
  grid = Grid.new(data)

  water = Water.new(grid)
  water.flow
  test(57, grid.water_count)

  data = [
    [495, 1],
    [495, 2],
    [495, 3],
    [495, 4],
    [495, 5],
    [495, 6],

    [499, 2],
    [499, 3],

    [500, 4],

    [501, 2],
    [501, 3],


    [505, 1],
    [505, 2],
    [505, 3],
    [505, 4],
    [505, 5],
    [505, 6],
  ]
  grid = Grid.new(data)

  water = Water.new(grid)
  water.flow
  test(17, grid.water_count)
  puts
end

def setup_grid
  puts "setting up grid:"
  data = input_data('data/day17_production_scan.txt')
  grid = Grid.new(data)

  water = Water.new(grid)
  water.flow
  grid
end

def part1(grid)
  grid.water_count
end

def part2(grid)
  grid.remaining_water_count
end

run_tests

grid = setup_grid

puts "Part 1: How many tiles can the water reach within the range of y values in your scan?"
puts "Answer: #{part1(grid)}"

puts "Part 2: How many water tiles are left after the water spring stops producing water and all remaining water not at rest has drained?"
puts "Answer: #{part2(grid)}"




