#!/bin/bash

echo "my Dockercompose has an issue with starting the DB from a unique state. Dockercompose doesn't really support 'depends_on' as it would be expected"
echo "When MySQL starts from a container, it has to initialize a few items. However, DC will start our flask app as soon as the MySQL container is up, NOT when the process is ready to accept connections"
echo "We will just bounce the flask container, as it will start correctly on the second try.  Another alternative would be to use a healthcheck script or a 'wait-for-service' script that starts flask after a set of conditions passes."


docker-compose build

echo "Now the build is complete, let's start up!"  
docker-compose up -d 
#We will sleep a few seconds to allow mySQL to settle
sleep 10

echo "Now that MySQL is set, we can restart Flask"

docker-compose restart flask




