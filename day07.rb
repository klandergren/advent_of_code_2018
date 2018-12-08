require_relative 'toolbox'

class Node
  attr_reader :name, :downstream_nodes, :upstream_nodes

  def initialize(name)
    @name = name
    @downstream_nodes = []
    @upstream_nodes = []
  end

  def add_downstream_node(n)
    @downstream_nodes << n
    @downstream_nodes.sort! { |a,b| a.name <=> b.name }
  end

  def add_upstream_node(n)
    @upstream_nodes << n
    @upstream_nodes.sort! { |a,b| a.name <=> b.name }
  end

end

class Graph
  attr_reader :nodes

  def initialize(f)
    @nodes = []
    @visited = []

    _load_graph(f)
  end

  def create_directed_edge(a, b)
    upstream_node = @nodes.select {|n| n.name == a }.first
    upstream_node = Node.new(a) if upstream_node.nil?
    
    downstream_node = @nodes.select {|n| n.name == b }.first
    downstream_node = Node.new(b) if downstream_node.nil?

    upstream_node.add_downstream_node(downstream_node)
    downstream_node.add_upstream_node(upstream_node)

    # hacky
    @nodes << upstream_node
    @nodes << downstream_node
    @nodes.uniq!
  end

  def path
    @visited = []
    p = ""
    loop do
      n = self.next_node
      p << n.name unless n.nil?
      break if n.nil?
    end
    p
  end

  def next_node
    if @visited.empty?
      n = root_nodes.first
      @visited << n
      return n
    end

    a = available_nodes
    n = _best_of(a)

    return n if n.nil?
    @visited << n
    n    
  end

  def mark_visited(n)
    @visited << n
  end

  def root_nodes
    @nodes.select {|n| n.upstream_nodes.empty?}.sort{|a,b| a.name <=> b.name }
  end

  def available_nodes
    a = @visited.map {|n| n.downstream_nodes }.flatten.uniq.select {|n| _is_reachable?(n) } - @visited

    # add any unvisited root nodes
    unvisited_root_nodes = root_nodes - @visited

    if !unvisited_root_nodes.empty?
      a = a + unvisited_root_nodes
    end
    a
  end

  def reset
    @visited = []
  end

  private

  def _best_of(nodes)
    nodes.sort {|a,b| a.name <=> b.name }.first
  end

  def _is_reachable?(n)
    (n.upstream_nodes - @visited).empty?
  end

  def _load_graph(f)
    raw_lines(f).each do |l|
      edge = l.split(' ' ).select {|w| w.length == 1}
      self.create_directed_edge(edge.first, edge.last)
    end
  end
end

class Processor
  def initialize(graph, n, extra_time)
    @graph = graph
    @workers = n
    @extra_time = extra_time
    @time = 0
  end

  # super hacky
  def process
    queues = Array.new(@workers) { Array.new }
    work_timings = Array.new(@workers, 0)
    in_progress = []
    available_nodes = @graph.available_nodes.reverse
    loop do
      debug "b - time: #{@time} - available nodes: #{available_nodes.map(&:name)} - work queues: #{queues}"

      # try to assign nodes
      queues.each do |q|
        if q[@time].nil?
          # are we idling?
          if available_nodes.empty?
            q[@time] = "."
          else
            # we have a node and an open queue
            n = available_nodes.pop
            in_progress << n
            t = @time + _time_for_node(n)
            (@time..t).each do |w|
              q[w] = n.name
            end
          end
        end

      end

      all_idle = queues.reject {|q| q[@time] == "." }.empty?
      debug "e - time: #{@time} - available nodes: #{available_nodes.map(&:name)} - work queues: #{queues} in progress: #{in_progress.map(&:name)}"
      @time += 1

      # is work done?
      queues.each do |q|
        nn = q[@time]
        pn = q[@time - 1]
        if nn.nil? && !pn.nil? && pn != "."
          prev_in = in_progress
          debug "#{pn} finished"
          finished_node = in_progress.select {|n| n.name == pn }.first
          @graph.mark_visited(finished_node)
          available_nodes = (@graph.available_nodes - prev_in).reverse
          in_progress.reject! {|n| n.name == pn }
        end
      end

      debug "in progress: #{in_progress.map(&:name)}"

      break if all_idle
    end

    queues.first.size - 1
  end

  private

  def _missing_work?
    @graph.available_nodes <= @workers
  end

  def _time_for_node(n)
    ("A".."Z").to_a.find_index(n.name) + @extra_time
  end

end

def run_tests
  test_data_file = 'data/day07_test_instructions.txt'
  g = Graph.new(test_data_file)

  test(6, g.nodes.size)
  test("C", g.root_nodes.first.name)
  test("C", g.next_node.name)
  test("A", g.next_node.name)
  test("B", g.next_node.name)
  test("D", g.next_node.name)
  test("F", g.next_node.name)
  test("E", g.next_node.name)
  test(nil, g.next_node)
  test("CABDFE", g.path)

  g.reset
  p = Processor.new(g, 2, 0)
  test(15, p.process)
end


run_tests

production_data_file = 'data/day07_production_instructions.txt'
g = Graph.new(production_data_file)

puts "Part 1: In what order should the steps in your instructions be completed?"
puts "Answer: #{g.path}"

g.reset
p = Processor.new(g, 5, 60)

puts "Part 2: With 5 workers and the 60+ second step durations described above, how long will it take to complete all of the steps?"
puts "Answer: #{p.process}"
