require "socket"
channel = Channel(String).new
class MyGlobals  
    property bashpid = 0  
    property bashinputfd = IO::FileDescriptor.new(0, blocking: (LibC.isatty(0)) == 0)
end
my=MyGlobals.new

class Mc    #My Clients Class
    @@ac = Array(TCPSocket).new  #array for client connections
    def self.add_client(str)
        @@ac << str
        print_state
    end
    def self.del_client(str)
        @@ac.delete str
        print_state
    end
    def self.get_clients
        @@ac
    end    
    def self.count
        @@ac.size
    end    
    def self.print_state
     p! @@ac
     puts "Number of Clients Online: #{count}"
   end
 end   

#Long running Process, here an interactive shell for example
spawn do
    begin  
    cmd = "bash -i"
    Process.run(cmd, shell: true) do | p |
         pp p
         my.bashpid = p.pid
         my.bashinputfd = p.input.dup              #get copy of current fd
         p.input.puts("exec 2>&1")                 #stderr > stdout
         p.input.puts("echo connected to bash")    #send to STDIN of bash
          while line = p.output.read_line 
            puts line                     #send to STDOUT
            #send output of shell process to all online clients
            Mc.get_clients.each do |all|  
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


#Multi session TCP server 
server = TCPServer.new("localhost", PORT)
p! server
spawn do
  while client = server.accept?
    p! client
    p! client.remote_address
    spawn handle_client(client,channel,my.bashinputfd)
  end
end  

def handle_client(client,channel,fd)
    Mc.add_client(client)
    client.send "Hello in the bash chat: #{client.remote_address} \n"
    client.send "Please be careful, all input is logged\n"
    client.send "If you enter: \"exit\" the bash server will shutdown !!!\n"
    Mc.get_clients.each do |all|     #send echo to all clients
         all.puts (client.remote_address.to_s + " Logged in")
         all.puts ("Clients online: #{Mc.count}")
       end
    while message = client.gets
      channel.send (client.remote_address.to_s + " Client sent: " + message)
      puts fd.puts message     #send to bash process
      Mc.get_clients.each do |all|     #send to all clients
            all.puts (client.remote_address.to_s + " Client sent: " + message)
            all.puts (message)
      end
    end
    #Client closes session
    Mc.del_client(client) 
    Mc.get_clients.each do |all|
      all.puts (client.remote_address.to_s + " Disconnected")
      all.puts ("Clients online: #{Mc.count}")
    end   
end

PORT=9090
puts "Welcome, server with PID #{Process.pid},listening on TCP port #{PORT}"
puts "STDIN not connected to local terminal"
puts "Waiting for remote clients"
while my.bashpid == 0
    puts "Wait for Bash start"
    sleep 0.1
  end
channel = Channel(String).new
Mc.print_state

#logging to stdout in main fiber
loop do
  puts Time.local.to_s + " IP:" + channel.receive
end

