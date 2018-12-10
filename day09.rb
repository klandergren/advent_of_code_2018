require_relative 'toolbox'

# plan:
#   * create model of the game
#   * test "stages" by using the sample game input
#   * once 25 marble game solved, move onto testing

class Game
  attr_reader :current_player, :board, :scores

  def initialize(players)
    @players = players
    @current_player = nil
    @current_marble_index = 0
    @board = []
    @scores = Hash.new(0)
  end

  def play_rounds(iteration)
    _setup
    (1..iteration).each do |i|
      @current_player = _player_for_round(i)
      _advance_board(i)
    end
  end

  def high_score
    @scores.values.max || 0
  end

  def current_marble
    @board[@current_marble_index]
  end

  private

  def _setup
    @current_player = "-"
    @current_marble_index = 0
    @board = [0]
  end

  def _player_for_round(i)
    return "-" if i == 0
    return @players.to_s if (i % @players) == 0
    (i % @players).to_s
  end

  def _advance_board(marble_in_play)
    # handle 23 case
    if marble_in_play % 23 == 0
      @scores[@current_player] += marble_in_play

      # get marble 7 counter clockwise
      remove_index = @current_marble_index - 7
      if @board.size <= remove_index.abs
        puts "bad tidings"
      end

      if remove_index < 0
        remove_index = @board.size + remove_index
      end
      @scores[@current_player] += @board.slice!(remove_index)

      @current_marble_index = remove_index

      return
    end

    # need to find the index to insert at
    # the index is between clockwise marbles 1 and 2

    first_index = @current_marble_index + 1
    if @board.size <= first_index
      first_index = 0
    end

    # insert in between
    @board.insert(first_index + 1, marble_in_play)
    @current_marble_index = first_index + 1
  end

end

class GameRunner
  def self.play_with(players, iterations)
    g = Game.new(players)
    g.play_rounds(iterations)
    g
  end
end

# returns array [a, b, c] where a is the current player, b is the current marble, c is the board
def parse_test_game_line(l)
  # cleanup lines from "5(22)11" to "5 (22) 11". adds extra space when no crowding that is removed by split.
  l.gsub!(/\(/, ' (').gsub!(/\)/, ') ')

  ans = []
  fields = l.split(' ')
  current_player = fields.shift.split('[').last.split(']').first
  current_marble_index = fields.find_index {|f| f.include?('(') }

  # strip out the parens
  fields[current_marble_index] = fields[current_marble_index].split('(').last.split(')').first
  board = fields.map(&:to_i)
  current_marble = board[current_marble_index]

  [current_player, current_marble, board]
end

def run_tests
  puts "testing initial conditions:"
  game = GameRunner.play_with(9, 0)
  test("-", game.current_player)
  test(0, game.current_marble)
  test([0], game.board)
  test(0, game.high_score)

  puts "\ntesting against sample game:"
  raw_lines('data/day09_test_game.txt').each_with_index do |line, i|
    debug "line: #{line}"

    expected = parse_test_game_line(line)
    current_player = expected[0]
    current_marble = expected[1]
    board = expected[2]
    high_score = 0
    high_score = 32 if 23 <= i

    debug "iter: #{i}"
    debug "current_player: #{current_player}"
    debug "current_marble: #{current_marble}"
    debug "board: #{board.inspect}"

    game = GameRunner.play_with(9, i)

    test(current_player, game.current_player)
    test(current_marble, game.current_marble)
    test(board, game.board)
    test(high_score, game.high_score)
  end

  puts "\ntesting against sample outcomes:"
  raw_lines('data/day09_test_outcomes.txt').each_with_index do |line, i|
    debug "line: #{line}"

    results = line.split(' ')
    players = results[0].to_i
    iters = results[6].to_i
    high_score = results[-1].to_i

    debug "iter: #{i}"
    debug "players: #{players}"
    debug "iters: #{iters}"
    debug "high_score: #{high_score}"

    game = GameRunner.play_with(players, iters)
    test(high_score, game.high_score)
  end
end

def part1
  line = raw_lines('data/day09_production_scenario.txt').first.split(' ')
  players = line[0].to_i
  iters = line[-2].to_i
  GameRunner.play_with(players, iters)
end

def part2
  return "brute force solution implemented. not running."
  
  line = raw_lines('data/day09_production_scenario.txt').first.split(' ')
  players = line[0].to_i
  iters = line[-2].to_i * 100
  g = GameRunner.play_with(players, iters)
  g.high_score
end

run_tests

game = part1

puts
puts "Part 1: What is the winning Elf's score?"
puts "Answer: #{game.high_score}"

puts "Part 2: What would the new winning Elf's score be if the number of the last marble were 100 times larger?"
puts "Answer: #{part2}"
