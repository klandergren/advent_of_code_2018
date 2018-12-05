require 'time'
require_relative 'toolbox'

class RecordKeeper

  def initialize(f)
    @filename = f
    @h = Hash.new { |h, k| h[k] = Array.new(60, 0) }
  end

  # guard with the most sleep
  def strat1
    _generate_record if @h.empty?
    sleepiest_guard_id = nil
    max = 0
    @h.each do |id, minutes|
      total = minutes.reduce(&:+)
      if max < total
        max = total
        sleepiest_guard_id = id
      end
    end
    @h.select {|k,v| k == sleepiest_guard_id}
  end
  
  # guard with the most consistent sleep
  def strat2
    _generate_record if @h.empty?
    gid = nil
    max = 0
    @h.each do |id, minutes|
      peak = minutes.max
      if max < peak
        max = peak
        gid = id
      end
    end
    @h.select {|k,v| k == gid}
  end
  
  private

  def _generate_record
    id = nil
    fall_asleep_time = nil
    wake_up_time = nil

    _clean_and_sorted_lines.each do |line|
      date = Time.parse(line[/\[(.*?)\]/, 1])

      id = line.split(' ')[3].split('#').last.to_i if line.include?("Guard")

      if line.include?("Guard")
        fall_asleep_time = nil
        wake_up_time = nil
      end

      fall_asleep_time = date if line.include?("asleep")
      wake_up_time = date if line.include?("wakes")

      if line.include?("wakes")
        # get the fall asleep minute
        m_sleep = fall_asleep_time.strftime("%M").to_i
        m_wake = wake_up_time.strftime("%M").to_i

        (m_sleep...m_wake).each {|m| @h[id][m] += 1 }
      end
    end
  end

  def _clean_and_sorted_lines
    raw_lines(@filename).sort! {|a,b|
      da = Time.parse(a[/\[(.*?)\]/, 1])
      db = Time.parse(b[/\[(.*?)\]/, 1])
      da <=> db
    }
  end

end

def minute_with_most_sleep(guard)
  minutes = guard.values.first
  max_index = minutes.max
  minutes.find_index(max_index)
end

def checksum(guard)
  guard.keys.first * minute_with_most_sleep(guard)
end

def run_tests
  test_data_file = "data/day04_test_duty_records.txt"
  rk = RecordKeeper.new(test_data_file)
  puts "Part 1: testing..."
  expected = [240]
  (0...expected.size).each do |n|
    actual = checksum(rk.strat1)
    if actual == expected[n]
      puts "test #{n} passed"
    else
      puts "test #{n} failed! got #{actual} and expected #{expected[n]}"
    end
  end
  puts "Part 2: testing..."
  expected = [4455]
  (0...expected.size).each do |n|
    actual = checksum(rk.strat2)
    if actual == expected[n]
      puts "test #{n} passed"
    else
      puts "test #{n} failed! got #{actual} and expected #{expected[n]}"
    end
  end
end

run_tests

production_data_file = 'data/day04_production_duty_records.txt'
rk = RecordKeeper.new(production_data_file)

puts "Part 1: What is the ID of the guard you chose multiplied by the minute you chose?"
puts "Answer: #{checksum(rk.strat1)}"

puts "Part 2: What is the ID of the guard you chose multiplied by the minute you chose?"
puts "Answer: #{checksum(rk.strat2)}"

