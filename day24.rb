require_relative 'toolbox'

# plan:
#  [X] classes for each type
#  [X] figure out combat / battle class
#  [X] tests against example
#  [X] production run

class Army
  attr_reader :name
  def initialize(name, groups)
    @name = name
    @groups = groups
  end

  def groups
    @groups.reject {|g| g.dead? }
  end

  def dead?
    self.num_units == 0
  end

  def num_units
    @groups.map(&:num_units).reduce(:+)
  end

  def select_targets(other_army)
    @groups.each do |group|
      group.select_targets(other_army.groups)
    end
  end

end

class Group
  attr_reader :army_name, :initiative

  def initialize(army_name, num_units, hit_points, attack, initiative, weaknesses = [], immunities = [])
    @army_name = army_name
    @num_units = num_units
    @hit_points = hit_points
    @attack = attack
    @initiative = initiative
    @weaknesses = weaknesses
    @immunities = immunities
  end

  def target_pref(groups)
    groups.reject {|g| self.ally?(g) || self.effective_damage(g) == 0 }
      .sort_by {|o| [self.effective_damage(o), o.effective_power, o.initiative] }
      .reverse.first
  end

  def ally?(group)
    self.army_name == group.army_name
  end

  def take_attack(damage)
    if @num_units == 0
      LOGGER.fatal { "tried to attack dead group: #{self.inspect}" }
      exit
    end
    LOGGER.debug { "       #{damage} damage" }
    num_killed = (damage.to_f / @hit_points).floor.to_i
    if (@num_units - num_killed) < 0
      num_killed = @num_units.dup
    end
    LOGGER.debug { "       #{num_killed} killed" }
    @num_units = @num_units.dup - num_killed
    LOGGER.debug { "       now only: #{@num_units} units" }
  end

  def effective_power
    self.num_units * @attack.power
  end

  def dead?
    self.num_units == 0
  end

  def num_units
    return @num_units if 0 < @num_units
    0
  end

  def is_immune_to?(attack_type)
    @immunities.include?(attack_type)
  end

  def is_weak_to?(attack_type)
    @weaknesses.include?(attack_type)
  end

  def to_s
    "ini: #{self.initiative} | ef: #{self.effective_power} | fighting for #{@army_name}"
  end

  def effective_damage(other_group)
    return 0 if other_group.is_immune_to?(@attack.type)
    return 2 * effective_power if other_group.is_weak_to?(@attack.type)
    effective_power
  end
end

class Attack
  attr_reader :power, :type
  def initialize(power, type)
    @power = power
    @type = type
  end

  def to_s
    "#{@power} #{@type}"
  end

end

class War
  def initialize(army1, army2)
    @army1 = army1
    @army2 = army2
  end

  # returns winning army
  def battle
    iter = 0
    loop do
      LOGGER.debug { "starting fight: #{iter}" }
      LOGGER.debug { "before: #{@army1.name}:" }
      @army1.groups.each do |g|
        LOGGER.debug { "   - #{g}" }
      end
      LOGGER.debug { "before: #{@army2.name}:" }
      @army2.groups.each do |g|
        LOGGER.debug { "   - #{g}" }
      end

      a1 = @army1.num_units
      a2 = @army2.num_units

      @army1, @army2 = _fight(@army1, @army2)
      LOGGER.debug { "after: army1: #{@army1.num_units} army2: #{@army2.num_units}" }
      break if @army1.dead? || @army2.dead?

      # stalemate
      return @army2 if ((a1 == @army1.num_units) && (a2 == @army2.num_units))

      iter += 1
    end
    @army1.dead? ? @army2 : @army1
  end

  private

  def _fight(army1, army2)
    # target selection phase
    alive_groups = army1.groups + army2.groups

    target_order = _target_order(alive_groups)
    targets = {}

    army1_groups = army1.groups.dup
    army2_groups = army2.groups.dup

    target_order.each do |group|
      if group.army_name == army1.name
        target_pref = group.target_pref(army2_groups)
        next if target_pref.nil?
        army2_groups.delete(target_pref)
        targets[group] = target_pref
      elsif group.army_name == army2.name
        target_pref = group.target_pref(army1_groups)
        next if target_pref.nil?
        army1_groups.delete(target_pref)
        targets[group] = target_pref
      end
    end

    # attacking phase
    attack_order = _attack_order(alive_groups)

    loop do
      break if attack_order.empty?
      LOGGER.debug { "new fight: " }
      attacker = attack_order.shift
      LOGGER.debug { "attacker: #{attacker}" }
      next if attacker.dead?
      opponent = targets[attacker]
      next if opponent.nil? || opponent.dead?
      LOGGER.debug { "opponent: #{opponent}" }
      opponent.take_attack(attacker.effective_damage(opponent))
      LOGGER.debug { " " }
    end
    
    [army1, army2]
  end

  def _target_order(groups)
    groups.sort_by {|g| [g.effective_power, g.initiative] }.reverse
  end

  def _attack_order(groups)
    groups.sort_by {|g| [g.initiative] }.reverse
  end

end

class WarMachine

  class <<self
    def remaining_units(f)
      army1, army2 = _parse_file(f)
      
      w = War.new(army1, army2)
      winner = w.battle
      winner.num_units
    end
    
    def minimum_immune_boost(f, guess = 100)
      results = []
      scores = []

      loop do
        break unless _minimum_boost(results).nil?

        LOGGER.debug { "guess: #{guess}" }
        army1, army2 = _parse_file(f, guess)
        
        w = War.new(army1, army2)
        winner = w.battle
        results[guess] = (winner.name == 'Immune System')
        scores[guess] = winner.num_units
        
        if (winner.name == 'Immune System')
          # we are too high
          last_loss = 0 unless results.include?(false)
          last_loss ||= results.rindex(false)
          guess = guess - ((guess - last_loss) / 2)
        else
          # we are too low
          last_win = results.index(true)
          last_win ||= 2 * guess
          guess = guess + ((last_win - guess) / 2)
        end

      end

      scores[_minimum_boost(results)]
    end

    private
    
    def _minimum_boost(results)
      winning_index = results.each_cons(2).to_a.index([false, true])
      return nil if winning_index.nil?
      winning_index + 1
    end

    def _parse_file(f, immune_boost = 0)
      armies = []
      groups = []
      army_name = nil
      raw_lines(f).each do |line|
        break if line == "end"
        if line.include?(':')
          army_name = line.gsub(/:/, '')
          groups = []
          next
        end
        
        if line.empty?
          armies << Army.new(army_name, groups)
          next
        end

        num_units = line.split(' ')[0].to_i
        hit_points = line.split(' ')[4].to_i
        attack_power = line.split(' with an attack that does ').last.split(' ')[0].to_i
        attack_power += immune_boost if army_name == 'Immune System'
        attack_type = line.split(' with an attack that does ').last.split(' ')[1].to_sym
        initiative = line.split(' with an attack that does ').last.split(' ')[5].to_i
        
        weaknesses = []
        immunities = []
        if line.include?('(')
          specials = line.split('(').last.split(')').first.split(';')
          specials.each do |special|
            if special.include?('weak')
              weaknesses = special.split('weak to ').last.split(', ').map(&:to_sym)
            else
              immunities = special.split('immune to ').last.split(', ').map(&:to_sym)
            end
          end
        end

        groups << Group.new(army_name,
                            num_units,
                            hit_points,
                            Attack.new(attack_power, attack_type),
                            initiative,
                            weaknesses,
                            immunities)
      end
      armies
    end

    def _parse_line(line)
      return nil if line.empty?
      return line.gsub(/:/, '') if line.include?(':')
    end

  end
end

def run_tests
  puts "testing:"
  test_file = 'data/day24_test_war.txt'
  test(5216, WarMachine.remaining_units(test_file))
  test(51, WarMachine.minimum_immune_boost(test_file))
  puts
end

def part1
  WarMachine.remaining_units('data/day24_production_war.txt')
end

def part2
  WarMachine.minimum_immune_boost('data/day24_production_war.txt')
end

run_tests

puts "Part 1: As it stands now, how many units would the winning army have?"
puts "Answer: #{part1}"

puts "Part 2: How many units does the immune system have left after getting the smallest boost it needs to win?"
puts "Answer: #{part2}"
