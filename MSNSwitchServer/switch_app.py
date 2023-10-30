from flask import Flask, render_template
import requests
import argparse
from bs4 import BeautifulSoup

app = Flask(__name__)

data = {
    'user': 'admin',
    'password': 'switch818'
}

switchOne = 0
switchTwo = 0

def control_switch(target, control):
    control_url = f'http://{args.ip}/cgi-bin/control.cgi?target={target}&control={control}&csrftoken={csrf_token}'
    print(control_url)
    control_response = requests.get(control_url, headers={'Cookie': set_cookie_header})
    print(control_response.text)

# example: curl http://192.168.0.68/cgi-bin/control.cgi\?target\=2\&control\=2\&csrftoken\=Bl5Up8FcFE3U4J65c -H "Cookie: WQKJhuEcnAVA3t7WE+ug6A=bWFu0IfNfeDuEjGFN"
@app.route("/switchOne/toggle")
def switchOneToggle():
    global switchOne, switchTwo
    switchOne = (switchOne + 1) % 2
    control_switch(1, 2)
    templateData = {
        'switchOne': 'On' if switchOne else 'Off',
        'switchTwo': 'On' if switchTwo else 'Off',
    }
    return render_template('index.html', **templateData)


@app.route("/switchOne/on")
def switchOneOn():
    global switchOne, switchTwo
    switchOne = 1
    control_switch(1, 1)
    templateData = {
        'switchOne': 'On' if switchOne else 'Off',
        'switchTwo': 'On' if switchTwo else 'Off',
    }
    return render_template('index.html', **templateData)

@app.route("/switchOne/off")
def switchOneOff():
    global switchOne, switchTwo
    switchOne = 0
    control_switch(1, 0)
    templateData = {
        'switchOne': 'On' if switchOne else 'Off',
        'switchTwo': 'On' if switchTwo else 'Off',
    }
    return render_template('index.html', **templateData)

@app.route("/switchTwo/toggle")
def switchTwoToggle():
    global switchOne, switchTwo
    switchTwo = (switchTwo + 1) % 2
    control_switch(2, 2)
    templateData = {
        'switchOne': 'On' if switchOne else 'Off',
        'switchTwo': 'On' if switchTwo else 'Off',
    }
    return render_template('index.html', **templateData)


@app.route("/switchTwo/on")
def switchTwoOn():
    global switchOne, switchTwo
    switchTwo = 1
    control_switch(2, 1)
    templateData = {
        'switchOne': 'On' if switchOne else 'Off',
        'switchTwo': 'On' if switchTwo else 'Off',
    }
    return render_template('index.html', **templateData)


@app.route("/switchTwo/off")
def switchTwoOff():
    global switchOne, switchTwo
    switchTwo = 0
    control_switch(2, 0)
    templateData = {
        'switchOne': 'On' if switchOne else 'Off',
        'switchTwo': 'On' if switchTwo else 'Off',
    }
    return render_template('index.html', **templateData)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Send a GET request to a URL with a customizable IP address.")
    parser.add_argument("ip", help="IP address to customize the URL")
    args = parser.parse_args()

    login_url = f'http://{args.ip}/goform/login'
    headers = {
        'Accept': '*/*',
        'Accept-Encoding': 'gzip, deflate',
        'Content-Type': 'application/x-www-form-urlencoded',
    }
    responseCookie = requests.post(login_url, data=data, stream=True, headers=headers)
    set_cookie_header = responseCookie.headers.get('Set-Cookie')

    # example: curl -X POST -H "Accept: */*" -H "Accept-Encoding: gzip, deflate" -H "Content-Type: application/x-www-form-urlencoded" --data "user=admin&password=switch818" http:/192.168.0.68/goform/login -i | awk -F' ' '/Set-Cookie/{print $2}' | cut -d'=' -f2 | sed 's/;$//'
    # Send a GET request to the web page
    home_url = f'http://{args.ip}/index.asp'
    response = requests.get(home_url, headers={'Cookie': set_cookie_header})

    # Check if the request was successful
    if response.status_code == 200:
        # Parse the HTML content of the page
        soup = BeautifulSoup(response.text, 'html.parser')

    # Find the CSRF token by inspecting the page source
    csrf_token = soup.find('input')['value']

    app.run(host='0.0.0.0', port=80, debug=True)