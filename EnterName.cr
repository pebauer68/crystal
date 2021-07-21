# written by peter.bauer, pebauer68@gmail.com
# tested on Ubuntu 20.04
# needs tcl wish installed
# see https://www.tcl.tk/man/tcl/UserCmd/wish.html

class Name
  property? hasdata = false
  property firstname
  property lastname

  def initialize(@firstname = "", @lastname = "")
  end
end

class Gui
  property? isopen = false
  property r = IO::FileDescriptor.new(fd = 0)
  property w = IO::FileDescriptor.new(fd = 0)
  NL = "\n"

  def initialize
    reader, writer = IO.pipe   # writer goes to process input
    reader2, writer2 = IO.pipe # reader2 delivers output
    spawn self.run_long_cmd(reader, writer2)
    @r = reader2
    @w = writer
  end

  def run_long_cmd(proc_stdin, proc_stdout) # run cmd in a fiber
    @isopen = true
    Process.run("wish", output: proc_stdout, input: proc_stdin)
    puts "\rWish Process ended"
    @isopen = false
  end

  def close_window
    close_window = %(wm forget .)
    @w << close_window << NL
  end

  def set_window_properties
    properties = {
      "window"          => %(wm resizable . 0 0),
      "title"           => %(wm title . EnterName),
      "label1"          => %(label .l1 -text "Please enter your name"),
      "label2"          => %(label .l2 -text "Name: "),
      "entry1"          => %(entry .e -textvariable name),
      "pack_label1"     => %(pack .l1 -side top -anchor w),
      "pack_entry1"     => %(pack .e -side top -anchor w),
      "pack_label2"     => %(pack .l2 -side left -before .e),
      "bind_send_entry" => %(bind .e <Return> { puts $name }),
    }
    properties.each_value { |prop|
      @w << prop << NL
    }
  end

  def run_app(mygui, myname, debug = false) # run receive in a fiber
    counter = 0
    while receive = r.gets
      if receive && receive.size > 0 # got some chars
        puts "receive counter: #{counter}" if debug
        l = receive.size
        puts "got: #{l} chars" if debug
        puts receive if l > 0 && debug # write received data from wish to stdout
        if receive.includes?(" ")
          vals = receive.split
          myname.firstname, myname.lastname = vals if vals.size == 2
        else
          myname.firstname = receive
          myname.lastname = ""
        end
        myname.hasdata = true
      end
      sleep 0.1
      counter += 1
    end # end of while
  end
end

class Main
  mygui = Gui.new
  myname = Name.new
  mygui.set_window_properties
  spawn mygui.run_app(mygui, myname)
  sleep 0.5

  while mygui.isopen?        # run while window is open
    break if myname.hasdata? # wait for input data from tcl widget
    sleep 1
  end

  puts "GUI closed" unless mygui.isopen?
  mygui.close_window
  if myname.hasdata?
    puts "Name entered is: #{myname.firstname} #{myname.lastname} "
  end
end
