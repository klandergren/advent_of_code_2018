require_relative 'toolbox'

OPS_LOOKUP = {
  'addr' => ->(registers, a, b, c) {
    registers[c] = registers[a] + registers[b]
    registers
  },
  'addi' => ->(registers, a, b, c) {
    registers[c] = registers[a] + b
    registers
  },
  'mulr' => ->(registers, a, b, c) {
    registers[c] = registers[a] * registers[b]
    registers
  },
  'muli' => ->(registers, a, b, c) {
    registers[c] = registers[a] * b
    registers
  },
  'banr' => ->(registers, a, b, c) {
    registers[c] = registers[a] & registers[b]
    registers
  },
  'bani' => ->(registers, a, b, c) {
    registers[c] = registers[a] & b
    registers
  },
  'borr' => ->(registers, a, b, c) {
    registers[c] = registers[a] | registers[b]
    registers
  },
  'bori' => ->(registers, a, b, c) {
    registers[c] = registers[a] | b
    registers
  },
  'setr' => ->(registers, a, b, c) {
    registers[c] = registers[a]
    registers
  },
  'seti' => ->(registers, a, b, c) {
    registers[c] = a
    registers
  },
  'gtir' => ->(registers, a, b, c) {
    registers[c] = (a > registers[b] ? 1 : 0)
    registers
  },
  'gtri' => ->(registers, a, b, c) {
    registers[c] = (registers[a] > b ? 1 : 0)
    registers
  },
  'gtrr' => ->(registers, a, b, c) {
    registers[c] = (registers[a] > registers[b] ? 1 : 0)
    registers
  },
  'eqir' => ->(registers, a, b, c) {
    registers[c] = (a == registers[b] ? 1 : 0)
    registers
  },
  'eqri' => ->(registers, a, b, c) {
    registers[c] = (registers[a] == b ? 1 : 0)
    registers
  },
  'eqrr' => ->(registers, a, b, c) {
    registers[c] = (registers[a] == registers[b] ? 1 : 0)
    registers
  },
}

class CPU
  attr_reader :registers

  def initialize(registers)
    @registers = registers
  end

  def run_program(lines)
    @instruction_pointer_register = lines.shift.split(' ').last.to_i
    @instructions = lines.map {|l| Instruction.new(l) }
    @instruction_pointer = @registers[@instruction_pointer_register]
    loop do
      break if @instructions.size <= @instruction_pointer
      @registers[@instruction_pointer_register] = @instruction_pointer
      @instructions[@instruction_pointer].execute(@registers)
      @instruction_pointer = @registers[@instruction_pointer_register]
      @instruction_pointer += 1
    end
  end

  def to_s
    "r: #{@registers.inspect}, ipr: #{@instruction_pointer_register}, ip: #{@instruction_pointer}"
  end

end

class Instruction
  def initialize(args)
    values = args.split(' ')
    @op_name = values.shift

    @a, @b, @c = *values.map(&:to_i)
    @op = OPS_LOOKUP[@op_name]
  end

  def execute(registers)
    @op.call(registers, @a, @b, @c)
  end

  def to_s
    "#{@op_name} #{@a} #{@b} #{@c}"
  end

end

def run_tests
  cpu = CPU.new([0,0,0,0,0,0])
  cpu.run_program(raw_lines('data/day19_test_program.txt'))
  puts cpu.registers.inspect
end

def part1
  cpu = CPU.new([0,0,0,0,0,0])
  cpu.run_program(raw_lines('data/day19_production_program.txt'))
  cpu.registers.first
end

def part2
  return 'calculated manually'
end

run_tests

puts "Part 1: What value is left in register 0 when the background process halts?"
puts "Answer: #{part1}"

puts "What value is left in register 0 when this new background process halts?"
puts "Answer: #{part2}"















