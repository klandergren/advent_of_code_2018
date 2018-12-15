require_relative 'toolbox'

class Node
  attr_accessor :header, :child_nodes, :metadata_entries
  
  def value
    v = 0
    if child_nodes.empty?
      v = sum_metadata
    else
      metadata_entries.each do |e|
        next if e == 0

        index = e - 1
        child = child_nodes[index]
        if child
          v += child.value
        end
      end
    end
    v
  end

  def sum_metadata
    child_sum = child_nodes.map{|c| c.sum_metadata }.flatten.reduce(:+)
    child_sum ||= 0

    metadata_entries.reduce(:+) + child_sum
  end

end

class Tree
  attr_reader :license

  def load_file(f)
    @license = raw_lines(f).first.split(' ').map(&:to_i)
  end

  def load_string(s)
    @license = s.split(' ').map(&:to_i)
  end

  def root_node
    return @root_node if @root_node
    num_children = @license.shift
    num_metadata = @license.shift
    @root_node = Node.new
    @root_node.header = [num_children, num_metadata]

    if num_children == 0
      @root_node.child_nodes = []
    else
      @root_node.child_nodes = _child_nodes(num_children, @license)
    end
    @root_node.metadata_entries = @license.slice!(0 - num_metadata, num_metadata)
    @root_node
  end

  private

  def _child_nodes(amount, license)
    LOGGER.debug { "b - license: #{license.inspect}" }
    nodes = []

    amount.times do
      num_children = license.shift
      num_metadata = license.shift
      n = Node.new
      n.header = [num_children, num_metadata]

      if num_children == 0
        n.child_nodes = []
      else
        n.child_nodes = _child_nodes(num_children, license)
      end
      n.metadata_entries = license.slice!(0, num_metadata)

      nodes << n
    end

    LOGGER.debug { "e - license: #{license.inspect} - nodes: #{nodes.inspect}" }
    nodes
  end

end

def run_tests
  puts "Testing:"
  t = Tree.new
  t.load_string("0 1 99")
  rn = t.root_node
  test(2, rn.header.size)
  test(0, rn.header[0])
  test(1, rn.header[1])
  test(0, rn.child_nodes.size)
  test(1, rn.metadata_entries.size)
  test([99], rn.metadata_entries)

  t = Tree.new
  t.load_string("0 3 10 11 12")
  rn = t.root_node
  test(2, rn.header.size)
  test(0, rn.header[0])
  test(3, rn.header[1])
  test(0, rn.child_nodes.size)
  test(3, rn.metadata_entries.size)
  test([10,11,12], rn.metadata_entries)

  t = Tree.new
  t.load_string("2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2")
  rn = t.root_node
  test(2, rn.header.size)
  test(2, rn.header[0])
  test(3, rn.header[1])
  test(2, rn.child_nodes.size)
  test(3, rn.metadata_entries.size)
  test([1,1,2], rn.metadata_entries)
  test(138, rn.sum_metadata)

  t = Tree.new
  t.load_string("1 1 0 1 99 2")
  rn = t.root_node
  test(2, rn.header.size)
  test(1, rn.header[0])
  test(1, rn.header[1])
  test(1, rn.child_nodes.size)
  test(1, rn.metadata_entries.size)
  test([2], rn.metadata_entries)

  t = Tree.new
  t.load_string("2 1 0 1 99 0 1 99 16")
  rn = t.root_node
  test(2, rn.header.size)
  test(2, rn.header[0])
  test(1, rn.header[1])
  test(2, rn.child_nodes.size)
  test(1, rn.metadata_entries.size)
  test([16], rn.metadata_entries)

  rn.child_nodes.each do |n|
    test(2, n.header.size)
    test(0, n.header[0])
    test(1, n.header[1])
    test(0, n.child_nodes.size)
    test(1, n.metadata_entries.size)
    test([99], n.metadata_entries)
  end

  t = Tree.new
  t.load_string("2 2 2 1 0 1 99 0 1 99 16 2 1 0 1 99 0 1 99 16 32 32")
  rn = t.root_node
  test(2, rn.header.size)
  test(2, rn.header[0])
  test(2, rn.header[1])
  test(2, rn.child_nodes.size)
  test(2, rn.metadata_entries.size)
  test([32, 32], rn.metadata_entries)

  rn.child_nodes.each do |n|
    test(2, n.header.size)
    test(2, n.header[0])
    test(1, n.header[1])
    test(2, n.child_nodes.size)
    test(1, n.metadata_entries.size)
    test([16], n.metadata_entries)
  end

  puts
end

run_tests

#f = 'data/day08_test_license.txt'
f = 'data/day08_production_license.txt'

t = Tree.new
t.load_file(f)
puts "Part 1: What is the sum of all metadata entries?"
puts "Answer: #{t.root_node.sum_metadata}"

puts "Part 2: What is the value of the root node?"
puts "Answer: #{t.root_node.value}"


