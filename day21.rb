require_relative 'toolbox'

require 'set'

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

  def run_short_halting_program(lines, stop_on_instruction = -1)
    @instruction_pointer_register = lines.shift.split(' ').last.to_i
    @instructions = lines.map {|l| Instruction.new(l) }
    @instruction_pointer = @registers[@instruction_pointer_register]
    loop do
      break if @instructions.size <= @instruction_pointer
      @registers[@instruction_pointer_register] = @instruction_pointer
      @instructions[@instruction_pointer].execute(@registers)
      break if @instruction_pointer == stop_on_instruction
      @instruction_pointer = @registers[@instruction_pointer_register]
      @instruction_pointer += 1
    end
  end

  def run_long_halting_program(lines)
    vals28 = Set.new
    prev = 0
    @instruction_pointer_register = lines.shift.split(' ').last.to_i
    @instructions = lines.map {|l| Instruction.new(l) }
    @instruction_pointer = @registers[@instruction_pointer_register]
    loop do
      break if @instructions.size <= @instruction_pointer
      @registers[@instruction_pointer_register] = @instruction_pointer
      @instructions[@instruction_pointer].execute(@registers)
      if @instruction_pointer == 28
        magic = @registers[4]
        if vals28.include?(magic)
          return prev
        end
        vals28.add(magic)
        prev = magic
      end        
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

def part1
  cpu = CPU.new([0,0,0,0,0,0])
  # instruction 28 is where registers[0] finally gets used
  cpu.run_short_halting_program(raw_lines('data/day21_production_program.txt'), 28)
  cpu.registers[4]
end

def part2
  cpu = CPU.new([0,0,0,0,0,0])
  cpu.run_long_halting_program(raw_lines('data/day21_production_program.txt'))
end

puts "What is the lowest non-negative integer value for register 0 that causes the program to halt after executing the fewest instructions?"
puts "Answer: #{part1}"

puts "What is the lowest non-negative integer value for register 0 that causes the program to halt after executing the most instructions?"
puts "Answer: #{part2}"

