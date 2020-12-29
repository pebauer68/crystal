#require "readline"         #its better to use the rlwrap readline wrapper 
                            #from the shell: #rlwrap ./tree 
VARS = {
  "started"  => true,       #used in prompt()
  "debug"    => false,      #toggle debug message output by entering debug
  "filename" => "",         #currrent file loaded
  "lines"    => 0,          #number of lines
}
KEYWORDS = [ # list grows during runtime, when procs are added
  {"print", ->(x : String, y : Int32) { puts x; return 0 }},
  {"load", ->(x : String, y : Int32) { Code.load x; return 0 }},
  {"eval", ->(x : String, y : Int32) { eval x; return 0 }},
  {"ceval", ->(x : String, y : Int32) { ceval x; return 0 }},
  {"after", ->(x : String, y : Int32) { _after_(x, y); return 0 }},
  {"+", ->(x : String, y : Int32) { plus(x, y) }},
  {"inc", ->(x : String, y : Int32) { inc(x, y) }},
  {"<", ->(x : String, y : Int32) { lower(x, y) }},
  {"while", ->(x : String, y : Int32) { Code._while_(x, y); return 0 }},
  {"every", ->(x : String, y : Int32) { t = Timer.new; t.timer_test(x,y); return 0 }},
  {"split", ->(x : String, y : Int32) { split x; return 0 }},
  {"ls", ->(x : String, y : Int32) { ls x; return 0 }},
  {"let", ->(x : String, y : Int32) { let x; return 0 }},
  {"clear", ->(x : String, y : Int32) { clear x; return 0 }},
  {"p", ->(x : String, y : Int32) { _p_ x; return 0 }},
  {"!", ->(x : String, y : Int32) { system(x); return 0 }},
  {"now", ->(x : String, y : Int32) { puts Time.local.to_s("%H:%M:%S.%6N"); return 0 }},
  {"help", ->(x : String, y : Int32) { help(x); return 0 }},
  {"ls", ->(x : String, y : Int32) { ls; return 0 }},
  {"debug", ->(x : String, y : Int32) { VARS["debug"] = !VARS["debug"]; puts "debug is now: ", VARS["debug"]; return 0 }},
  {"test", ->(x : String, y : Int32) { procloop; return 0 }},
  {"pass", ->(x : String, y : Int32) { pass; return 0 }},
  {"end", ->(x : String, y : Int32) { Code._end_; return 0 }},
  {"cls", ->(x : String, y : Int32) { print "\33c\e[3J"; return 0 }},
  {"exit", ->(x : String, y : Int32) { exit(0) }},
]

#register Code evaluater functions and procs
Code.register
if ARGV.size == 1 # run file non interactive
  file = ARGV[0]
  eval("load #{file}")
  eval("run")
end
repl()

#run interactive if no file given or file not found
#error handler: print out error message and backtrace 
def repl
  line = ""
  loop do
    prompt()
    line = read_command()
    eval(line)
  rescue ex
    print "Error in: #{line}\n", ex.message, "\n"
    if Code.current_line > 0
      print "in File: #{VARS["filename"]} Line: #{Code.current_line}\n"
      ex.backtrace.each { |line|
        puts line
      }
      Code.current_line = 0
    end
  end
end

def prompt
  puts "Welcome to tree" if VARS["started"]
  VARS["started"] = false
  print ">"
end

#list VARS and functions
def ls(*arg)
  print "builtin vars: "
  puts VARS # builtin constants can change their value
  print "user vars: \n"
  print "vars_int32: ",Code.vars_int32,"\n" if Code.vars_int32.size > 0
  print "vars_string: ",Code.vars_string,"\n" if Code.vars_string.size > 0
  puts "functions:"
  Code.kwh.each { |d| puts d }
end

#read line from STDIN
def read_command
  #line = Readline.readline(prompt = ">", add_history = true)
  line = STDIN.gets
end

def help(*arg)  
helptext = <<-HELP
List Vars, functions: 
>ls

Set,clear vars:
>counter = 5 
>name = foo
>counter+ = 2
>clear          #clear all user vars

Print Strings, vars:
>p <varname> 
>print hello    

Call functions:
>now            # display current time
>after 5 exit   # call exit in 5 seconds
>every 5 now    # Set timers to run <function> every 5 seconds
                # here we just print the time
                # stop all started timers by typing >stop = 1

Load,run,list a script:
>load <filename>
>run  
>list
Run a script from cli:
./tree <filename>

Execute shell commands:
>! pwd     #be aware of the blank 
>! icr     #use icr(interactive crystal), exit with ^D
           #https://github.com/crystal-community/icr

Toggle debug on/off:
>debug

Execute functions like they were typed in:
>eval help

Eval via the crystal binary:
Expression is compiled and then executed.
This will take about a second per evaluation. 
>ceval puts 1+2
>ceval puts "aha"
The result is stored as a string in the user var:
ceval.result

HELP

puts helptext

if VARS["debug"]
    p! arg
    p! arg.first?
  end
end

#eval a line by
#search for operators and 
#looking up the commands in the keyword hash
def eval(line)
  #print "eval: ",line,"\n" if VARS["debug"]
  word = ""
  if line && line != ""
    ary = [] of String
    ary = split(line)
    if ary.includes?("+") # found operator in command ?
      ary.unshift("+")
    else
      if ary.includes?("=") # found operator in command ?
        ary.unshift("let")
      end
    end
    word = ary.shift                 # get first word
    return if word.starts_with?("#") # skip comments
    rol = ary.join(" ")              # rest of line

    # print "Word: ",word,"\n" if VARS["debug"]
    # print "Rol: ",rol,"\n" if VARS["debug"]

    if Code.kwh.try &.has_key?(word)
      Code.kwh.not_nil![word].call(rol, ary.size)
    else
      puts "Command #{word} not found"
    end
  end
end

#eval a line by  
#passing the line to the crystal binary 
def ceval(line)
  #print "eval: ",line,"\n" if VARS["debug"]
  if line && line != ""
    cmd  = "crystal"
    args = ["eval", line]
    status, output = run_cmd(cmd, args)
    puts output  
    # ser user var
    Code.vars_string = Code.vars_string.merge({"ceval.result" => output.chomp})  
    else
      puts "Line is empty"
   end
end

#run cmd as a subprocess and capture the output
def run_cmd(cmd, args)
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  status = Process.run(cmd, args: args, output: stdout, error: stderr)
  if status.success?
    {status.exit_code, stdout.to_s}
  else
    {status.exit_code, stderr.to_s}
  end
end

#split line into words by blank
#seperate operators from var names
def split(line)
  puts "Line in: ", line if VARS["debug"]
  ary = [] of String
  line.split(" ", remove_empty: true) { |string|
    if string.ends_with?("+") && string.size > 1 # find operator like "+"
      string = string.chomp("+")                 # seperate operator from string
      ary << string
      string = "+"
    end

    if string.ends_with?("+=")    # find operator like "+="
      string = string.chomp("+=") # seperate operator from string
      ary << string
      ary << "+"
      string = "="
    end

    ary << string
  }
  puts "Line splitted: ", ary if VARS["debug"]
  return ary
end

#load,run,list code
#loop fuction: while, end 
#register and merge procs
#into a central hash 
#named kwh - Keyword hash  
module Code
  class_property kwh = Hash(String, Proc(String, Int32, Int32)).new
  class_property codelines = [] of String
  class_property lines = 0
  #class_property line = ""
  class_property current_line = 0
  class_property last_line = 0
  class_property vars_int32 = { } of String => Int32 
  class_property vars_string = { } of String => String
  class_property jmp_trigger = "no"
  class_property start_line = "no"
  class_property skip_lines = false
  extend self
  
  #load code into the
  #String array  
  def load(filename)
    if File.exists?(filename)
      fd = File.open(filename)
      @@codelines.clear
      @@lines = 0
      while line = fd.gets
        # puts line
        @@codelines << line
        @@lines += 1
      end
      fd.close
      VARS["filename"] = filename
      VARS["lines"] = lines
      print "Loaded: ", filename, " Number of lines: ", lines, "\n"
    else
      puts "File #{filename} not found"
    end
  end

  #run code
  def run(arg)
    return if VARS["filename"] == ""
    @@current_line = 0
    @@skip_lines = false
    @@jmp_trigger = "no"
    @@start_line = "no"

    size = @@codelines.size
    loop do 
      line = @@codelines[@@current_line]
      #print "Current line:",@@current_line+1,"\n" if VARS["debug"]
      if !@@skip_lines
        #print "Eval line: ", @@line, "\n" if VARS["debug"]
        eval(line)
      else
        # print "find end of block\n"
        @@skip_lines = false if line.includes?("end")
      end
      if @@jmp_trigger != "no"
        @@current_line = @@jmp_trigger.to_i
        @@jmp_trigger = "no" # reset trigger
        # print "Jumping to: ",@@current_line," ",@@line,"\n"
      else
        @@current_line += 1
      end
      break if @@current_line >= codelines.size
    end # of loop
    puts "reached end of file"
  end # of run code

  #list the code
  def list
    @@codelines.each { |line|
      puts line
    }
  end
  
  #merge the keyword hash 
  def kws
    kws = {
      "run"  => ->(x : String, y : Int32) { run x; return 0 },
      "list" => ->(x : String, y : Int32) { list; return 0 },
    }
    index = 0
    while (index < KEYWORDS.size)
      kw = KEYWORDS.[index][0]
      proc = KEYWORDS.[index][1]
      # print kw ," ", KEYWORDS.[index][1],"\n"
      kws = kws.merge({kw => proc})
      index += 1
      # print kws[ "#{ kw }" ],"\n"
    end
    return kws
  end

  #register functions 
  def register
    @@kwh = Code.kws
  end
  
  #implement while
  def _while_(x : String, y : Int32)
    # while a < 77
    if y == 3
      varname = S.shift(x, start = true)
      cmp = S.shift(x)
      value = S.shift(x).to_i
      @@start_line = @@current_line.to_s

      result = lower("#{varname} #{cmp} #{value}", 3)
      if result == 0 # loop conditions not met
        @@skip_lines = true
        return
      end
    else
      puts "Method while needs at least 3 arguments"
      puts "got: ", x
    end
  end

  #implement end
  def _end_
    @@jmp_trigger = @@start_line
    # print "jmp trigger: ",@@start_line.to_s,"\n" if VARS["debug"]
  end
end   
#end of Code module


class Timer
  property name ="Test Name"

  def initialize
    puts "New instance started"
    p! self.name
    p! self.object_id
  end  

def timer_test(x , y)
if y >=2
  interval = x.split(" ")[0]
  job = x.split(" ")[1]
    puts "timer_test called with interval: #{interval}" 
    eval ("stop = 0")
    return if interval == ""
    eval ("interval = #{interval.to_i}")      #try to set a hash value
    if Code.vars_int32.has_key?("interval")   #check if the var really exists now
      puts "Var interval exists"
      puts "Message from Timer, type >stop = 1 to stop all started timers"
    end
    spawn {
      loop do
        eval job   
        sleep (Code.vars_int32["interval"])
        break if Code.vars_int32["stop"] == 1
      end
    }
 else
  puts "Method needs at least 2 arguments"
 end 
end 
end




#call function after x seconds
def _after_(x : String, y : Int32)  
print "function after called with: \n",x,"\n"  
  spawn do
    if y >= 2
      sleep S.shift(x, start = true).to_i
      rol = ""
      while y > 1
        rol += S.shift(x) + " "
        y -= 1
      end
      eval rol
    else
      puts "Method needs at least 2 arguments"
    end
  end
end

#S.shift gets elem from string
module S 
  class_property ind = 0
  
  def self.shift(x, start = false)
    if start
      @@ind = 0
    end
    ret = x.split(" ")[@@ind]
    @@ind += 1
    return ret
  end
end

def p_time
  puts(Time.local.to_s("%H:%M:%S.%6N"))
end

def procloop
  puts(Time.local.to_s("%H:%M:%S.%6N"))
  10.times {
    procs = {->pass}
    procs.each do |p|
      p.call
    end
  }
  puts(Time.local.to_s("%H:%M:%S.%6N"))
end

#do nothing
def pass
end

#set var to a value
def let(x : String)
  # <myintvar> = 7
  # <mystringvar> = "7"
  varname = x.split(" ")[0]
  value = (x.split(" ")[2]) 
  if value.to_i?
    Code.vars_int32 = Code.vars_int32.merge({varname => value.to_i})
  else if
    Code.vars_string = Code.vars_string.merge({varname => value})
   end 
  end
  # p! Code.vars_int32
end

#clear all vars in the hashes
def clear(x : String)
    Code.vars_int32.clear
    Code.vars_string.clear
end

#print var value to stdout
def _p_(x : String)
  if Code.vars_int32.has_key?(x)
    p Code.vars_int32[x].to_i  
  else if Code.vars_string.has_key?(x)
    p Code.vars_string[x]
  else
    puts "var not found" 
  end
 end
end

# lower "<" operator
def lower(x : String, y : Int32)
  # counter < 10
  varname, operand, val = x.split(" ")
  value = val.to_i
  # y=3
  # varname = S.shift(x,start=true)
  # operand = S.shift(x)
  # value = S.shift(x).to_i
  if Code.vars_int32[varname] < value
    return 1
  else
    return 0
  end
end

# add value to a var
# example:  counter+= 3
# splitted: counter + = 3
def plus(x : String, y : Int32)
  p! x if VARS["debug"] 
  if y == 4
    varname = x.split(" ")[0]
    value = x.split(" ")[3].to_i
    # varname = S.shift(x,start=true)
    # operator = S.shift(x)
    # assign = S.shift(x)
    # value = S.shift(x)
    Code.vars_int32[varname] += value
  else
    puts "Method plus needs at least 4 arguments"
    puts "got: ", x
  end
  return 0
end

# increment var value 
def inc(x : String, y : Int32)
  if y == 1
    varname = x.split(" ")[0]
    Code.vars_int32[varname] += 1
  else
    puts "Method inc needs 1 argument"
    puts "got: ", x
  end
  return 0
end