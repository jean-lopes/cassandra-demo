#!/bin/bash
docker-compose up -d
cd frontend
elm-live src/Main.elm --start-page index.html --pushstate --open -- --output=elm.js

