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