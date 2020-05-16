# crystal
Small programs written in Crystal language

This program allows multiple users to connect to a single
server prcoess like an interactive bash session or any other program which
runs on the command line and do not expect a real tty (e.g. top).

All input from connected clients is sent to the server process and to all
other connected clients. So you can chat on the bash or even better on
the ICR prompt with other users.

$ icr
127.0.0.1:56334 Client sent: 
icr(0.34.0) > 
puts "hello"
127.0.0.1:56334 Client sent: puts "hello"
puts "hello"
icr(0.34.0) > puts "hello"
hello
 => nil

The pefered way to connect is:
rlwrap socat localhost:9090   #rlwrap gives command history
or:
socat tcp:localhost:9090      #no issues with ctrl chars from client side
or:
telnet localhost 9090         #be carful, if you use ctrl chars on client side !!!

Use at your own risk, currently no password protected login
