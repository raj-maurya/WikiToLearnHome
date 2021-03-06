#!/bin/bash
. ./load-libs.sh

BACKUP_DIR=$WTL_BACKUPS"/"$(date +'%Y_%m_%d__%H_%M_%S')"_quick"

test -d $BACKUP_DIR || mkdir $BACKUP_DIR

wtl-event BACKUP_STARTED ${WTL_INSTANCE_NAME}

rsync -a --stats --delete $WTL_WORKING_DIR"/mediawiki/images/" ${BACKUP_DIR}"/images/"

for db in $(docker exec -ti ${WTL_INSTANCE_NAME}-mysql mysql -e "SHOW DATABASES" | grep wikitolearn | awk '{ print $2 }') ; do
 wtl-event BACKUP_QUICK_DB $db
 BACKUP_FILE=$BACKUP_DIR"/"$db
 BACKUP_FILE_STRUCT=$BACKUP_FILE".struct.sql"
 BACKUP_FILE_DATA=$BACKUP_FILE".data.sql"

 docker exec -ti ${WTL_INSTANCE_NAME}-mysql mysqldump --skip-add-drop-table --skip-comments -d $db > $BACKUP_FILE_STRUCT
 sed -i 's/CREATE TABLE/CREATE TABLE IF NOT EXISTS/g' $BACKUP_FILE_STRUCT

 docker exec -ti ${WTL_INSTANCE_NAME}-mysql mysqldump --no-create-info $db    > $BACKUP_FILE_DATA
done

rsync -a --stats --delete $WTL_WORKING_DIR"/mediawiki/images/" ${BACKUP_DIR}"/images/"

wtl-event BACKUP_FINISHED ${WTL_INSTANCE_NAME}
