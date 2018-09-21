#!/bin/bash
####################################
#
# Backup to network drive via samba client
# bash shell script
#
####################################

# I. Basic data
# Hostname
HOSTNAME=$(hostname -s)
# Backup date
DATE=$(date +%Y%m%d)

#####################################
# II. Path data
# 1. Log path
# a.) Filepath of the backup log
LOGPATH="/var/log/backup/"
# b.) Filename of the backup log
LOGFILE="${DATE}_application_backup_monthly.log"
# c.) Full path of the backup log
BACKUPLOG="${LOGPATH}/${LOGFILE}"
# d.) Filepath of application log
APPLICATIONLOGGPATH="/opt/application/"

# 2. Backup path
# a.) Target network path for backup
SAMBAPATH="//samba/path"
# b.) Target directory
SAMBADIR="monthly_backup"
# c.) Path of blob store to backup
BACKUP_BLOB_PATH="/opt/application/blobs/"
# d.) Path of database to backup
BACKUP_DATABASE_PATH="/opt/application/backup/"
# e.) Files to backup
BACKUP_FILES="${BACKUP_BLOB_PATH} ${BACKUP_DATABASE_PATH}"
#BACKUP_FILES="/usr/local/etc/cronkjobs/backup_monthly.sh"
# f.) Archive target path
DEST="/root/backup"
# g.) Archive target filename.
ARCHIVE_FILE="${DATE}_${HOSTNAME}_backup_monthly.tgz"

########################################
# III. Backup
# 1. Print start status message for starting backup.
echo "---------------------------------------------------------" >> ${BACKUPLOG} 2>&1
echo "I. Archiving ${BACKUP_FILES} to ${DEST}/${ARCHIVE_FILE}"  >> ${BACKUPLOG} 2>&1
date >> ${BACKUPLOG} 2>&1
echo >> ${BACKUPLOG} 2>&1

# 2. Stop application service
echo "---------------------------------------------------------" >> ${BACKUPLOG} 2>&1
echo "II. Stop Application service" >> ${BACKUPLOG} 2>&1
systemctl stop application.service >> ${BACKUPLOG} 2>&1
systemctl status application.service >> ${BACKUPLOG} 2>&1

# 3. Archive the files using tar.
echo "---------------------------------------------------------" >> ${BACKUPLOG} 2>&1
echo "III. tar" >> ${BACKUPLOG} 2>&1
tar czf ${DEST}/${ARCHIVE_FILE} ${BACKUP_FILES} >> ${BACKUPLOG} 2>&1
ls -lh ${DEST} >> ${BACKUPLOG} 2>&1

# 4. Start application service
echo "---------------------------------------------------------" >> ${BACKUPLOG} 2>&1
echo "IV. Start application service" >> ${BACKUPLOG} 2>&1
# rm ${APPLICATIONLOGPATH}/*.log.gz
systemctl start application.service >> ${BACKUPLOG} 2>&1
systemctl status application.service >> ${BACKUPLOG} 2>&1

# 5. Backup the files using smbclient
echo "---------------------------------------------------------" >> ${BACKUPLOG} 2>&1
echo "V. transfer archive to backup server" >> ${BACKUPLOG} 2>&1
smbclient -U user%password ${SAMBAPATH} -D ${SAMBADIR} -c "put ${DEST}/${ARCHIVE_FILE} ${ARCHIVE_FILE}" >> ${BACKUPLOG} 2>&1

# 6. Free space: delete blog archive on server
echo "---------------------------------------------------------" >> ${BACKUPLOG} 2>&1
echo "VI. remove archive from server" >> ${BACKUPLOG} 2>&1
rm ${DEST}/${ARCHIVE_FILE} >> ${BACKUPLOG} 2>&1

# 7. Print end status message.
echo "---------------------------------------------------------" >> ${BACKUPLOG} 2>&1
echo "VII. Backup finished" >> ${BACKUPLOG} 2>&1
date >> ${BACKUPLOG} 2>&1

# 8. Transfer log to  backup server
smbclient -U user%password ${SAMBAPATH} -D ${SAMBADIR} -c "put ${BACKUPLOG} ${LOGFILE}" >> ${BACKUPLOG} 2>&1

# IV. Clean up space
# 9. Free space: delete backup log
find $LOGPATH -type f -mtime +185 -delete

# 10. Free space: delete backup database
find $BACKUP_DATABASE_PATH -type f -mtime +185 -delete
