#!/bin/bash

openssl req -x509 -newkey rsa:2048 -keyout private.key -out cert1.pem -days 1 -subj "/C=PL/ST=ExampleState/L=ExampleCity/O=ExampleOrg/OU=ExampleUnit/CN=example.com" -nodes

openssl req -x509 -newkey rsa:2048 -keyout private.key -out cert7.pem -days 7 -subj "/C=PL/ST=ExampleState/L=ExampleCity/O=ExampleOrg/OU=ExampleUnit/CN=example.com" -nodes

openssl req -x509 -newkey rsa:2048 -keyout private.key -out cert14.pem -days 14 -subj "/C=PL/ST=ExampleState/L=ExampleCity/O=ExampleOrg/OU=ExampleUnit/CN=example.com" -nodes

openssl req -x509 -newkey rsa:2048 -keyout private.key -out cert30.pem -days 30 -subj "/C=PL/ST=ExampleState/L=ExampleCity/O=ExampleOrg/OU=ExampleUnit/CN=example.com" -nodes