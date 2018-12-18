require_relative 'toolbox'

# returns hash of operation names to their objects
def build_ops
  operations = []

  operations << Op.new('addr') do |registers, a, b, c|
    registers[c] = registers[a] + registers[b]
    registers
  end

  operations << Op.new('addi') do |registers, a, b, c|
    registers[c] = registers[a] + b
    registers
  end

  operations << Op.new('mulr') do |registers, a, b, c|
    registers[c] = registers[a] * registers[b]
    registers
  end

  operations << Op.new('muli') do |registers, a, b, c|
    registers[c] = registers[a] * b
    registers
  end

  operations << Op.new('banr') do |registers, a, b, c|
    registers[c] = registers[a] & registers[b]
    registers
  end

  operations << Op.new('bani') do |registers, a, b, c|
    registers[c] = registers[a] & b
    registers
  end

  operations << Op.new('borr') do |registers, a, b, c|
    registers[c] = registers[a] | registers[b]
    registers
  end

  operations << Op.new('bori') do |registers, a, b, c|
    registers[c] = registers[a] | b
    registers
  end

  operations << Op.new('setr') do |registers, a, b, c|
    registers[c] = registers[a]
    registers
  end

  operations << Op.new('seti') do |registers, a, b, c|
    registers[c] = a
    registers
  end

  operations << Op.new('gtir') do |registers, a, b, c|
    registers[c] = (a > registers[b] ? 1 : 0)
    registers
  end

  operations << Op.new('gtri') do |registers, a, b, c|
    registers[c] = (registers[a] > b ? 1 : 0)
    registers
  end

  operations << Op.new('gtrr') do |registers, a, b, c|
    registers[c] = (registers[a] > registers[b] ? 1 : 0)
    registers
  end

  operations << Op.new('eqir') do |registers, a, b, c|
    registers[c] = (a == registers[b] ? 1 : 0)
    registers
  end

  operations << Op.new('eqri') do |registers, a, b, c|
    registers[c] = (registers[a] == b ? 1 : 0)
    registers
  end

  operations << Op.new('eqrr') do |registers, a, b, c|
    registers[c] = (registers[a] == registers[b] ? 1 : 0)
    registers
  end

  operations.inject({}) {|h, op| h[op.name] = op; h }
end

class CPU
  attr_reader :registers

  def initialize(registers)
    @registers = registers
  end

  def process_instruction(instruction)
    instruction.execute(@registers)
  end
end

class Instruction
  def initialize(values, op)
    @op_code, @a, @b, @c = *values.split(' ').map(&:to_i)
    @op = op
  end

  def execute(registers)
    @op.execute(registers, @a, @b, @c)
  end

end

class Op
  attr_reader :name

  def initialize(name, &block)
    @name = name
    @block = block
  end

  def execute(registers, a, b, c)
    @block.call(registers, a, b, c)
  end

  def ==(o)
    o.class == self.class && o.state == state
  end

  protected

  def state
    [@block]
  end
  
end

class Tester
  # returns true if instruction produces final outcome
  def self.check(initial_registers, instruction_args, potential_op, final_registers)
    cpu = CPU.new(initial_registers.dup)
    instruction = Instruction.new(instruction_args, potential_op)
    cpu.process_instruction(instruction)
    cpu.registers == final_registers
  end
end

def run_tests
  puts "Testing:"
  operations = build_ops
  test(16, operations.size)

  truth_table = Hash.new(false)
  truth_table['addi'] = true
  truth_table['mulr'] = true
  truth_table['seti'] = true

  operations.each do |name, op|
    test(truth_table[name], Tester.check([3, 2, 1, 1], '9 2 1 2', op, [3, 2, 2, 1]))
  end

  test(1, count_three_or_more([[[3,2,1,1],'9 2 1 2',[3,2,2,1]]]))

  puts
end

def build_part1_input_data(f)
  input_data = []
  args = []
  double_blank_line = false
  prev_blank = false
  raw_lines(f).each do |line|
    next if double_blank_line
    
    if line.empty? && prev_blank
      double_blank_line = true
      next
    end

    if line.empty?
      prev_blank = true
      next
    end
    
    if line.include?('Before')
      prev_blank = false
      args = []
      args << line.split('[').last.split(']').first.split(',').map(&:to_i)
    elsif line.include?('After')
      prev_blank = false
      args << line.split('[').last.split(']').first.split(',').map(&:to_i)
      input_data << args
    else
      prev_blank = false
      args << line
    end
  end
  input_data
end

def count_three_or_more(input_data)
  LOGGER.debug { "input_data: #{input_data.size}" }

  total_count = 0
  operations = build_ops
  input_data.each do |before, instruction, after|
    
    count = 0
    operations.values.each do |op|
      result = Tester.check(before, instruction, op, after)
      LOGGER.debug { "#{result} #{before} -> #{after} with instruction #{op.name}-#{after}" }
      count += 1 if result
    end
    total_count += 1 if 3 <= count
  end

  total_count
end

def part1
  count_three_or_more(build_part1_input_data('data/day16_production_op_codes.txt'))
end

# returns array with correct ops per index
def build_op_code_lookup
  op_code_lookup = Array.new(16, nil)

  operations = build_ops
  input_data = build_part1_input_data('data/day16_production_op_codes.txt')

  loop do
    LOGGER.debug { "op_code_lookup: #{op_code_lookup.inspect}" }
    break unless op_code_lookup.any? {|x| x.nil? }

    input_data.each do |before, instruction, after|
      
      count = 0
      found_operation = nil
      operations.values.each do |op|
        next if op_code_lookup.include?(op)
        op_code = instruction.split(' ').map(&:to_i).first
        
        if Tester.check(before, instruction, op, after) && op_code_lookup[op_code].nil?
          count += 1
          found_operation = op
        end
      end
      if count == 1
        op_code = instruction.split(' ').map(&:to_i).first
        op_code_lookup[op_code] = found_operation
      end
    end

  end

  op_code_lookup
end

def build_part2_input_data(f)
  input_data = []
  double_blank_line = false
  prev_blank = false
  raw_lines(f).reverse.each do |line|
    next if double_blank_line
    
    if line.empty? && prev_blank
      double_blank_line = true
      next
    end

    if line.empty?
      prev_blank = true
      next
    end

    input_data.unshift(line)    
  end
  input_data
end

def part2
  op_code_lookup = build_op_code_lookup
  input_data = build_part2_input_data('data/day16_production_op_codes.txt')
  
  cpu = CPU.new([0,0,0,0])
  input_data.each do |instruction_args|
    op_code = instruction_args.split(' ').first.to_i
    instruction = Instruction.new(instruction_args, op_code_lookup[op_code])
    cpu.process_instruction(instruction)
  end
  cpu.registers[0]
end

run_tests

puts "Part 1: Ignoring the opcode numbers, how many samples in your puzzle input behave like three or more opcodes?"
puts "Answer: #{part1}"

puts "Part 2: What value is contained in register 0 after executing the test program?"
puts "Answer: #{part2}"


