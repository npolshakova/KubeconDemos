import time
from rpi_ws281x import PixelStrip, Color
from flask import Flask, render_template
app = Flask(__name__)

# LED strip configuration:
LED_COUNT = 50        # Number of LED pixels.
LED_PIN = 18          # GPIO pin connected to the pixels (18 uses PWM!).
LED_FREQ_HZ = 800000  # LED signal frequency in hertz (usually 800khz)
LED_DMA = 10          # DMA channel to use for generating signal (try 10)
LED_BRIGHTNESS = 100  # Set to 0 for darkest and 255 for brightest
LED_INVERT = False    # True to invert the signal (when using NPN transistor level shift)
LED_CHANNEL = 0       # set to '1' for GPIOs 13, 19, 41, 45 or 53

colors = [ Color(0, 0, 0), Color(0, 255, 0), Color(255, 0, 0) ]
color_index = 0

strip = PixelStrip(LED_COUNT, LED_PIN, LED_FREQ_HZ, LED_DMA, LED_INVERT, LED_BRIGHTNESS, LED_CHANNEL)

@app.route("/")
def index():
    templateData = {
        'r': colors[color_index].r,
        'g': colors[color_index].g,
        'b': colors[color_index].b,
    }
    return render_template('led.html', **templateData)

@app.route("/switch")
def action():
    global color_index

    color_index = (color_index + 1) % 3

    for i in range(strip.numPixels()):
        strip.setPixelColor(i, Color(255, 0, 0))
        #strip.setPixelColor(i, colors[color_index])
    strip.show()

    templateData = {
        'r': colors[color_index].r,
        'g': colors[color_index].g,
        'b': colors[color_index].b,
    }

    return render_template('led.html', **templateData)

if __name__ == "__main__":
    # Initialize library before calling other functions
    strip.begin()
    app.run(host='0.0.0.0', port=80, debug=True)
