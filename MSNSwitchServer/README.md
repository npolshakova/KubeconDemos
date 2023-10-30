Heartbeat:
Heartbeat function allows a PC or Source to send a HTTP command to MSNswitch at an interval.

The function starts after the first command is received. If the next command is not received with the Timeout duration, the assigned outlet will auto reset. 

Check status:

https://<IP>/api/status

Turn outlet2 on:

https://<IP>/api/control?target=outlet2&action=on

Heartbeat:
“https://<IP>/api/heartbeat

Login:

curl http://192.168.0.68/goform/login/user=admin&password=switch818 -X POST \ 
    -H 'Accept-Encoding: gzip, deflate' \
    -H 'Content-Type: application/x-www-form-urlencoded' 

With cookie:

curl -X GET -H "Accept: */*" -H "Accept-Encoding: gzip, deflate" -H "Cookie: WQKJhuEcnAVA3t7WE+ug6A=gS6VX1bFhSKTFbaLh"


https://<IP>/api/control?target=outlet2&action=on

***

Working:

 curl -X GET -H "Accept: */*" -H "Accept-Encoding: gzip, deflate" -H "Cookie: WQKJhuEcnAVA3t7WE+ug6A=gS6VX1bFhSKTFbaLh" http://192.168.0.68/xml/outlet_status.xml


curl http://192.168.0.68/cgi-bin/control.cgi\?target\=1\&control\=2\&time\=1698618654678\&csrftoken\=GhvkmqB5Hh0i5BAaH -H "Cookie: WQKJhuEcnAVA3t7WE+ug6A=gS6VX1bFhSKTFbaLh"

Toggle 1:

curl http://192.168.0.68/cgi-bin/control.cgi\?target\=1\&control\=2\&time\=1698618654678\&csrftoken\=GhvkmqB5Hh0i5BAaH -H "Cookie: WQKJhuEcnAVA3t7WE+ug6A=gS6VX1bFhSKTFbaLh"

Toggle 2: 

curl http://192.168.0.68/cgi-bin/control.cgi\?target\=2\&control\=2\&time\=1698618654678\&csrftoken\=GhvkmqB5Hh0i5BAaH -H "Cookie: WQKJhuEcnAVA3t7WE+ug6A=gS6VX1bFhSKTFbaLh"

***

curl -X POST -H "Accept: */*" -H "Accept-Encoding: gzip, deflate" -H "Content-Type: application/x-www-form-urlencoded" --data "user=admin&password=switch818" http:/192.168.0.68/goform/login

Get cookie:

curl -X POST -H "Accept: */*" -H "Accept-Encoding: gzip, deflate" -H "Content-Type: application/x-www-form-urlencoded" --data "user=admin&password=switch818" http:/192.168.0.68/goform/login -i | awk -F' ' '/Set-Cookie/{print $2}' | cut -d'=' -f2 | sed 's/;$//'

curl http://192.168.0.68/cgi-bin/control.cgi\?target\=2\&control\=2\&csrftoken\=MNPLb0q4dkcY23iD7 -H "Cookie: WQKJhuEcnAVA3t7WE+ug6A=mnplMA1EOVNyCDTdH"

http://192.168.0.68/cgi-bin/control.cgi?target=2&control=2

curl https://192.168.0.68/cgi-bin/control2.cgi?user=admin&passwd=switch818&target=2&control=1

***

curl http://192.168.0.68/index.asp -H "Cookie: WQKJhuEcnAVA3t7WE+ug6A=mnplMA1EOVNyCDTdH"


***

curl http://192.168.0.68/cgi-bin/control.cgi\?target\=2\&control\=2\&csrftoken\=Bl5Up8FcFE3U4J65c -H "Cookie: WQKJhuEcnAVA3t7WE+ug6A=bWFu0IfNfeDuEjGFN"
curl http://192.168.0.68/cgi-bin/control.cgi\?target\=2\&control\=2\&csrftoken\=8WR0RUWTguiKVRyr3

http://192.168.0.68/cgi-bin/control.cgi?target=1&control=2&csrftoken=MNPLb0q4dkcY23iD7