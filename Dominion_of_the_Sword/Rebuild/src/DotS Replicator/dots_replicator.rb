require 'yaml'
require 'optparse'

$comment = nil
$command_prefix = nil
$args = []
$debug = false
$conv = nil
$noglobals = false

class ParseError < Exception
  def initialize(line = 0, error)
    super("(line "+line.to_s+") "+error)
    @line = line
  end
end

class InternalError < Exception
  def initialize(error=nil)
    super()
  end
end

class LogicError < Exception
  def initialize(error=nil)
    super(error)
  end
end

class DSR_IOError < Exception
  def initialize(error=nil)
    super(error)
  end  
end

#A lightwieght line based parsing system. Input is injected line by line and parsed using match or require.
class Parser
  attr_accessor :line
  attr_reader :column
  attr_reader :tokens

  MATCH_FAILACTION = lambda {|token, prevtoken, line| false}
  REQUIRE_FAILACTION = lambda do |token, prevtoken, line| 
    if prevtoken
      raise ParseError.new(line, 'expected '+token.to_s+' after '+prevtoken.to_s)
    else
      raise ParseError.new(line, 'expected '+token.to_s)
    end
  end

  def initialize
    @tokens = []
    @column = 0
    @line = 0
  end

  #Inject the next line of tokens
  def next_line(input=[])
    @tokens = input
    @column = -1
    @line += 1
  end

  def skip_line
    @line += 1
  end

  private
  #This is the method invoked by match and require to perform the parsing.
  #It accepts the input as a sequence of string literals and special symbols.
  #String literals match if they equal the next token in the input.
  #
  #Special symbols are matched as follows:
  #+any+:: Matches any single token in the input. The match can only fail if there are no more tokens.
  #+start+:: Matches the start of input (immediately before the first token).
  #+end+:: Matches the end of input (immediately after the first token).
  #+ismatch+:: Does not make a match. Instead switches mode from match to require.
  #
  #If a match is sucessful, the parse column will be moved forward to the end of the match, otherwise it will remain put.
  #
  #parse is not to be invoked directly: use match or require instead.
  def parse(template, failAction)
    #Use a temporary solumn variable because if the match fails we want to keep the orginal column value.
    tempColumn = @column
    returnVars = []
    wasend = false
    template.each do |token|
      case token
        when :any then
          #Match any token
          #push matching token to return variables
            unless tempColumn>=@tokens.size
              returnVars.push(@tokens[tempColumn])
            else
              return failAction.call("further input", get_previous_token(tempColumn), @line)
            end
        when :start then
          #Match start of input
          return failAction.call("start of line", nil, @line) unless tempColumn == -1
        when :end then
          #Match end of input
          wasend=true
          return failAction.call("end of line", get_previous_token(tempColumn), @line) unless tempColumn == @tokens.size
        when :ismatch
          failAction = REQUIRE_FAILACTION #Switch to require mode
          tempColumn-=1 #Compensate for the fact that this does not actually consume input
        else
          if token.kind_of?(String)
            #Match sting literal
            return failAction.call("'#{token}'", get_previous_token(tempColumn), @line) unless (token == @tokens[tempColumn])
          elsif token.kind_of?(Array)
            #Match one of several literals
            #Try matching each literal in sequence
            matchVar = nil
            token.each do |subtok|
              if matchVar = match(subtok, failAction)
                #If string literal matches an any
                @returnVars.push(matchVar) if matchVar.kind_of?(Array)
                break
              end
            end
          elsif token.kind_of?(Symbol)
            #Match any token
            #push matching token to return variables
            unless tempColumn>=@tokens.size
              returnVars.push(@tokens[tempColumn])
            else
              #Use custom error message
              return failAction.call(token.to_s, get_previous_token(tempColumn), @line)
            end
          else
            raise InternalError.new('invalid parsing template')
          end
      end
      tempColumn += 1 unless wasend
    end
    if tempColumn > @tokens.size
      return failAction.call("further input", get_previous_token(tempColumn), @line)
    end
    @column = tempColumn
    return returnVars.flatten
  end

  def get_previous_token(column)
    if column < 0
      return nil
    elsif column == 0
      return "start of line"
    elsif column > 0
      return "'#{@tokens[column-1]}'"
    end
  end

  public
  #Return array of +any+ matches if pattern matches, false otherwise. See also parse.
  def match(*template)
    return parse(template, MATCH_FAILACTION)
  end

  #Raise parse error if pattern fails to match, else return the last column of the match. See also parse.
  def require(*template)
    return parse(template, REQUIRE_FAILACTION)
  end
end

class Transformer3
  attr_reader :sets, :macros, :globals, :macro_parameters

  def initialize(sets = {}, input_stream, output_stream)
    @top_level_filter = Glob.new()
    @current_filter = @top_level_filter
    @current_set = []
    @tsets = {}
    @sets = sets
    @sets['globals'] = [] unless @sets.has_key?('globals')
    @globals = {
      'file' => File.basename(File.absolute_path($args[0])),
      'path' => File.dirname(File.absolute_path($args[0])),
      'date' => Time.now.strftime('%B %-e, %Y'),
      'time' => Time.now.strftime('%-l:%M %p %Z')
    }
    @macros = {}
    @macro_parameters = {}
    @current_macro = ''
    @current_macro_parameters = []
    @in_set = false
    @in_macro = false
    @comment = $comment
    @command_prefix = $command_prefix
    @parser = Parser.new
    @input_stream = input_stream
    @output_stream = output_stream
    create_parse_procs
  end

  def make_set_statement(klass, iterator_name)
    iterator_name = iterator_name[0]
    set_name = nil
    excluded_items = []
    next_excluded_item = nil
    included_items = []
    next_included_item = nil
    type = :include
    if set_name = @parser.match('all', :ismatch, :'set name')
      type = :exclude
      #All statement
      set_name = set_name[0]
      if excluded_items = @parser.match('except', :ismatch, :'list of excluded set items')
        #All except statement
        #First excluded set item parsed above; the rest are looped through below
        while next_excluded_item = @parser.match(:'excluded set item')
          excluded_items.push(next_excluded_item[0])
        end
      else
        excluded_items = []
      end
    else
      #Include statement
      included_items = @parser.require(:'set name', :'list of included set items')
      set_name = included_items.shift
      #First included set item parsed above; the rest are looped through below
      while next_included_item = @parser.match(:'included set item')
        included_items.push(next_included_item[0])
      end
    end
    push_filter(klass.new(iterator_name, verify_set(set_name), type, included_items, excluded_items))
  end

  #Add the given filter as a child to the filter of the current context.
  #This will also change the filter context to that of the new filter.
  def push_filter(filter)
    filter.line_end_format = @current_format
    @current_filter.append(filter)
    @current_filter = filter
  end

  #Move up one filter context level.
  def pop_filter
    if @current_filter.parent.nil?
      raise ParseError.new(@parser.line, "too many `end' keywords")
    elsif @current_filter.kind_of?(Unpack)
      @current_filter.delete_tset
    end
    @current_filter = @current_filter.parent unless @current_filter.parent.nil?
  end

  #Equivalent to push, but the given argument is a string to be appended as a child, and not a filter.
  #As a result, the filter context will not be changed.
  def scan(line)
    @current_filter.append(line)
    @parser.skip_line
  end

  def process
    unless @current_filter.parent.nil?
      raise LogicError.new("expected more `end' keywords before end of file")
    end
    return @top_level_filter.filtered_text
  end

  #Flush the set that is currently being defined to the set dictionary.
  def new_set
    @sets[@current_set_name] = @current_set
    @current_set = []
  end

  def new_macro
    @macros[@current_macro_name] = @current_macro
    @macro_parameters[@current_macro_name] = @current_macro_parameters
    @current_macro = ''
  end

  def new_tset(name, set = [])
    @tsets[name] = set
  end

  def delete_tset(name)
    @tsets.delete(name)
  end

  def verify_set(set_name)
    unless @tsets.has_key?(set_name)
      unless @sets.has_key?(set_name)
        raise ParseError.new(@parser.line, "found a reference to set `#{set_name}' but no such set exists")
      end
      return set_name
    end
    return set_name
  end

  def get_set(set_name)
    unless @tsets.has_key?(set_name)
      unless @sets.has_key?(set_name)
        raise ParseError.new(@parser.line, "found a reference to set `#{set_name}' but no such set exists")
      end
      return @sets[set_name]
    end
    return @tsets[set_name]
  end

  def safe_get_set(set_name)
    unless @tsets.has_key?(set_name)
      return @sets[set_name]
    end
    return @tsets[set_name]
  end

  def create_parse_procs

    @repeat_proc = proc do |repetitions|
      repetitions = repetitions[0]
      push_filter(Repeat.new(repetitions.to_i))
    end

    @on_proc = proc do |iterations|
      iterations = iterations[0]
      push_filter(OnIteration.new(iterations.to_i))
    end

    @except_on_proc = proc do |iterations|
      iterations = iterations[0]
      push_filter(OnIteration.new(iterations.to_i, true))
    end

    @for_range_proc = proc do |data|
      iterator_name = data[0]
      range_limits = data.shift
      if range_increment = @parser.match('increment', :ismatch, :'range increment value')
        range_increment = range_increment[0]
      else
        range_increment = 1
      end
      push_filter(ForRange.new(iterator_name, range_limits[0].to_i, range_limits[1].to_i, range_increment.to_i))
    end

    @for_each_proc = proc do |iterator_name|
      make_set_statement(ForEach, iterator_name)
    end

    @with_above_proc = proc do |iterator_name|
      make_set_statement(WithAbove, iterator_name)
    end

    @glob_proc = proc do |iterator_name|
      make_set_statement(Glob, 'dummy')
    end

    @set_proc = proc do |global_name|
      global_name = global_name[0]
      SetGlobal.new(global_name)
    end

    @write_proc = proc do |macro_name|
      macro_name = macro_name[0] #Flatten single element array
      macro_text = @macros[macro_name]
      raise ParseError.new(@parser.line, "found a reference to macro `#{macro_name}' but no such macro exists") unless macro_text
        if @parser.match('with')
          arguments = []
          arguments.push(@parser.require(:'macro argument value')[0])
          while arg = @parser.match(:'macro argument value')
            arguments.push(arg[0])
          end
        end
        raise ParseError.new(@parser.line, "the macro `#{macro_name}' expects #{@macro_parameters[macro_name].size} arguments, but #{arguments.size} were given") unless arguments.size == @macro_parameters[macro_name].size
        arg_hash = { }
        i = 0
        @macro_parameters[macro_name].each do |formal_name|
          arg_hash[formal_name] = arguments[i]
          i += 1
        end
        push_filter(MacroCall.new(macro_text, arg_hash))
        pop_filter #Macro calls cannot have children
    end

    @declare_proc = proc do |item_name|
      item_name = item_name[0]
      if @parser.match('counter')
        #Counter definition
        if counter_value = @parser.match('value', :ismatch, :'counter value')
          counter_value = counter_value[0]
        else
          counter_value = 0
        end
        if counter_increment = @parser.match( 'increment', :ismatch, :'counter increment value')
          counter_increment = counter_increment[0]
        else
          counter_increment = 1
        end
        #Create the counter and push to filter stack
        push_filter(Counter.new(item_name, counter_value.to_i, counter_increment.to_i))
      elsif @parser.match('set')
        @in_set = true #Set state as being in a set
        @current_set_name = item_name
      elsif @parser.match('macro')
        @in_macro = true #Set state as being in a macro
        @current_macro_name = item_name
        arguments = []
        if @parser.match('on')
          arguments.push(@parser.require(:'parameter name')[0])
          while arg = @parser.match(:'parameter name')
            arguments.push(arg[0])
          end
        end
        @current_macro_parameters = arguments
      else
        raise ParseError.new(@parser.line, "invalid datatype; expected `counter,' `macro,' or `set'")
      end
    end

    @if_proc = Proc.new do |set_name|
      if value = @parser.match('is', :ismatch, :'value')
        push_filter(IfIs.new(verify_set(set_name[0]), value[0]))
      elsif set_name2 = @parser.match('equals', :ismatch, :'set name')
        push_filter(IfEqual.new(verify_set(set_name[0]), verify_set(set_name2[0])))
      else
        push_filter(IfCondition.new(verify_set(set_name[0]), true))
      end
    end

    @unless_proc = Proc.new do |set_name|
      if value = @parser.match('is', :ismatch, :'value')
        push_filter(IfIs.new(verify_set(set_name[0]), value[0], true))
      elsif set_name2 = @parser.match('equals', :ismatch, :'set name')
        push_filter(IfEqual.new(verify_set(set_name[0]), verify_set(set_name2[0]), true))
      else
        push_filter(IfCondition.new(verify_set(set_name[0]), true))
      end
    end

    @unpack_proc = Proc.new do |vars|
      @tsets[vars[0]] = true
      push_filter(Unpack.new(vars[0], verify_set(vars[1])))
    end

    @wa_unpack_proc = Proc.new do |vars|
      @tsets[vars[0]] = true
      push_filter(WithAboveUnpack.new(vars[0], verify_set(vars[1])))
    end


    @parse_hash = {
      [:start, 'repeat', :ismatch, :'number of repititions', 'times'] => @repeat_proc,
      [:start, 'for', :'iterator name', 'in', 'range', :ismatch, :'start of range', 'to', :'end of range'] => @for_range_proc,
      [:start, 'for', 'each', :ismatch, :'iterator name', 'in'] => @for_each_proc,
      [:start, 'with', 'above', 'each', :ismatch, :'iterator name', 'in'] => @with_above_proc,
      [:start, 'with', 'above', 'unpack', :ismatch, 'each', :'iterator name', 'in', :'set name'] => @wa_unpack_proc,
      [:start, 'unpack', :ismatch, 'each', :'iterator name', 'in', :'set name'] => @unpack_proc,
      [:start, 'glob'] => @glob_proc,
      [:start, 'call', :ismatch, :'macro name'] => @write_proc,
      [:start, 'write', :ismatch, :'macro name'] => @write_proc,
      [:start, 'set', :ismatch, 'global', :'global name', 'to'] => @set_proc,
      [:start, 'declare', :ismatch, :'counter, macro, or set name', 'as'] => @declare_proc,
      [:start, 'on', :ismatch, 'iteration', :'integer'] => @on_proc,
      [:start, 'except', :ismatch, 'on', 'iteration', :'integer'] => @except_on_proc,
      [:start, 'if', :ismatch, :'set name'] => @if_proc,
      [:start, 'unless', :ismatch, :'set name'] => @unless_proc
    }

  end

  def run
    @input_stream.each_line do |line|
      config(line)
    end
    @output_stream.write(process)
  end

  def parse_line
    if @parser.match(:start, 'end', :ismatch, :end)
      pop_filter
      return
    end

    match_result = nil

    @parse_hash.each do |syntax, procedure|
      match_result = @parser.match(*syntax)
      if match_result
        procedure.call(match_result)
        @parser.require(:end)
        return
      end
    end

    raise ParseError.new(@parser.line, "invalid command; expected `call,' `declare,' `for,' `repeat,' `set global,' `unpack,' `with above,' or `write'")

  end

  def config(line)

    line = line.chomp
    orig_line = line.dup

    #Check if the string is a command string and strip the comment and command prefix if it is.
    line.strip!
    unless line.size >= @comment.size and line.slice(0, @comment.size) == @comment
      unless @in_macro or @in_set
        scan(orig_line)
        return #Not a command line
      end
    else
      line = line.slice(@comment.size, line.size - @comment.size)
    end

    command_indentation = line.slice(0, line.index(/[^\S]/) || 0) #TODO: test this line
    line.lstrip!
    unless line.size >= @command_prefix.size and line.slice(0, @command_prefix.size) == @command_prefix
      unless @in_macro or @in_set
        scan(orig_line)
        return #Not a command line
      end
    else
      line = line.slice(@command_prefix.size, line.size - @command_prefix.size)
    end

    unless @in_set or @in_macro
      line.lstrip!
      @current_format = :O
      #Format specifiers
      if line.size >= 1
        fm = line.slice(0, 1)
        @current_format = case fm
          when '+' then :'+'
          when '-' then :'-'
          when '=' then :'='
          else
            :O
        end
        line = line.slice(1, line.size - 1) unless @current_format == :O
        line.lstrip!
      end
    end

    @parser.next_line(line.split)

    #Handle set definition bodies
    if @in_set
      if @parser.match(:start, 'end', :ismatch, :end)
        @in_set = false
        new_set
      else
        @current_set.push(line.strip)
      end
      return
    end
    #Macro definition body
    if @in_macro
      if @parser.match(:start, 'end', :ismatch, :end)
        @in_macro = false
        new_macro
      else
        @current_macro += "\n" unless @current_macro.empty?
        @current_macro += line
      end
      return
    end

    #Inject next line of input
    parse_line

  end

end

class Aggregator

  attr_reader :text
  attr_accessor :line_end_string

  def initialize(lstr)
    @text = ''
    @line_end_string = lstr
  end

  def has_cached_text?
    return false
  end

  def clear
    @text = ''
  end

  def add(line)
    return if line.nil? or line.empty?
    @text = '' if @text.nil?
    unless @text.empty?
      @text += @line_end_string
    end
    @text += line
  end

  def append(line)
    return if line.nil?
    @text = '' if @text.nil?
    @text += "\n" unless @text.empty?
    @text += line
  end

  def set(text)
    @text = text
  end

end

#A Filter applies a transform to all of its children.
#Children can include blocks of text and other filters.
class Filter

  attr_accessor :parent
  attr_reader :line_end_format, :iteration

  def initialize
    @children = []
    @parent = nil
    @line_end_format = :O
    @acat = Aggregator.new(line_end_string)
    @cat = Aggregator.new(line_end_string)
    @iteration = 1
  end

  def line_end_format=(val)
    @line_end_format = val
    @cat.line_end_string = line_end_string
    return val
  end

  def line_end_string
    tmp = case @line_end_format
      when :'O' then "\n\n"
      when :'+' then "\n\n"
      when :'-' then "\n"
      when :'=' then " "
      else
        raise 'bad format specifier'
    end
    return tmp
  end

  def append(child)
    child.parent = self if child.kind_of?(Filter)
    @children.push(child)
  end

  def create_text

  end

  def aggregate
    return @acat.cached_text if @acat.has_cached_text?
    @acat.clear
    tmp = nil
    @children.each do |child|
      if child.kind_of?(String)
        @acat.append(child)
      else
        tmp = child.filtered_text
        @acat.append(tmp) unless tmp.nil?
      end
    end
    return @acat.text
  end

  #Returns a string that is the result of applying the transform to all children of this filter.
  def filtered_text
    return @cat.cached_text if @cat.has_cached_text?
    @cat.clear
    create_text
    @iteration += 1
    return @cat.text
  end

end

class SetGlobal < Filter

  def initialize(global_name)
    super()
    @name = global_name
    @line_end_format = :'-' if @line_end_format == :O #Different default than that of the standard
  end

  def create_text
    $conv.globals[@name] = aggregate
  end

end

class Unpack < Filter

  def initialize(iterator_name, set_name)
    super()
    @iterator_name = iterator_name
    @set_name = set_name
  end

  def create_text
    set = $conv.safe_get_set(@set_name)
    set.each do |child|
      $conv.new_tset(@iterator_name, child)
      @cat.add(aggregate)
      $conv.delete_tset(@iterator_name)
    end
  end

  def delete_tset
    $conv.delete_tset(@iterator_name)
  end

end

class WithAboveUnpack < Unpack

  def initialize(iterator_name, set_name)
    super(iterator_name, set_name)
    @position = 0
  end

  def create_text
    set = $conv.safe_get_set(@set_name)
    child = set[@position % set.size]
    $conv.new_tset(@iterator_name, child)
    @cat.set(aggregate)
    $conv.delete_tset(@iterator_name)
    @position += 1
  end

end

#ForEach is a Filter that copies one instance of its children for each item
#that is included from its set. The included set item is also ubstituted for
#the set iterator variable wherever it is found.
class ForEach < Filter

  def initialize(iterator_name, set, mode, include = [], exclude = [])
    super()
    @iterator_name = iterator_name
    @set = set
    @all = (mode == :exclude)
    @include = include
    @exclude = exclude
  end

  def create_set
    include = @include
    set = $conv.safe_get_set(@set)
    if @all
      include = set - @exclude
    end
    return include
  end

  def create_text
    create_set.each do |item|
      @cat.add(aggregate.gsub('{'+@iterator_name+'}', item))
    end
  end

end

#WithAbove is a set based version of Counter. It operates on the
#same set based criteria as ForEach, but like counter, does not loop itself,
#but only with the aid of a parent.
class WithAbove < ForEach

  def initialize(name, set, mode, include = [], exclude = [])
    super(name, set, mode, include, exclude)
    @position = 0
  end

  def create_text
    include = create_set
    tmp = aggregate.gsub('{'+@iterator_name+'}', include[@position % include.size])
    @position += 1
    @cat.set(tmp)
  end

end

class OnIteration < Filter

  def initialize(iteration, negate = false)
    super()
    @iteration = iteration
    @negate = negate
  end

  def test
    return !!(@parent.iteration == @iteration)
  end

  def create_text
    result = test
    result = !result if @negate
    tmp = aggregate
    ret =  result ? tmp : nil
    @iteration += 1
    @cat.set(ret)
  end

end

class IfCondition < Filter

  def initialize(set_name, negate = false)
    super()
    @set_name = set_name
    @set = nil
    @position = 0
    @negate = negate
  end

  def test
    return !!(@set[@position % @set.size])
  end

  def create_text
    @set = $conv.safe_get_set(@set_name)
    result = test
    result = !result if @negate
    tmp = aggregate
    ret =  result ? tmp : nil
    @position += 1
    @cat.set(ret)
  end

end

class IfIs < IfCondition

  def initialize(set, value, negate = false)
    super(set, negate)
    @value = value
  end

  def test
    return (@set[@position % @set.size] == @value)
  end

end

class IfEqual < IfCondition

  def initialize(set, set2, negate = false)
    super(set, negate)
    @set2_name = set2
    @set2 = nil
  end

  def test
    return (@set[@position % @set.size] == @set2[@position % @set2.size])
  end

  def create_text
    @set2 = $conv.safe_get_set(@set2_name)
    super
  end

end

class Glob < Filter

  def initialize(name= '', set = [], mode = :exclude, include = [], exclude = [])
    super()
    @all = (mode == :exclude)
    @include = include
    @exclude = exclude
  end

  def create_text
    set = $conv.globals.keys
    include = @include
    if @all
      include = set - @exclude
    end
    tmp = aggregate
    unless $noglobals
      @include.each do |key|
        tmp.gsub!('{$'+key+'}', $conv.globals[key])
      end
    end
    @cat.set(tmp)
  end

end

#ForRange is a Filter that copies one instance of its children for each integer
#in its range, substituting the current integer for the filter variable.
class ForRange < Filter

  def initialize(iterator_name, lower_bound, upper_bound, increment = 1)
    super()
    @iterator_name = iterator_name
    @lower_bound = lower_bound
    @upper_bound = upper_bound
    @increment = increment
  end

  def create_text
    counter = @lower_bound
    while counter <= @upper_bound
      @cat.add(aggregate.gsub('{'+@iterator_name+'}', counter.to_s))
      counter += @increment
    end
  end

end

#Repeat is a Filter that copies one instance of its children a given number of times.
#No variable substitution is performed.
class Repeat < Filter

  def initialize(iterator_name, repetitions)
    super()
    @iterator_name = iterator_name
    @repetitions = repetitions
  end

  def create_text
    repetitions.times do
      @cat.add(aggregate)
    end
  end

end

#Counter is a Filter substitutes the number of times it has been called (by a parent)
#for the filter variable.
class Counter < Filter

  def initialize(iterator_name, initial_value, increment)
    super()
    @iterator_name = iterator_name
    @value = initial_value
    @increment = increment
  end

  def create_text
    tmp = aggregate.gsub('{'+@iterator_name+'}', @value.to_s)
    @value += @increment
    @cat.set(tmp)
  end

end

class MacroCall < Filter

  def initialize(macro_text, args)
    super()
    @macro_text = macro_text
    @args = args
  end

  def create_text
    text = @macro_text.dup
    @args.each do |key, value|
      text.gsub!('{'+key+'}', value)
    end
    @cat.set(text)
  end

end

class App

  def run_transformer
    if @prefix_string
      files = []
      @prefix_string.size.times do
        files.push(StringIO.new('rw'))
      end
      files[0] = @input_file
      files.push(@output_file)
      i = 0
      @prefix_string.each_char do |c|
        $command_prefix = c
        $conv = Transformer3.new(@sets, files[i], files[i + 1])
        $conv.run
        #puts files[i + 1].readlines
        i += 1
      end
    end
    $conv = Transformer3.new(@sets, @input_file, @output_file)
    $conv.run
  end

  def load_options
    optdesc = nil
    OptionParser.new { |opts|
      opts.banner = "Usage: dots_replicator infile.txt outfile.txt [configfile.yaml] [options]\nSee README.txt for more information"

      opts.on("-h", "--help", "Display this message.") {
        puts <<DOC
Usage: dots_replicator infile.txt outfile.txt [configfile.yaml] [options]
See README.txt for more information

-h [--help]                 Display this message.

-c [ --comment] arg (=';')  The string that indicates the
                            beginning of a line comment.

-p [ --prefix] arg (='!')   A string that indicates that
                            the following comment line is
                            a DotS Replicator macro.

-i [ --input-encoding] arg  The encoding to use when reading 
                            the input file. (Autodetected by 
                            default.)

-o [ --output-encoding] arg The encoding to use when writing 
                            the output file. (UTF-8 by 
                            default.)

-g [ --no-globals]          Disable the substitution of 
                            globals. This may give a slight 
                            performance boost.

-s [ --prefix-sequence] arg Use the given single character
                            prefixes in sequence.
DOC
        exit
      }

      opts.on("-c", "--comment [arg]", "The string that indicates the beginning of a line comment.") { |c|
        $comment = c
      }
      
      opts.on("-p", "--prefix [arg]", "A string that indicates that the following comment line is a DotS Replicator macro.") { |p|
        $command_prefix = p
      }

      opts.on("-i", "--input-encoding [arg]", "The encoding to use when reading the input file.") { |i|
        @input_encoding = i
      }

      opts.on("-o", "--output-encoding [arg]", "The encoding to use when writing the output file.") { |o|
        @output_encoding = o
      }

      opts.on("-g", "--no-globals", "Disable the substitution of globals.") {
        $noglobals = true
      }

      opts.on("-s", "--prefix-sequence [arg]", "Use the given single character prefixes in sequence.") { |s|
        @prefix_string = s
      }

      opts.on("-d", "--debug", "Turn on full error reporting") {
        $debug = true
      }

      optdesc = opts
    }.order! { |arg|
      $args.push(arg)
    }
  end

  def load_parameters
    if $args.size < 2
      puts "Usage: dots_replicator infile.txt outfile.txt [configfile.yaml]\nSee README.txt for more information"
      exit
    end
    Encoding.default_internal = "UTF-8"
    @output_encoding ||= 'utf-8'
    if not @input_encoding.nil? and @input_encoding.downcase != 'utf-8'
      @input_file = File.new($args[0], "rb:#{@input_encoding}:utf-8")
    else
      @input_file = File.new($args[0], 'rb')
    end
    if @output_encoding.downcase != 'utf-8'
      @output_file = File.new($args[1], "w:#{@output_encoding}:utf-8")
    else
      @output_file = File.new($args[1], "w:#{@output_encoding}")
    end
  end

  def load_config_file
    if $args[2]
      config = YAML::load_file($args[2])
    else
      config = YAML::load_file('default.yaml')
    end
    unless config.kind_of?(Hash)
      raise DSR_IOError.new("invalid configuration file; expected top-level YAML !!map")
    end
    if $comment.nil?
      if config.has_key?('comment')
        $comment = config['comment']
        config.delete('comment')
      else
        $comment = ';'
      end
    end
    if $command_prefix.nil?
      if config.has_key?('command prefix') 
        $command_prefix = config['command prefix']
        config.delete('command prefix')
      else
        $command_prefix = '!'
      end
    end
    @sets = config
  end

  def run
    begin
      load_options
      load_parameters
      load_config_file
      run_transformer
    rescue Object => e
      if $debug
        raise
      end
      if e.kind_of?(ParseError)
        puts 'syntax error: ' + e.message
      elsif e.kind_of?(LogicError)
        puts 'logic error: ' + e.message
      elsif e.kind_of?(DSR_IOError)
        puts 'io error: ' + e.message
      elsif e.kind_of?(Errno::ENOENT)
        puts 'file error: ' + e.message
      elsif e.kind_of?(SystemExit)
        #do nothing
      elsif e.kind_of?(Exception)
        puts 'internal error: ' + e.message
      else
        puts 'internal error: encountered unknown error'
      end
    end
  end

end

App.new.run