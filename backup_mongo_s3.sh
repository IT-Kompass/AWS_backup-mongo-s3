#!/bin/bash
#MongoDB User
MongoUser="<<FillMe>>"
#MongoDB Password
MongoPassword="<<FillMe>>"
#AWS S3 Bucket for Backup
TargetBucket="<<FillMe>>"
#Prefix for Filename as Date
FileName=$(date '+%Y-%m-%d_%H-%M-%S')
#Dir for Exports !! ending with /!!
Dir=/data/export/
#Skip admin,config,local DBs
SkipAdminDBs="true"

#Regex for getting sizes of DBs.
RegEx="^[^a-z][.0-9]*.[.0-9][.0-9][.0-9]GB"
#Does export folder exist? If not create it!
if [[ ! -e $Dir ]]; then
    mkdir $Dir
fi
#Getting DB list from MongoDB
DBs=$(
    mongo -u $MongoUser -p $MongoPassword --authenticationDatabase admin --quiet <<EOF
show dbs
quit()
EOF
)

#Init counter variable
i=0

#Loop through all DBs
for DB in ${DBs[*]}; do
    i=$(($i + 1))
    #Filter Sizes of DBs (x.xxxGB)
    if ! [[ $DB =~ $RegEx ]]; then
        #Filter not active so export everything.
        if [ $SkipAdminDBs = "false" ]; then
            #Exporting all DBs incl. admin and config
            mongodump --archive=$Dir$FileName"_"$DB --host localhost:27017 --db $DB -u $MongoUser -p $MongoPassword --tlsInsecure --authenticationDatabase=admin --gzip

        elif [ $SkipAdminDBs = "true" ]; then
            #If SkipAdminDB is set to "true" and DB is neither "admin" nor "config" nor "local"
            if ! { [ $DB = "config" ] || [ $DB = "admin" ] || [ $DB = "local" ]; }; then
                mongodump --archive=$Dir$FileName"_"$DB --host localhost:27017 --db $DB -u $MongoUser -p $MongoPassword --tlsInsecure --authenticationDatabase=admin --gzip
            fi
        fi
    fi
done
#Upload to S3
aws s3 cp --recursive $Dir/ s3://$TargetBucket/
#Cleanup the exports
rm -f $Dir/*
