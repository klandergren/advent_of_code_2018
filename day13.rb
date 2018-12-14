require_relative 'toolbox'

class Coordinate
  attr_reader :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end

  def next_in_direction(direction)
    case direction
    when :north
      return Coordinate.new(self.x, self.y - 1)
    when :east
      return Coordinate.new(self.x + 1, self.y)
    when :south
      return Coordinate.new(self.x, self.y + 1)
    when :west
      return Coordinate.new(self.x - 1, self.y)
    else
      puts "next_in_direction called incorrectly: #{self.inspect}"
      return Coordinate.new(-1,-1)
    end
  end

  def to_s
    "#{x},#{y}"
  end

end

class Cart
  attr_reader :coordinate
  attr_writer :track_type

  INTERSECTION_MOVEMENTS = [:left, :straight, :right]

  def initialize(initial_position, direction)
    @coordinate = initial_position
    @direction = direction
    @track_type = (@direction == :north || @direction == :south) ? :vertical : :horizontal
    @intersection_move = 0
  end

  def tick
    if @track_type == :curve_right
      case @direction
      when :north
        @direction = :east
      when :east
        @direction = :north
      when :south
        @direction = :west
      when :west
        @direction = :south
      else
        puts "next_coordinate called incorrectly: #{self.inspect}"
      end
    elsif @track_type == :curve_left
      case @direction
      when :north
        @direction = :west
      when :east
        @direction = :south
      when :south
        @direction = :east
      when :west
        @direction = :north
      else
        puts "next_coordinate called incorrectly: #{self.inspect}"
      end
    elsif @track_type == :intersection
      _direction_at_intersection
    end
    @coordinate = @coordinate.next_in_direction(@direction)
  end

  def to_s
    "#{self.coordinate.x},#{self.coordinate.y} #{@direction} #{@track_type}"
  end
  
  private

  # :straight is no change in direction
  def _direction_at_intersection
    movement = _intersection_decision
    case movement
    when :left
      case @direction
      when :north
        @direction = :west
      when :east
        @direction = :north
      when :south
        @direction = :east
      when :west
        @direction = :south
      else
        puts "_direction_at_intersection called incorrectly: #{self.inspect}"
      end
    when :right
      case @direction
      when :north
        @direction = :east
      when :east
        @direction = :south
      when :south
        @direction = :west
      when :west
        @direction = :north
      else
      end
    end
  end

  def _intersection_decision
    movement = INTERSECTION_MOVEMENTS[@intersection_move]
    if @intersection_move == 0
      @intersection_move = 1
    elsif @intersection_move == 1
      @intersection_move = 2
    elsif @intersection_move == 2
      @intersection_move = 0
    else
      puts "we lose big time"
    end
    movement
  end
end

class TrackSystem
  attr_reader :grid

  def initialize(system_map)
    @carts = []
    @collided = []
    @grid = Array.new(system_map.first.size) { Array.new(system_map.size, nil) }

    # populate the grid
    system_map.each_with_index do |row, y|
      prev_actual_track = nil
      row.chars.each_with_index do |track_piece, x|
        actual_track = nil
        # handle carts
        if _is_cart?(track_piece)
          cart_direction = _parse_direction(track_piece)
          @carts << Cart.new(Coordinate.new(x,y), cart_direction)

          # we have a cart. inspect the previous piece to derive underlying track
          if prev_actual_track.nil?
            # we were on leftmost edge or had empty spot. must be vertical
            actual_track = :vertical
          elsif prev_actual_track == :vertical
            actual_track = :vertical
          else
            actual_track = :horizontal
          end
        else
          actual_track = _parse(track_piece)
        end
        
        # insert actual_track into grid
        @grid[x][y] = actual_track

        prev_actual_track = actual_track
      end
    end
  end

  def tick
    @carts.sort_by! {|c| [c.coordinate.y, c.coordinate.x] }
    
    (0...@carts.size).each do |i|
      next if @carts[i].nil?
      @carts[i].tick
      @carts[i].track_type = @grid[@carts[i].coordinate.x][@carts[i].coordinate.y]

      # remove any collisions
      (0...@carts.size).each do |j|
        next if @carts[i].nil?
        next if @carts[j].nil?
        next if @carts[i] == @carts[j]
        next unless @carts[i].coordinate.x == @carts[j].coordinate.x
        next unless @carts[i].coordinate.y == @carts[j].coordinate.y
        
        @collided << @carts[i].dup
        @collided << @carts[j].dup
        @carts[i] = nil
        @carts[j] = nil
      end
    end
    @carts.compact!
  end
  
  def first_collision_coordinate
    loop do
      self.tick
      break unless @collided.empty?
    end
    @collided.first.coordinate
  end

  def last_cart_standing_coordinate
    loop do
      self.tick
      break if @carts.size == 1
    end
    @carts.first.coordinate
  end

  private

  def _is_cart?(track_piece)
    track_piece == '^' || track_piece == 'v' || track_piece == '<' || track_piece == '>'
  end

  def _parse_direction(track_piece)
    case track_piece
    when '^'
      return :north
    when 'v'
      return :south
    when '<'
      return :west
    when '>'
      return :east
    else
      puts "_parse_direction called incorrectly with #{track_piece}"
    end
  end

  def _parse(track_piece)
    case track_piece
    when '|'
      return :vertical
    when '-'
      return :horizontal
    when '/'
      return :curve_right
    when ' \ '.strip # work around emacs ruby-mode formatting bug
      return :curve_left
    when '+'
      return :intersection
    when ' '
      return nil
    else
      puts "_parse called with: #{track_piece}"
    end
  end
end

def run_tests
  puts "testing:"
  system_map = ['|','v','|','|','|','^','|']
  ts = TrackSystem.new(system_map)
  test('0,3', ts.first_collision_coordinate.to_s)

  system_map = raw_lines('data/day13_test_track_1.txt').select {|l| 0 < l.size }
  ts = TrackSystem.new(system_map)
  test('7,3', ts.first_collision_coordinate.to_s)

  system_map = raw_lines('data/day13_test_track_2.txt').select {|l| 0 < l.size }
  ts = TrackSystem.new(system_map)
  test('6,4', ts.last_cart_standing_coordinate.to_s)

  puts
end

def part1
  system_map = raw_lines('data/day13_production_track.txt').select {|l| 0 < l.size }
  ts = TrackSystem.new(system_map)
  ts.first_collision_coordinate
end

def part2
  system_map = raw_lines('data/day13_production_track.txt').select {|l| 0 < l.size }
  ts = TrackSystem.new(system_map)
  ts.last_cart_standing_coordinate
end

run_tests

puts "Part 1: To help prevent crashes, you'd like to know the location of the first crash."
puts "Answer: #{part1}"

puts "Part 2: What is the location of the last cart at the end of the first tick where it is the only cart left?"
puts "Answer: #{part2}"

