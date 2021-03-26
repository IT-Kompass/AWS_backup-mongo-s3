#!/bin/bash

user=<<fillme>>
password=<<fillme>>
targetbucket=<<fillme>>
filename=`date '+%Y-%m-%d_%H-%M-%S'`
dir=/data/export

if [[ ! -e $dir ]]; then
    mkdir $dir
fi
dbs=$(mongo -u $user -p $password --authenticationDatabase admin --quiet <<EOF
show dbs
quit()
EOF
)
i=0
for db in ${dbs[*]}
do
    i=$(($i+1))
    if (($i % 2)); then
        mongodump --archive=$dir"/"$filename"_"$db --host localhost:27017 --db $db -u $user -p $password --tlsInsecure --authenticationDatabase=admin --gzip
    fi
done
aws s3 cp --recursive $dir/ s3://$targetbucket/
rm -f $dir/*
