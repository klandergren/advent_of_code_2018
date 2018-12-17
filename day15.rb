require_relative 'toolbox'

# plan:
#  [X] sample battles to files
#  [X] battle field class
#  [X] battle field parser
#  [X] test file parser
#  [X] unit class (goblin and elf)
#  [X] game runner
#  [X] test harness for battle summaries

DEFAULT_HIT_POINTS = 200
DEFAULT_ATTACK_POWER = 3

class Unit
  attr_accessor :current_coordinate
  attr_reader :hit_points
  def initialize(creature, x, y, hit_points, attack_power = DEFAULT_ATTACK_POWER)
    @creature = creature
    @current_coordinate = [x, y]
    @hit_points = hit_points
    @attack_power = attack_power
  end

  def take_step(battle_field)
    in_range = battle_field.open_coordinates_to_attack(_enemy, @current_coordinate)
    return if in_range.include?(@current_coordinate)

    paths = in_range.map {|c| self.move(battle_field, @current_coordinate, c) }
    paths.compact!
    paths.sort! {|a,b| a.size <=> b.size }

    if !paths.empty?
      by_size = paths.group_by {|path| path.size }
      minimum_length = by_size.keys.min

      smallest_paths = by_size[minimum_length]

      # two things. (a) sort smallest paths by end node in reading order. (b) sort starting position in reading order
      real_smallest_path = smallest_paths.sort_by {|path| [path.last.last, path.last.first, path.first.last, path.first.first] }.first

      chosen_path = real_smallest_path
      LOGGER.debug { "chosen path: #{chosen_path.inspect}" }
      current_position = chosen_path.shift
      if current_position != @current_coordinate
        LOGGER.fatal { "tried to take path starting at #{current_position} but currently at #{@current_coordinate}" }
        exit
      end
      next_square = chosen_path.first
      battle_field.step(self, next_square)
    end

  end

  def perform_attack(battle_field)
    in_range = battle_field.open_coordinates_to_attack(_enemy, @current_coordinate)
    return unless in_range.include?(@current_coordinate)

    LOGGER.debug { "#{self} in range at #{@current_coordinate[0]}, #{@current_coordinate[1]}" }

    # attack weakest unit, in reading order
    x, y = *@current_coordinate
    candidates = [
      [x    , y - 1],
      [x - 1,     y],
      [x + 1,     y],
      [x    , y + 1]
    ]
    occupants = candidates.map {|c| battle_field.occupant(c[0],c[1]) }
    enemies = occupants.select {|s| s.is_a?(Unit) && s.type == _enemy }
    weakest_enemies = enemies.sort {|a,b| a.hit_points <=> b.hit_points }

    LOGGER.debug { "candidates: #{candidates.inspect}" }
    LOGGER.debug { "occupants: #{occupants}" }
    LOGGER.debug { "enemies: #{enemies.inspect}" }
    LOGGER.debug { "weakest_enemies: #{weakest_enemies.inspect}" }
      
    self.attack(weakest_enemies.first)
  end

  def take_turn(battle_field)
    battle_field.clear_dead
    # identify targets. no targets? game over
    return false if battle_field.coordinates_of(_enemy).empty?

    # identify open squares in range of each target (adjacent to target not occupied by wall or unit)
    in_range = battle_field.open_coordinates_to_attack(_enemy, @current_coordinate)
    LOGGER.debug { "#{self} at #{@current_coordinate[0]}, #{@current_coordinate[1]} in range of #{in_range.inspect}" }
    return true if in_range.empty?

    self.take_step(battle_field)
    self.perform_attack(battle_field)
    true
  end

  def reconstruct_path(came_from, current_coordinate)
    total_path = [current_coordinate]
    while came_from.keys.include?(current_coordinate)
      current_coordinate = came_from[current_coordinate]
      total_path << current_coordinate
    end
    total_path.reverse
  end

  def move(map, start, goal)
    closed_set = []
    open_set = [start]
    came_from = {}
    g_score = Hash.new(100_000)
    g_score[start] = 0

    while !open_set.empty?
      LOGGER.debug { "open_set: #{open_set.inspect}" }
      LOGGER.debug { "came_from: #{came_from.inspect}" }
      LOGGER.debug { "g_score: #{g_score.inspect}" }
      current = _minimum(open_set, g_score)
      if current == goal
        # TODO this should return multiple shortest paths, if they exist? or can we handle that scenario by attempting reading order movements first? so always check N, W, E, S?
        return reconstruct_path(came_from, current)
      end

      open_set.delete(current)
      closed_set << current

      map.open_neighbors_of(current).each do |neighbor|
        next if closed_set.include?(neighbor)
        
        tentative_g_score = g_score[current] + _taxi_distance(current, neighbor)

        if !open_set.include?(neighbor)
          open_set << neighbor
        elsif g_score[neighbor] <= tentative_g_score
          next
        end

        came_from[neighbor] = current
        g_score[neighbor] = tentative_g_score
      end
    end
    nil
  end

  def _taxi_distance(c1, c2)
    x1, y1 = *c1
    x2, y2 = *c2

    (x2 - x1).abs + (y2 - y1).abs
  end

  def _minimum(options, scores)
    LOGGER.debug { "options: #{options.inspect} scores: #{scores.inspect}" }
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

  def attack(unit)
    unit.take_hit(@attack_power)
    LOGGER.debug { "#{self} at #{@current_coordinate.inspect} attacked #{unit} at #{unit.current_coordinate.inspect}!" }
  end

  def take_hit(damage)
    @hit_points -= damage
  end

  def is_alive?
    1 <= @hit_points 
  end

  def type
    @creature
  end

  def to_s
    "#{@creature == :elf ? 'E' : 'G'}(#{@hit_points})"
  end

  private

  def _enemy
    self.type == :elf ? :goblin : :elf
  end

end

class BattleField
  def step(unit, coordinate)
    x,y = *unit.current_coordinate
    if @grid[x][y] != unit
      LOGGER.fatal { "#{unit} has out of date current_coordinate: #{x},#{y}. bf has square: #{@grid[x][y]}" }
      exit
    end
    x_dest, y_dest = *coordinate
    if @grid[x_dest][y_dest] != :open
      LOGGER.fatal { "#{unit.inspect} tried to move to #{coordinate} but was occupied by: #{@grid[x_dest][y_dest].inspect}" }
      exit
    end
    @grid[x][y] = :open
    @grid[x_dest][y_dest] = unit
    unit.current_coordinate = coordinate
    LOGGER.debug { "#{unit} moved from [#{x}, #{y}] to #{coordinate.inspect}! " }
  end

  def open_neighbors_of(coordinate)
    x, y = *coordinate
    # prefer reading order: north, west, east, south
    candidates = [
      [x    , y - 1],
      [x - 1,     y],
      [x + 1,     y],
      [x    , y + 1],
    ]
    candidates.select {|c| _is_open?(c) }
  end

  def _is_open?(coordinate)
    x, y = *coordinate
    @grid[x][y] == :open
  end

  def coordinates_of(creature_type)
    LOGGER.debug { "checking for squares with #{creature_type}" }
    coordinates = []
    @grid.each_with_index do |col, x|
      col.each_with_index do |square, y|
        if square.is_a?(Unit) && square.type == creature_type
          coordinates << [x,y]
        end
      end
    end
    LOGGER.debug { "found #{creature_type}s in #{coordinates.inspect}" }
    coordinates
  end

  def open_coordinates_to_attack(creature_type, current_coordinate)
    # filter for adjacent squares
    adjacent_square_coordinates = []
    coordinates_of(creature_type).each do |c|
      x,y = *c
      adjacent_square_coordinates << [    x, y - 1]
      adjacent_square_coordinates << [x - 1,     y]
      adjacent_square_coordinates << [x + 1,     y]
      adjacent_square_coordinates << [    x, y + 1]
    end

    adjacent_square_coordinates.uniq!

    # filter for open squares
    adjacent_square_coordinates.select {|c| _is_open?(c) || c == current_coordinate }
  end

  def occupant(x,y)
    @grid[x][y]
  end

  def clear_dead
    dead_units = []
    @grid.each_with_index do |col, x|
      col.each_with_index do |square, y|
        if square.is_a?(Unit) && square.hit_points <= 0
          dead_units << [x,y]
        end
      end
    end

    dead_units.each do |x, y|
      @grid[x][y] = :open
    end
  end

  def initialize(map_lines, elvish_attack_power = 3)
    width = map_lines.first.size
    height = map_lines.size
    @grid = Array.new(width) { Array.new(height, nil) }

    map_lines.each_with_index do |line, y|
      line.chars.each_with_index do |char, x|
        square = nil
        case char
        when '#'
          square = :wall
        when '.'
          square = :open
        when 'E'
          square = Unit.new(:elf, x, y, DEFAULT_HIT_POINTS, elvish_attack_power)
        when 'G'
          square = Unit.new(:goblin, x, y, DEFAULT_HIT_POINTS)
        else
          LOGGER.fatal { "tried to build map with unknown character: #{char}" }
          exit
        end
        @grid[x][y] = square
      end
    end
  end

  def print
    rows = []
    (0...@grid.size).each do |i|
      row = @grid.map {|n| _display(n[i]) }.join
      rows << "#{row}   "
    end

    positions = self.players.group_by {|unit| unit.current_coordinate.last }
    positions.keys.each do |y|
      row = rows[y]
      health = positions[y].map(&:to_s).join(', ')
      rows[y] = "#{row}#{health}"
    end

    rows.each do |row|
      puts row
    end
  end

  def determine_player_order
    self.clear_dead
    @player_order = @grid.map {|col| col.select {|square| square.is_a?(Unit) } }.flatten.sort_by {|unit| [unit.current_coordinate.last, unit.current_coordinate.first] }
  end

  def elves
    self.players.select {|u| u.type == :elf }.size
  end

  def players
    self.determine_player_order
    @player_order
  end

  def next_player
    LOGGER.debug { "player order: #{@player_order.inspect}" }
    player = @player_order.shift
    loop do
      break if @player_order.empty? || 0 < player.hit_points
      player = @player_order.shift
    end
    player
  end

  def ==(o)
    o.class == self.class && o.state == state
  end

  protected

  def state
    [@grid.map {|x| x.map {|square| square.is_a?(Unit) ? square.type : square } }]
  end

  private

  def _display(square)
    if square.is_a?(Unit)
      return 'E' if square.type == :elf
      return 'G' if square.type == :goblin
    else
      return '#' if square == :wall
      return '.' if square == :open
    end
  end
end

class GameRunner
  attr_reader :rounds, :winner, :total_hit_points

  def initialize(battle_field)
    @battle_field = battle_field
    @rounds = 0
    @winner = nil
    @total_hit_points = 0
  end

  def play!(max_rounds = 1000)
#    puts "initially:"
#    @battle_field.print 
    loop do
      LOGGER.debug { "begin round #{@rounds}:" }
#      if @rounds == 33
#        LOGGER.level = Logger::DEBUG
#      end
      break if @battle_field.coordinates_of(:elf).empty? || @battle_field.coordinates_of(:goblin).empty? || @rounds == max_rounds

      completed_turn = true
      @battle_field.determine_player_order
      loop do
        player = @battle_field.next_player
        LOGGER.debug { "player: #{player} taking turn" }

        break if player.nil? || @battle_field.coordinates_of(:elf).empty? || @battle_field.coordinates_of(:goblin).empty?
        next if player.hit_points < 0
        completed_turn = player.take_turn(@battle_field)
        break unless completed_turn
      end
      @battle_field.clear_dead
      break unless completed_turn
      @rounds += 1
#      puts "After #{@rounds} rounds:"
#      @battle_field.print
    end

    @winner = @battle_field.coordinates_of(:elf).empty? ? :goblin : :elf
    @total_hit_points = @battle_field.players.map {|p| p.hit_points }.reduce(:+)

  end

  def final_battle_field
    @battle_field
  end

  def outcome
    @rounds * @total_hit_points
  end

end

def load_test_file(f)
  lines = raw_lines(f)
  bf_width = lines.first.split(' ').first.size
  bf_height = lines.map(&:chars).map(&:first).select {|c| c == '#' }.size

  map_lines = lines.slice!(0, bf_height)

  initial_lines = []
  final_lines = []
  map_lines.each do |line|
    initial_lines << line.slice!(0, bf_width)
    line.slice!(0, 7)
    final_lines << line.slice!(0, bf_width)
  end
  initial_battle_field = BattleField.new(initial_lines)
  final_battle_field = BattleField.new(final_lines)

  winning_creature = (lines[-2].split(' ').first == 'Goblins' ? :goblin : :elf)

  last_line = lines.last.split(' ')
  num_full_rounds = last_line[1].to_i
  total_hit_points = last_line[3].to_i
  outcome = last_line[-1].to_i

  [initial_battle_field, final_battle_field, num_full_rounds, winning_creature, total_hit_points, outcome]
end

def run_tests
  puts "Testing:"

  initial_battle_field = BattleField.new([
    '#######',
    '#.G...#',
    '#...EG#',
    '#.#.#G#',
    '#..G#E#',
    '#.....#',
    '#######'
  ])

  final_battle_field = BattleField.new([
    '#######',
    '#G....#',
    '#.G...#',
    '#.#.#G#',
    '#...#.#',
    '#....G#',
    '#######'
  ])
  test_data = load_test_file('data/day15_test_battle_0.txt')

  test(initial_battle_field, test_data[0])
  test(final_battle_field, test_data[1])
  test(47, test_data[2])
  test(:goblin, test_data[3])
  test(590, test_data[4])
  test(27730, test_data[5])

  (0..5).each do |i|
    puts
    puts "file: #{i}"
    test_data = load_test_file("data/day15_test_battle_#{i}.txt")
    bf = test_data[0]
    gr = GameRunner.new(bf)
    gr.play!
    test(test_data[1], gr.final_battle_field)
    test(test_data[2], gr.rounds)
    test(test_data[3], gr.winner)
    test(test_data[4], gr.total_hit_points)
    test(test_data[5], gr.outcome)
    puts
  end

  outcomes = [0, 4988, 31284, 3478, 6474, 1140]
  (2..5).each do |i|
    puts
    f = "data/day15_test_battle_#{i}_part2.txt"
    puts "testing: #{f}"
    test(outcomes[i], binary_search(f))
    puts
  end

  
  puts
end

def part1
  bf = BattleField.new(raw_lines('data/day15_production_battle.txt'))
  gr = GameRunner.new(bf)
  gr.play!
  gr.outcome
end

def binary_search(f, max_power = 35)
  outcome = 0
  prev_power = -1
  attempts = Array.new(max_power)
  outcomes = []
  power = max_power
  loop do
    puts "attempting power: #{power}"
    bf = BattleField.new(raw_lines(f), power)
    num_elves = bf.elves

    gr = GameRunner.new(bf)
    gr.play!

    puts "results: #{gr.rounds}, #{gr.total_hit_points}, #{gr.outcome} "
    outcome = gr.outcome
    outcomes[power] = outcome
    attempts[power] = (num_elves == bf.elves)

    if attempts[power] == false && attempts[power + 1] == true
      power = power + 1

      break
    end

    break if prev_power == power || (attempts[power] == true && attempts[power - 1] == false)

    prev_power = power

    if attempts[power]
      # decrease power to half distance between highest failing and current
      highest_failing_attempt = attempts.rindex(false)
      highest_failing_attempt ||= 4

      power = highest_failing_attempt + ((power - highest_failing_attempt) / 2)
    else
      # increase power to half distance between current attempt and lowest succeeding
      lowest_succeeding_power = attempts.find_index(true)
      lowest_succeeding_power ||= max_power

      power = power + ((lowest_succeeding_power - power) / 2)
    end
  end
  outcomes[power]
end

def part2
  binary_search('data/day15_production_battle.txt', 50)
end

run_tests

puts "Part 1: What is the outcome of the combat described in your puzzle input?"
puts "Answer: #{part1}"

puts "Part 2: After increasing the Elves' attack power until it is just barely enough for them to win without any Elves dying, what is the outcome of the combat described in your puzzle input?"
puts "Answer: #{part2}"


