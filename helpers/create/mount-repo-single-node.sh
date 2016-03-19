#!/bin/bash

#Control the existance of docker instances and create them if they are not existing
docker inspect ${WTL_INSTANCE_NAME}-parsoid &> /dev/null
if [[ $? -ne 0 ]] ; then
    docker create -ti $MORE_ARGS --hostname parsoid --name ${WTL_INSTANCE_NAME}-parsoid $WTL_DOCKER_PARSOID
fi

docker inspect ${WTL_INSTANCE_NAME}-mathoid &> /dev/null
if [[ $? -ne 0 ]] ; then
    docker create -ti $MORE_ARGS --hostname mathoid --name ${WTL_INSTANCE_NAME}-mathoid -e NUM_WORKERS=$MATHOID_NUM_WORKERS $WTL_DOCKER_MATHOID
fi

docker inspect ${WTL_INSTANCE_NAME}-memcached &> /dev/null
if [[ $? -ne 0 ]] ; then
    docker create -ti $MORE_ARGS --hostname memcached --name ${WTL_INSTANCE_NAME}-memcached $WTL_DOCKER_MEMCACHED
fi

docker inspect ${WTL_INSTANCE_NAME}-mysql &> /dev/null
if [[ $? -ne 0 ]] ; then
    ROOT_PWD=$(echo $RANDOM$RANDOM$(date +%s) | sha256sum | base64 | head -c 32 )
    docker create -ti $MORE_ARGS -v ${WTL_INSTANCE_NAME}-var-lib-mysql:/var/lib/mysql --hostname mysql --name ${WTL_INSTANCE_NAME}-mysql -e MYSQL_ROOT_PASSWORD=$ROOT_PWD $WTL_DOCKER_MYSQL
fi
    
docker inspect ${WTL_INSTANCE_NAME}-ocg &> /dev/null
if [[ $? -ne 0 ]] ; then    
    docker create -ti $MORE_ARGS -v wikitolearn-ocg:/tmp/ocg/ocg-output/ --hostname ocg --link ${WTL_INSTANCE_NAME}-parsoid:parsoid --name ${WTL_INSTANCE_NAME}-ocg $WTL_DOCKER_OCG
fi

docker inspect ${WTL_INSTANCE_NAME}-websrv &> /dev/null
if [[ $? -ne 0 ]] ; then  
    docker create -ti $MORE_ARGS -v ${WTL_INSTANCE_NAME}-var-log-apache2:/var/log/apache2 --hostname websrv -e USER_UID=$EXT_UID -e USER_GID=$EXT_GID \
        -v $WTL_REPO_DIR:/var/www/WikiToLearn/ \
        --name ${WTL_INSTANCE_NAME}-websrv \
            --link ${WTL_INSTANCE_NAME}-mysql:mysql \
            --link ${WTL_INSTANCE_NAME}-memcached:memcached \
            --link ${WTL_INSTANCE_NAME}-ocg:ocg \
            --link ${WTL_INSTANCE_NAME}-mathoid:mathoid \
            --link ${WTL_INSTANCE_NAME}-parsoid:parsoid \
            $WTL_DOCKER_WEBSRV
fi
            
docker cp ${WTL_CERTS}/wikitolearn.crt ${WTL_INSTANCE_NAME}-websrv:/etc/ssl/certs/apache.crt
if [[ $? -ne 0 ]] ; then
    echo = "unable to copy certificates to the webserver"
    exit1
fi

docker cp ${WTL_CERTS}/wikitolearn.key ${WTL_INSTANCE_NAME}-websrv:/etc/ssl/private/apache.key
if [[ $? -ne 0 ]] ; then
    echo = "unable to copy certificates to the webserver"
    exit1
fi