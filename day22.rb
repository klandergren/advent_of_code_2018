require_relative 'toolbox'

require 'set'

# plan:
#  [X] cave representation (mouth, target, grid with types)
#  [X] rendering
#  [X] geologic index
#  [X] erosion level
#  [X] risk level
#  [X] modified a* for minutes_to_target

class Region
  attr_reader :geologic_index, :erosion_level, :type

  def initialize(geologic_index, erosion_level, is_mouth = false, is_target = false)
    @geologic_index = geologic_index
    @erosion_level = erosion_level
    @is_mouth = is_mouth
    @is_target = is_target

    if @erosion_level % 3 == 0
      @type = :rocky
    elsif @erosion_level % 3 == 1
      @type = :wet
    else
      @type = :narrow
    end
    
  end

  def risk_level
    return 0 if self.type == :rocky
    return 1 if self.type == :wet
    2
  end

  def permits?(equipment)
    case self.type
    when :rocky
      return equipment != :neither
    when :wet
      return equipment != :torch
    when :narrow
      return equipment != :climbing_gear
    end
  end

  def alternate_equipment(equipment)
    case self.type
    when :rocky
      return equipment == :torch ? :climbing_gear : :torch
    when :wet
      return equipment == :neither ? :climbing_gear : :neither
    when :narrow
      return equipment == :torch ? :neither : :torch
    end
  end

  def to_s
    return 'M' if @is_mouth
    return 'T' if @is_target

    case self.type
    when :rocky
      return '.'
    when :wet
      return '='
    when :narrow
      return '|'
    else
      LOGGER.fatal { "unknown type: #{self.type}" }
      exit
    end
  end

  private

  def _valid_equipment
    case self.type
    when :rocky
      return [:torch, :climbing_gear]
    when :wet
      return [:climbing_gear, :neither]
    when :narrow
      return [:torch, :neither]
    end
  end

end

class CaveSystem
  def initialize(depth, target_coordinate)
    @depth = depth
    @mouth = [0,0]
    @target_coordinate = target_coordinate
    
    _build_cave_to(@target_coordinate)
  end

  def risk_level
    x, y = *@target_coordinate

    risk_level = 0
    (0..x).each do |x|
      (0..y).each do |y|
        risk_level += @grid[x][y].risk_level
      end
    end
    
    risk_level
  end

  def minutes_to_target
    # calculate shortest path, using minutes
    goal = [@target_coordinate, :torch]
    
    closed_set = Set.new
    open_set = Set.new
    open_set.add([@mouth, :torch])
    came_from = {}
    g_score = Hash.new(100_000)
    g_score[[@mouth, :torch]] = 0
    
    f_score = Hash.new(100_000)
    f_score[[@mouth, :torch]] = _heuristic([@mouth, :torch], goal)
    
    iter = 0
    loop do
      break if open_set.empty?
      current = open_set.map {|o| [o, f_score[o]] }.sort_by {|o| o.last }.first.first
      break if current == goal
      
      LOGGER.debug { "iter: #{iter} for #{current.inspect}" } if iter != 0 && iter % 1000 == 0

      open_set.delete(current)
      closed_set.add(current)
      
      _valid_moves_of(current).reject{ |m| closed_set.include?(m) }.each do |movement|
        tentative_g_score = g_score[current] + _time_cost_traversing(current, movement)
        
        if !open_set.include?(movement)
          open_set.add(movement)
        elsif g_score[movement] <= tentative_g_score
          next
        end
        
        came_from[movement] = current
        g_score[movement] = tentative_g_score
        f_score[movement] = g_score[movement] + _heuristic(movement, goal)
      end
      iter += 1
    end
    
    g_score[[@target_coordinate, :torch]]
  end
  
  def render
    (0...@grid.first.size).each do |y|
      puts @grid.map {|col| col[y] }.flatten.join(' ')
    end
  end

  private

  def _heuristic(from_tuple, to_tuple)
    from_coordinate, from_equipment = *from_tuple
    to_coordinate, to_equipment = *to_tuple

    score = 0

    score += 7 if from_equipment != to_equipment

    score += _taxi_distance(from_coordinate, to_coordinate)

    score
  end

  def _taxi_distance(c1, c2)
    x1, y1 = *c1
    x2, y2 = *c2

    (x2 - x1).abs + (y2 - y1).abs
  end

  def _valid_moves_of(tuple)
    coordinate, equipment = *tuple
    x, y = *coordinate
    
    valid_moves = [
      [    x, y - 1],
      [x + 1,     y],
      [    x, y + 1],
      [x - 1,     y],
    ].select {|x_a, y_a|
      0 <= x_a && 0 <= y_a # impossible to reach
    }.map {|x_b, y_b|
      [[x_b, y_b], _region_at([x_b, y_b])]
    }.select {|coordinate, region|
      region.permits?(equipment)
    }.map {|coordinate, region|
      [coordinate, equipment]
    }

    # staying and switching is always valid
    valid_moves << [coordinate, _region_at([x, y]).alternate_equipment(equipment)]
    
    valid_moves.to_set
  end

  def _time_cost_traversing(from_tuple, to_tuple)
    return 7 if from_tuple.first == to_tuple.first # same coordinate, means an equipment change
    1
  end

  def _build_cave_to(coordinate)
    x_c, y_c = *coordinate
    
    # my A* heuristic results in horizontal travel, and computing the regions
    # ahead of time saves cycles inside the distance loop. these values chosen
    # from trial and error
    x_c = x_c * 20
    y_c = y_c * 2

    @grid = Array.new(x_c + 1) { Array.new }
    (0..x_c).each do |x|
      (0..y_c).each do |y|
        @grid[x][y] = _region_at([x, y])
      end
    end
  end

  def _region_at(coordinate)
    x, y = *coordinate

    if @grid[x].nil?
      @grid[x] = Array.new
    end

    if @grid[x][y].nil?
      geologic_index = _geologic_index(coordinate)
      erosion_level = _erosion_level(coordinate)
      region = Region.new(geologic_index, erosion_level, coordinate == @mouth, coordinate == @target_coordinate)
      @grid[x][y] = region
    end

    @grid[x][y]
  end

  def _geologic_index(coordinate)
    x, y = *coordinate
    return @grid[x][y].geologic_index unless @grid[x].nil? || @grid[x][y].nil?
    return 0 if coordinate == @mouth
    return 0 if coordinate == @target_coordinate

    return x * 16807 if y == 0
    return y * 48271 if x == 0

    _erosion_level([x - 1, y]) * _erosion_level([x, y - 1])
  end

  def _erosion_level(coordinate)
    x, y = *coordinate
    return @grid[x][y].erosion_level unless @grid[x].nil? || @grid[x][y].nil?
    (_geologic_index(coordinate) + @depth) % 20183
  end
end

def run_tests
  test_scan = [510, [10, 10]]
  cs = CaveSystem.new(*test_scan)
  test(114, cs.risk_level)
  test(45, cs.minutes_to_target)
  puts
end

def part1(cs)
  cs.risk_level
end

def part2(cs)
  cs.minutes_to_target
end

run_tests

production_scan = [11109, [9, 731]]
cs = CaveSystem.new(*production_scan)

puts "What is the total risk level for the smallest rectangle that includes 0,0 and the target's coordinates?"
puts "Answer: #{part1(cs)}"

puts "What is the fewest number of minutes you can take to reach the target?"
puts "Answer: #{part2(cs)}"













