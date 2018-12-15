require_relative 'toolbox'


# plan:
#  [X] recipe class
#  [X] combiner functionality
#  [X] scoreboard class
#  [X] method on scoreboard to get scores after iter n
#  [X] method on scoreboard to get scores after at least r recipes
#  [X] method on scoreboard to return the 10 recipes after m total recipes

class Scoreboard
  def initialize(s1, s2)
    @s1, @s2 = s1, s2
    _reset
  end

  def scores_after_iterations(max_iter)
    _reset
    iter = 0
    loop do
      break if max_iter == iter 
      _tick
      iter += 1
    end
    @scores
  end

  def scores_after_num_recipes(num_recipes)
    _reset
    iter = 0
    loop do
      break if num_recipes <= @scores.size
      _tick
      iter += 1
    end
    @scores
  end

  def scores_before(sequence)
    _reset
    sub_score = sequence.chars.map(&:to_i)
    left_recipes = 0
    loop do
      _tick
      next if @scores.size < (sub_score.size + 1)
      next unless @scores[-1] == sub_score[-1] || @scores[-2] == sub_score[-1]
      next unless @scores[-2] == sub_score[-2] || @scores[-3] == sub_score[-2]
      next unless @scores[-3] == sub_score[-3] || @scores[-4] == sub_score[-3]
      next unless @scores[-4] == sub_score[-4] || @scores[-5] == sub_score[-4]
      scores = @scores.slice(-(sub_score.size + 1), sub_score.size + 1)
      
      iter = -1

      scores.each_cons(sub_score.size) do |score|
        iter += 1
        next unless score == sub_score
        if iter == 0
          @scores.pop
        end
        @scores.reverse!.slice!(0, sub_score.size )
        left_recipes = @scores.size
      end
      break if left_recipes != 0
    end
    left_recipes
  end

  private

  def _reset
    @scores = [@s1, @s2]
    @elf1_index = 0
    @elf2_index = 1
  end

  def _tick
    @scores.concat(_from_recipe_scores(@scores[@elf1_index], @scores[@elf2_index]))

    # update indicies
    @elf1_index = _new_index_from(@elf1_index, @scores[@elf1_index], @scores.size)
    @elf2_index = _new_index_from(@elf2_index, @scores[@elf2_index], @scores.size)
  end

  def _from_recipe_scores(s1, s2)
    sum = s1 + s2
    return [sum] if sum < 10
    [1, sum % 10]
  end

  def _new_index_from(index, score, scores_size)
    score_index = index + 1 + score
    return score_index if score_index < scores_size
    score_index % scores_size
  end

end

def part1(num_recipes)
  s = Scoreboard.new(3,7)
  scores = s.scores_after_num_recipes(num_recipes + 10)
  scores.slice(num_recipes, 10).map(&:to_s).join
end

def part2(score)
  s = Scoreboard.new(3,7)
  s.scores_before(score)
end

def run_tests
  puts "testing:"
  s = Scoreboard.new(3,7)
  test([3,7], s.scores_after_iterations(0))
  test([3,7,1,0], s.scores_after_iterations(1))
  test([3,7,1,0,1,0], s.scores_after_iterations(2))

  test([3,7,1,0,1,0], s.scores_after_num_recipes(6))

  test('0124515891', part1(5))
  test('5158916779', part1(9))
  test('9251071085', part1(18))
  test('5941429882', part1(2018))

  test(9, part2('51589'))
  test(5, part2('01245'))
  test(18, part2('92510'))
  test(2018, part2('59414'))

  puts 
end

run_tests

puts "Part 1: What are the scores of the ten recipes immediately after the number of recipes in your puzzle input?"
puts "Answer: #{part1(880751)}"

puts "Part 2: How many recipes appear on the scoreboard to the left of the score sequence in your puzzle input?"
puts "Answer: #{part2('880751')}"


