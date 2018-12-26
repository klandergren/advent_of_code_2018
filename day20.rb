require_relative 'toolbox'


# plan:
#  [X] figure out how to parse the regex string into a blueprint
#  [X] blueprint class w/ maker
#  [X] test file loader
#  [X] test harness
#  [X] largest_number_of_doors method
#  [X] filter on door counts

class Blueprint
  
  def initialize(regex)
    @grid = _load_grid(regex) 

    @grid.each_with_index do |col, x|
      col.each_with_index do |square, y|
        if square == :starting_coordinate
          @starting_coordinate = [x, y]
          break
        end
      end
    end
  end

  def render
    (0...@grid.first.size).each do |y|
      puts @grid.map {|col| _display(col[y]) }.flatten.join(' ')
    end
  end

  def largest_number_of_doors
    @scores ||= _calculate_door_counts
    @scores.values.max
  end

  def rooms_past_doors_of_at_least(num_doors)
    @scores ||= _calculate_door_counts
    @scores.values.select {|v| num_doors <= v }.count
  end

  def save_to_file(f)
    File.open(f, 'w') do |file|
      (0...@grid.first.size).each do |y|
        file.puts(@grid.map {|col| _display(col[y]) }.flatten.join(' '))
      end
    end
  end

  private

  def _load_grid(regex)
    max_dimension = 10 * regex.scan(/[NESW]+/).join.size
    grid = Array.new(max_dimension) { Array.new }

    starting_coordinate = [max_dimension / 2, max_dimension / 2]
    x, y = *starting_coordinate
    grid[x][y] = :starting_coordinate

    squares = regex.chars

    # cleanup
    squares.delete('^')
    squares.delete('$')

    # setup
    intersections = []
    current_position = starting_coordinate

    # walk grid
    loop do
      x, y = *current_position
      grid[x][y] ||= :room

      # install walls
      grid[x - 1][y - 1] ||= :wall
      grid[x + 1][y - 1] ||= :wall
      grid[x - 1][y + 1] ||= :wall
      grid[x + 1][y + 1] ||= :wall
      
      # install unknowns if nil
      grid[x][y - 1] ||= :unknown
      grid[x + 1][y] ||= :unknown
      grid[x][y + 1] ||= :unknown
      grid[x - 1][y] ||= :unknown

      break if squares.empty?
      square = squares.shift

      case square
      when '('
        # start a new intersection
        intersections << current_position
        next
      when '|'
        # retreat to previous intersection
        current_position = intersections.last
        next
      when ')'
        # pop last and return to previous
        current_position = intersections.pop
        next
      when 'N'
        grid[x][y - 1] = :horizontal_door
        current_position = [x, y - 2]
        next
      when 'E'
        grid[x + 1][y] = :vertical_door
        current_position = [x + 2, y]
        next
      when 'S'
        grid[x][y + 1] = :horizontal_door
        current_position = [x, y + 2]
        next
      when 'W'
        grid[x - 1][y] = :vertical_door
        current_position = [x - 2, y]
        next
      else
        LOGGER.fatal { "bad square: #{square}" }
        exit
      end
    end

    # cleanup crew
    grid.map! {|col| col.map! {|square| square == :unknown ? :wall : square } }
    grid.map! {|col| col.compact! }.reject! {|col| col.nil? || col.empty? }

    grid
  end

  def _display(square)
    case square
    when :unknown
      return '?'
    when :room
      return '.'
    when :horizontal_door
      return '-'
    when :vertical_door
      return '|'
    when :wall
      return '#'
    when :starting_coordinate
      return 'X'
    when nil
      return ' '
    else
      LOGGER.fatal { "unknown square rendered: #{square}" }
      exit
    end
  end

  def _calculate_door_counts
    closed_set = []
    open_set = [@starting_coordinate]
    came_from = {}
    g_score = Hash.new(100_000)
    g_score[@starting_coordinate] = 0

    loop do
      break if open_set.empty?
      current = _minimum(open_set, g_score)

      open_set.delete(current)
      closed_set << current

      open_neighbors = _open_neighbors_of(current)

      open_neighbors.each do |neighbor|
        next if closed_set.include?(neighbor)
        
        tentative_g_score = g_score[current] + 1

        if !open_set.include?(neighbor)
          open_set << neighbor
        elsif g_score[neighbor] <= tentative_g_score
          next
        end

        came_from[neighbor] = current
        g_score[neighbor] = tentative_g_score
      end
    end

    # potential destination rooms
    rooms = []

    @grid.each_with_index do |col, x|
      col.each_with_index do |square, y|
        rooms << [x, y] if square == :room
      end
    end

    scores = {}
    rooms.each do |coordinate|
      current_coordinate = coordinate
      doors_passed = 0
      loop do
        break unless came_from.has_key?(current_coordinate)
        current_coordinate = came_from[current_coordinate]
        doors_passed += 1
      end
      scores[coordinate] = doors_passed
    end

    scores
  end

  def _open_neighbors_of(coordinate)
    x, y = *coordinate

    # to be considered 'open', we need to see if there are doors in N, E, S, or
    # W, and a :room after that
    directions = [
      [[    x, y - 1], [    x, y - 2]],
      [[x + 1,     y], [x + 2,     y]],
      [[    x, y + 1], [    x, y + 2]],
      [[x - 1,     y], [x - 2,     y]],
    ]

    directions.select {|step1, step2| x, y = *step1; @grid[x][y] == :vertical_door || @grid[x][y] == :horizontal_door  }.map {|step1, step2| step2 }
  end

  def _minimum(options, scores)
    minimum_coordinate = nil
    minimum_score = 100_000
    options.each do |c|
      s = scores[c]
      if s < minimum_score
        minimum_score = s
        minimum_coordinate = c
      end
    end
    minimum_coordinate
  end
end

def parse_file(f)
  regex = raw_lines(f).first.split(' ').last
  furthest_rooms = raw_lines(f)[1].split(' ')[4]
  [regex, furthest_rooms]
end

def run_tests
  (0..4).each do |i|
    f = "data/day20_test_blueprint_#{i}.txt"
    regex, largest_number_of_doors = *parse_file(f)
    b = Blueprint.new(regex)
    test(largest_number_of_doors.to_i, b.largest_number_of_doors)
  end
  puts
end

def part1(b)
  b.largest_number_of_doors
end

def part2(b)
  b.rooms_past_doors_of_at_least(1000)
end

run_tests

b = Blueprint.new(raw_lines('data/day20_production_blueprint.txt').first)
puts "Part 1: What is the largest number of doors you would be required to pass through to reach a room?"
puts "Answer: #{part1(b)}"

puts "Part 2: How many rooms have a shortest path from your current location that pass through at least 1000 doors?"
puts "Answer: #{part2(b)}"








