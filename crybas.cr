#connect to Gambas GUI via TCP
#https://www.bitkistl.com/2020/05/the-crybas-demo-app.html
require "socket"
GUI_SERVER="localhost"
GUI_PORT=9090

class GuiClient
  property send_time = true
  @client = TCPSocket.new    #define var
  def connect
    @client = TCPSocket.new(GUI_SERVER,GUI_PORT)
  rescue err
    puts err.message  
    exit
  end

def send (object,value)
    puts "send(object,value)"     
    @client << object + "," + value + "\n"  #send to GUI_SERVER
end

def send (object)
  puts "send(object)"     
  @client << object + "\n"  #send to GUI_SERVER
end

def disconnect
  @client.close
end  

def receive  #handle events
  
spawn do  
        loop do    
            event = @client.gets
            puts event
            case event 
            when "Button1_clicked"  #stop button
              @send_time=false
            when "Button2_clicked"  #continue button
              @send_time=true
            when "Button3_clicked"  #clear textarea button
              send "textarea1.text",""    
            when "Button4_clicked"  #upcase textarea.text
              send "Textarea1.text" #request this value from gui elemen
              response = @client.gets
              puts "Response: ",response
              send "Textarea1.text",(response.not_nil! + "\n").upcase  #do upcase on string in textarea1
            when "Button5_clicked"  #upcase textarea.text
              send "Textarea1.text" #request this value from gui element
              response = @client.gets
              puts "Response: ",response
              send "Textarea1.text",(response.not_nil! + "\n").downcase  #do downcase on string in textarea1
            when "FMain_closed"     #Appilcation Window closed by user
            exit
            else  
            end  
        end
    end
  end
end  
#start the gambas gui server demo app
spawn do; system("~/src_gambas/gui_server/gui_server.gambas"); end
sleep 1   #give some time for startup
mygui = GuiClient.new
mygui.connect 
mygui.receive
mygui.send "textlabel1.text","crystal + gambas = crybas"
mygui.send "button1.text","stop"
mygui.send "button2.text","continue"
#mygui.send "button3.enabled","0"  #disable a button
mygui.send "button3.text","clear texrarea"
mygui.send "button4.text","do Text.upcase"
mygui.send "button5.text","do Text.downcase"
#send key,value pairs for GUI Objects based on GTK or QT 
mygui.send "FMain.Text","Crybas"   #set title of Application
mygui.send "Textarea1.Text","hello-textarea"

loop do   #Error writing to socket: Broken pipe when server closes
       mygui.send "Textbox1.Text",Time.local.to_s if mygui.send_time # display time in the gui
       sleep 1
    end   

sleep
