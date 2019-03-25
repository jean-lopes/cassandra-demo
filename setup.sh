#!/bin/bash
cd backend
mvn clean
mvn install
cd ../frontend
npm install
cd ..

