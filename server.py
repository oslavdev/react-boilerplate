#!/usr/bin/env python

import BaseHTTPServer, SimpleHTTPServer
import ssl
import os

httpd = BaseHTTPServer.HTTPServer(('127.0.0.1', 443), SimpleHTTPServer.SimpleHTTPRequestHandler)
httpd.socket = ssl.wrap_socket(httpd.socket, certfile='https/crt', keyfile='https/key', server_side=True)

web_dir = os.path.join(os.path.dirname(__file__), 'dist')
os.chdir(web_dir)

httpd.serve_forever()
