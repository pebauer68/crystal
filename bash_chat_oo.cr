require "socket"
module Mc  #Myclients is a Singleton
  extend self
  AC = Array(TCPSocket).new  #Constant array for client connections, can be changed, because mutable
  def bashpid(pid); bashpid=pid ; end
  def add_client(str)
      AC << str
      clients_print_state
  end
  def del_client(str)
      AC.delete str
      clients_print_state
  end
  def get_clients
      AC
  end    
  def clients_count : Int32
      AC.size
  end    
  def clients_print_state
      puts AC
      puts "Number of Clients Online: #{clients_count}"
  end
end   

class Chat
   include Mc
   @bashpid = 0
   @bashinputfd = IO::FileDescriptor.new(0, blocking: (LibC.isatty(0)) == 0)
   #class_property bashinputfd : IO = STDIN
   @channel = Channel(String).new
def initialize
end
def start_shell
#Long running Process, here an interactive shell for example
spawn do
    begin  
    cmd = "bash -i"
    Process.run(cmd, shell: true) do | p |
         pp p
         @bashpid = p.pid
         @bashinputfd = p.input.dup                #get copy of current fd
         p.input.puts("exec 2>&1")                 #stderr > stdout
         p.input.puts("echo connected to bash")    #send to STDIN of bash
          while line = p.output.read_line 
            puts line                     #send to STDOUT
            #send output of shell process to all online clients
            get_clients.each do |all|  
                     all.puts (line)   #send to Client
                   end  
          end
       end 
rescue exception
  puts "Error: #{exception.message}"
  puts "Shell process has ended, program exits"
  exit
  end
end
end

def start_chat_server
#Multi session TCP server 
server = TCPServer.new("localhost", PORT)
p! server
puts "Welcome, server with PID #{Process.pid},listening on TCP port #{PORT}"
puts "STDIN not connected to local terminal"
puts "Waiting for remote clients"
spawn do
  while client = server.accept?
    p! client
    p! client.remote_address
    spawn handle_client(client)
  end
end  
end

def handle_client(client)
#this def runs spwaned in a seperate fiber for every client session
#all needed objects must be passed in
    add_client(client)
    client.send "Hello in the bash chat: #{client.remote_address} \n"
    client.send "Please be careful, all input is logged\n"
    client.send "If you enter: \"exit\" the bash server will shutdown !!!\n"
    get_clients.each do |all|     #send echo to all clients
         all.puts (client.remote_address.to_s + " Logged in")
         all.puts ("Clients online: #{clients_count}")
       end
    while message = client.gets
      @channel.send (client.remote_address.to_s + " Client sent: " + message)
      puts @bashinputfd.puts message          #send to bash process
      get_clients.each do |all|     #send to all clients
        all.puts (client.remote_address.to_s + " Client sent: " + message)
        all.puts (message)
      end
    end
    #Client closes session
    del_client(client) 
    get_clients.each do |all|
      all.puts (client.remote_address.to_s + " Disconnected")
      all.puts ("Clients online: #{clients_count}")
    end   
end

def start_logging
#logging to stdout in main fiber
spawn do
     loop do
      puts Time.local.to_s + " IP:" + @channel.receive
     end 
  end
end

end
#end of class chat
PORT=9090
mychat = Chat.new
mychat.start_logging
mychat.start_shell
mychat.start_chat_server
sleep
