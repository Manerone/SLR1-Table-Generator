# Generate the first, follow and closure sets of a given grammar
class Sets
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
    @grammar = grammar
    @firsts = Hash.new { |hsh, key| hsh[key] = [] }
    @follows = Hash.new { |hsh, key| hsh[key] = [] }
    @closures = {}
  end

  # first(variable) returns a hash with the first set of the variable
  # variable is expected to be a string, using the variable rule that is:
  # 	Variables should start with a capital letter
  # The hash is in the current format:
  # {
  # variable => ['alphabet1', 'alphabet2',...]
  # }
  # Example:
  # { "F"=>["(", "num"] }
  def first(variable)
    generate_first_set(variable) if @firsts[variable].empty?
    @firsts[variable]
  end

  # follow(variable) returns a hash with the follow set of the variable
  # variable is expected to be a string, using the variable rule that is:
  # 	Variables should start with a capital letter
  # The hash is in the current format:
  # {
  # variable => ['alphabet1', 'alphabet2',...]
  # }
  # Example:
  # { "F"=>["+", "-", ")", "*"] }
  def follow(variable)
    generate_follow_set(variable) if @follows[variable].empty?
    @follows[variable]
  end

  # firsts returns the hash with all the first sets
  # The hash is in the current format:
  # {
  #  'Variable1' => ['alphabet1', 'alphabet2',...],
  #  'Variable2' => ['alphabet1', 'alphabet5',...],
  # ...
  # }
  # Example:
  # {
  # "F"=>["(", "num"],
  # "T"=>["(", "num"],
  # "E"=>["(", "num"],
  # "S"=>["+", "-"],
  # "M"=>["*"]
  # }
  def firsts
    generate_first_sets if @firsts.empty?
    @firsts
  end

  # follows returns the hash with all the follow sets
  # The hash is in the current format:
  # {
  #  'Variable1' => ['alphabet1', 'alphabet2',...],
  #  'Variable2' => ['alphabet1', 'alphabet5',...],
  # ...
  # }
  # Example:
  # {
  # "E"=>["+", "-", ")"],
  # "S"=>["(", "num"],
  # "T"=>["+", "-", ")", "*"],
  # "M"=>["(", "num"],
  # "F"=>["+", "-", ")", "*"]
  # }
  def follows
    generate_follow_sets if @follows.empty?
    @follows
  end

  def closures
    generate_closures if @closures.empty?
    @closures
  end

  def closure(variable)
    return @closures[variable] unless @closures[variable].nil?
    @closures[variable] = @grammar[variable].map do |production|
      production.reject { |x| x == epsilon }
    end
    @closures[variable]
  end

  private

  def generate_closures
    @grammar.each do |head_of_production, _|
      closure(head_of_production)
    end
  end

  # generate_follow_sets generate every follow set
  def generate_follow_sets
    @grammar.each do |variable, _|
      generate_follow_set variable
    end
  end

  # generate_first_sets generate every first set
  def generate_first_sets
    @grammar.each do |variable, _|
      generate_first_set variable
    end
  end

  # generate_follow_set(variable) generates the follou set for that variable
  # variable is expected to be a string, using the variable rule that is:
  # 	Variables should start with a capital letter
  def generate_follow_set(variable)
    return @follows[variable] unless @follows[variable].empty?
    @grammar.each do |head_of_production, productions|
      productions.each do |production|
        generate_follow_set_based_on_production(
          head_of_production, production, variable
        )
      end
    end
    @follows[variable]
  end

  # generate_follow_set_based_on_production generates the follow set of that
  # variable, based on that production
  #
  # head_of_production is the head that generates the given production,
  # it is expected to be a string, using the variable rule that is:
  # 		Variables should start with a capital letter
  #
  # production is the production to be searched for follow sets,
  # it is expected to follow the productions rules:
  # 	Should be a string, with every item with a space in between,
  # 	the itens should follow his current rules:
  # 		-Variables: should start with a capital letter
  # 		-Terminals: should not start with a capital letter
  #
  # variable is the non-terminal that is being analyzed to find the follow set,
  # it should respect the variable rule.
  #
  # No return is expected,
  # if any follow set is found, then it is added to @follows[variable]
  def generate_follow_set_based_on_production(head_of_production, production, variable)
    elements = production.clone
    if elements.include? variable
      indexes = elements.each_index.select { |i| elements[i] == variable }
      indexes.each do |index|
        generate_follow_set_starting_from_index_on_production(
          head_of_production, production, variable, index
        )
      end
    end
  end

  # generate_follow_set_starting_from_index_on_production
  # finds the follow set of the variable that is on that index,
  # inside that production.
  #
  # head_of_production is the head that generates the given production,
  # it is expected to be a string, using the variable rule that is:
  # 		Variables should start with a capital letter
  #
  # production is the production to be searched for follow sets,
  # it is expected to follow the productions rules:
  # 	Should be a string, with every item with a space in between,
  # 	the itens should follow his current rules:
  # 		-Variables: should start with a capital letter
  # 		-Terminals: should not start with a capital letter
  # variable is the non-terminal that is being analyzed to find the follow set,
  # it should respect the variable rule.
  #
  # index is the position inside the production that the variable was found,
  # to get its follow set
  #
  # No return is expected, if any follow set is found,
  # then it is added to @follows[variable]
  def generate_follow_set_starting_from_index_on_production(head_of_production, production, variable, index)
    elements = production.clone
    index += 1
    if index >= elements.size
      if head_of_production != variable
        set = generate_follow_set head_of_production
        follow_set_add variable, set
      end
      return
    end
    element = elements[index]
    if terminal? element
      follow_set_add variable, element unless equal_epsilon element
    else
      loop do
        set = first(element)
        unless set.include? epsilon
          follow_set_add variable, set
          break
        end
        set = set.reject { |x| x == epsilon }
        follow_set_add variable, set
        index += 1
        if index >= elements.size
          if head_of_production != variable
            set = generate_follow_set head_of_production
            follow_set_add variable, set
          end
          break
        end
        element = elements[index]
      end
    end
  end

  # generate_first_set(variable) generates the first set of the variable
  # variable is the non-terminal that is being analyzed to find the first set,
  # it should respect the Variable rule.
  # It is expected to return a hash with the first set of that variable
  # Example:
  # { "F"=>["(", "num"] }
  def generate_first_set(variable)
    return variable if terminal?(variable)
    if @firsts[variable].empty?
      @grammar[variable].each do |production|
        generate_first_set_based_on_production(production, variable)
      end
    end
    @firsts[variable]
  end

  # generate_first_set_based_on_production generates the first set of
  # that variable, based on that production
  #
  # production is the production to be search for the first set of the variable,
  # it is expected to follow
  # 	the productions rule, that is:
  # 		Should be a string, with every item with a space in between,
  # 		the itens should follow his current rules:
  # 			-Variables: should start with a capital letter
  # 			-Terminals: should not start with a capital letter
  # variable is the non-terminal that is being analyzed to find the first set,
  # it should respect the variable rule.
  def generate_first_set_based_on_production(production, variable)
    elements = production.clone
    element = elements.shift
    return if element == variable
    if terminal? element
      first_set_add variable, element
    else
      loop do
        set = generate_first_set element
        if elements.empty?
          first_set_add variable, set
          break
        end
        if set.include? epsilon
          set = set.reject { |x| x == epsilon }
          first_set_add variable, set
          element = elements.shift
        else
          first_set_add variable, set
          break
        end
      end
    end
  end

  def follow_set_add(key, value)
    set_add(@follows, key, value)
  end

  def first_set_add(key, value)
    set_add(@firsts, key, value)
  end

  def set_add(set, key, value)
    set[key] = [] if set[key].nil?
    set[key] << value
    set[key].flatten!
    set[key] = set[key].uniq
  end

  def terminal?(e)
    !variable?(e) || equal_epsilon(e)
  end

  def equal_epsilon(element)
    element == epsilon
  end

  def variable?(element)
    /\A[A-Z]/ =~ element ? true : false
  end

  def epsilon
    'epsilon'
  end
end
