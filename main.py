"""Small example OSC client From a Flask APP
   Since I couldnt put it on LOVR side, stupid!

This program sends 10 random values between 0.0 and 1.0 to the /filter address,
waiting for 1 seconds between each value.
"""
import argparse
import random
import time

from pythonosc import udp_client
from flask import Flask

app = Flask(__name__)
args = None
osc_client = None


@app.route("/pythonOSC/1/<int:note>/<float:intensity>")
def sendOSC(note, intensity):
    # client.send_message("/myChucK/OSCNote", [random.randint(48, 60), 0.4, "hello"])
    osc_client.send_message("/myChucK/OSCNote", [note, intensity, "hello1"])
    print(f" Note - {note},  Intensity - {intensity}")
    return "Sent OSC message!"

@app.route("/pythonOSC/2/<int:note>/<float:intensity>")
def sendOSC2(note, intensity):
    # client.send_message("/myChucK/OSCNote", [random.randint(48, 60), 0.4, "hello"])
    osc_client2.send_message("/myChucK/OSCNote", [note, intensity, "hello2"])
    print(f" Note2 - {note},  Intensity - {intensity}")
    return "Sent OSC message!"

@app.route("/pythonOSC/3/<int:note>/<float:intensity>")
def sendOSC3(note, intensity):
    # client.send_message("/myChucK/OSCNote", [random.randint(48, 60), 0.4, "hello"])
    osc_client3.send_message("/myChucK/OSCNote", [note, intensity, "hello3"])
    print(f" Note3 - {note},  Intensity - {intensity}")
    return "Sent OSC message!"

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ip", default="127.0.0.1", help="The ip of the OSC server")
    parser.add_argument(
        "--port", type=int, default=5005, help="The port the OSC server is listening on"
    )
    args = parser.parse_args()
    osc_client = udp_client.SimpleUDPClient(args.ip, args.port)
    osc_client2 = udp_client.SimpleUDPClient(args.ip, 5007)
    osc_client3 = udp_client.SimpleUDPClient(args.ip, 5008)

    app.run(host="0.0.0.0", port=5006, threaded=True, debug=True)

#   for x in range(10):
#     client.send_message("/myChucK/OSCNote", random.random())
#     time.sleep(1)
