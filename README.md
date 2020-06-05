# crystal
Small programs written in Crystal language

**crybas.cr**  A GUI client which shows how to connect to a Gambas GUI server, and how to use the GUI elements

**bash_chat.cr** The program allows multiple users to connect to a single
server process like an interactive bash session or any other program which
runs on the command line and do not expect a real tty (e.g. top).

All input from connected clients is sent to the server process and to all
other connected clients. The output from the server process is sent to all clients.
So you can chat on the bash or even better on the ICR prompt with other users.
Coloured output from ICR seems to work.

$ icr  
127.0.0.1:56334 Client sent:   
icr(0.34.0) >   
puts "hello"  
127.0.0.1:56334 Client sent: puts "hello"  
puts "hello"  
icr(0.34.0) > puts "hello"  
hello  
 => nil  
 
The IP address and input of any client is visible to all connected clients. 

socat - tcp:localhost:9090  
Hello in the bash chat: 127.0.0.1:56334   
Please be careful, all input is logged  
If you enter: "exit" the bash server will shutdown !!!  
127.0.0.1:56334 Logged in  
Clients online: 1  
icr  
127.0.0.1:56334 Client sent: icr  
icr  
peter@brix:~/src_crystal$ icr  
WARNING: ICR is not a full featured REPL........  
 
## The pefered way to connect is:
rlwrap socat - tcp localhost:9090   #rlwrap gives command history on client side   
or:  
socat - tcp:localhost:9090      #no issues with ctrl chars from client side    
or:  
telnet localhost 9090         #be careful, if you use ctrl chars on client side !!!  

Use at your own risk, currently no password protected login
