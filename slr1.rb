# SLR1 table generator
class SLR1
  require_relative 'sets.rb'
  require 'set'
  # Grammar is a hash in the current form:
  # {
  # 	'Variable1' => [Production11, Production12,...],
  # 	'Variable2' => [Production21, Production22,...],
  # 	...
  # }
  # All variables should respect this rule:
  #   *First character is an upper case letter
  # The others are all considered terminals.
  #
  # IMPORTANT INFORMATION:
  #     1) The head of each production(Variable1, Variable2, ...)
  #     can be a symbol, but all of them are converted to string in
  #     the algorithm
  #     2) The first Variable will be considered the starting Variable
  #
  # The productions should respect this rule:
  # 		Every item of the alfhabet should hava a space in between him and the next
  # 		Example: 'Var1' => ['Var1 Var2 Terminal1', 'Var1 Terminal1']
  #
  # Epsilons should be represented using the exact string: epsilon
  #
  # An example of a valid grammar:
  # 	{
  # 	'E' => ['E S T', 'T'],
  # 	'S' => ['+', '-'],
  # 	'T' => ['T M F', 'F'],
  # 	'M' => ['*'],
  # 	'F' => ['( E )', 'numero', 'epsilon']
  # 	}
  def initialize(grammar)
    grammar = Hash[
      grammar.map do |k, v|
        [k.to_s, v.map { |prod| prod.split(' ') }]
      end
    ]
    @grammar = grammar
    @table = Hash.new { |hsh, key| hsh[key] = {} }
    @states = []
  end

  # Table will return the SLR(1) table.
  # The table will be a hash in current form:
  # {
  # 'e0' => {alphabet1:'e1', alphabet2:'e7', ...},
  # 'e1' => {alphabet1:'r1', alphabet4:'ac', ...},
  # ...
  # }
  #
  # Definitions of the table:
  # e* => the state e*
  # r* => the reduction r*
  # ac => means that the entry was accepted
  # observation: when the table returns nil,
  #   there is an error in the provided entry.
  def table
    generate_table if @table.empty?
    @table
  end

  def reductions
    generate_reductions if @reductions.nil?
    @reductions
  end

  private

  def generate_table
    add_new_stating_state
    @sets = Sets.new(@grammar)
    generate_reductions
    generate_states
  end

  def add_new_stating_state
    grammar_first_state = @grammar.keys.first
    @grammar[first_state] = [[grammar_first_state.to_s, eof]]
  end

  def generate_reductions
    reduction = 1
    @reductions = {}
    @grammar.each do |head_of_production, productions|
      productions.each do |production|
        item = [production.clone, head_of_production.clone]
        @reductions["r#{reduction}"] = item
        reduction += 1
      end
    end
    @reductions_inverted = @reductions.invert
  end

  def generate_states
    @states = [generate_first_state]
    @states.each.with_index do |state, state_index|
      current_state = "e#{state_index}"
      state.each do |head_of_production, productions|
        productions.each do |production|
          if production.last == dot
            prod = production.clone
            prod = [epsilon] if prod.size == 1
            prod.reject! { |x| x == dot }
            key = [prod, head_of_production]
            @sets.follow(head_of_production).each do |follow_item|
              if @table[current_state][follow_item] =~ /^r[0-9]+$/
                p 'This grammar is not SLR(1)'
                exit
              end
              unless @table[current_state][follow_item] =~ /^e[0-9]+$/
                @table[current_state][follow_item] = @reductions_inverted[key]
              end
            end
          end
          item_next_to_dot = production[production.index(dot) + 1]
          if item_next_to_dot == eof
            @table[current_state][eof] = 'ac'
            next
          end
          new_state = generate_new_state(state, head_of_production, production)
          next if new_state.nil?
          @states << new_state unless include?(@states, new_state)
          new_state_index = index(@states, new_state)
          state_to_go = "e#{new_state_index}"
          @table[current_state][item_next_to_dot] = state_to_go
        end
      end
    end
  end

  def index(array, element)
    e = {}
    element.each { |k, v| e[k] = v.to_set }
    array.each.with_index do |state, index|
      a = {}
      state.each { |k, v| a[k] = v.to_set }
      return index if a == e
    end
    nil
  end

  def include?(array, element)
    e = {}
    element.each { |k, v| e[k] = v.to_set }
    array.any? do |state|
      a = {}
      state.each { |k, v| a[k] = v.to_set }
      a == e
    end
  end

  def generate_new_state(state, head_of_production, production)
    return nil if production.last == dot
    dot_index = production.index(dot)
    item_next_to_dot = production[dot_index + 1]
    return nil if item_next_to_dot == '#eof'
    new_state = Hash.new { |hsh, key| hsh[key] = [] }
    new_state[head_of_production] << swap(production, dot_index, dot_index + 1)
    state.each do |head_of_p, productions|
      productions.each do |prod|
        next if head_of_p == head_of_production && production == prod
        dot_index = prod.index(dot)
        next unless prod[dot_index + 1] == item_next_to_dot
        new_state[head_of_p] << swap(prod, dot_index, dot_index + 1)
      end
    end
    closures = generate_closures_for new_state
    closures.each do |key, value|
      value.each do |prod|
        new_state[key] = new_state[key].push(prod).uniq
      end
    end
    new_state
  end

  def swap(arr, index1, index2)
    array = arr.clone
    temp = array[index1]
    array[index1] = array[index2]
    array[index2] = temp
    array
  end

  def generate_first_state
    production = @grammar[first_state].first.clone
    state = Hash.new { |hash, key| hash[key] = [] }
    state[first_state] = [production.unshift(dot)]
    closures = generate_closures_for state
    closures.each do |key, value|
      value.each do |prod|
        state[key] = state[key].push(prod).uniq
      end
    end
    state
  end

  def generate_closures_for(state)
    closures = find_closures_in_state_head state
    result = {}
    closures.each do |nonterminal|
      result[nonterminal] = closure(nonterminal)
      result[nonterminal].each do |production|
        item = get_item_to_find_closure(production)
        closures << item unless (closures.include? item) || item.nil?
      end
    end
    result
  end

  def find_closures_in_state_head(state)
    closures = []
    state.each do |_head, productions|
      productions.each do |production|
        item = get_item_to_find_closure(production)
        closures << item unless (closures.include? item) || item.nil?
      end
    end
    closures
  end

  def get_item_to_find_closure(production)
    index_next_to_dot = production.index(dot) + 1
    item_next_to_dot = production[index_next_to_dot]
    return nil unless variable? item_next_to_dot
    item_next_to_dot
  end

  def closure(element)
    closure = Marshal.load(Marshal.dump(@sets.closure(element)))
    closure.each { |e| e.unshift(dot) }
  end

  def first_state
    'StartingVar'
  end

  def dot
    '#dot'
  end

  def variable?(element)
    /\A[A-Z]/ =~ element ? true : false
  end

  def epsilon
    'epsilon'
  end

  def eof
    '#eof'
  end
end
