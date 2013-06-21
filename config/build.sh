#!/bin/sh
PATH=$PATH:node_modules/grunt/bin:node_modules/grunt-cli/bin
bundle install --deployment
npm install
grunt package
