require_relative 'toolbox'

# plan:
#  [X] test harness
#  [ ] figure out how to solve
#  [ ] production

def taxi_distance(c1, c2)
  x1, y1, z1, a1 = *c1
  x2, y2, z2, a2 = *c2

  (x2 - x1).abs + (y2 - y1).abs + (z2 - z1).abs + (a2 - a1).abs
end

def star_mapper(stars)
  constellations = []
  cluster = nil
  loop do
    break if stars.empty?
    star = stars.pop
#    LOGGER.debug { "#{star.inspect} with #{stars.inspect}" }
    cluster = constellation(star, stars)

#    LOGGER.debug { "found cluster: #{cluster.inspect}" }

    constellations << cluster

    stars.reject! {|s| cluster.include?(s) }
  end

  constellations.size
end

def constellation(star, coordinates)
#  LOGGER.debug { "checking #{star.inspect} with #{coordinates.inspect}" }
  members = []
  members << star

  original = coordinates.dup
  candidates = coordinates.dup
  loop do
    break if candidates.empty?
    candidate = candidates.pop
    next if members.include?(candidate)
    
    members.each do |member|
      if taxi_distance(member, candidate) <= 3
        members << candidate
        candidates = original.dup
        break
      end
    end

  end
  members.uniq!
  members
end

def run_tests
  puts "testing:"
  [2, 1, 4, 3, 8].each_with_index do |answer, i|
    f = "data/day25_test_points_0#{i}.txt"
    stars = raw_lines(f).map {|l| l.split(',').map(&:to_i) }

    break unless test(answer, star_mapper(stars))
  end
  puts
end

def part1
  stars = raw_lines('data/day25_production_points.txt').map {|l| l.split(',').map(&:to_i) }
  star_mapper(stars)
end

run_tests

puts "How many constellations are formed by the fixed points in spacetime?"
puts "Answer: #{part1}"




