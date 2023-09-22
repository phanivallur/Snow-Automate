#!/bin/bash
_version=1.0
set -x


while getopts :hci:s:up PARAM 2>/dev/null
do
	case ${PARAM} in

		h) 
			_usage $0
			;;
		c)
			CONSOLE_LOG=yes
			;;
		i) 
			INSTANCE=$OPTARG
			;;
		u) 
			USER=$OPTARG
			;;
		p)
			PASS=$OPTARG
			;;
		s)      
			SOURCE_ID=$OPTARG
			;;
		\?)
			echo "unrecognized option: ${PARAM}"
			_usage $0
			;;
	esac
done


SCR_FILENAME=$(basename $0)
SCR_NAME="${SCR_FILENAME%.*}"
LOGDIR=${SCR_NAME}
NOW=$(date +"%F-%H%M%S")
OLD_LOG_COUNT=$(find ${LOGDIR} -type f -name "*.log" | wc -l)
if [[ ${OLD_LOG_COUNT} -gt 0 ]]
then
	while read log_file
	do
		gzip -f ${log_file}
	done< <(find ${LOGDIR} -type f -name "*.log")
fi
LOGFILE=${LOGDIR}/${SCR_NAME}_${NOW}.log
CONSOLE_LOG=no
mkdir -p $LOGDIR || { echo "Could not create $LOGDIR"; exit 1; }
echo "All output will be available in $LOGFILE"
if [ ! -f LOGFILE ]
then
	touch ${LOGFILE}
fi

function log_it(){
	if [ "$CONSOLE_LOG" = "yes" ]
	then
		echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"
	else
		echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >> "${LOGFILE}" 2>&1
	fi
	return 0	
	}

function find_dbinfo(){
	local instance_name=$1
	RUCKUS_DB_OUTPUT=${LOGDIR}/ruckus_db_output.log
	if [ ! -f RUCKUS_DB_OUTPUT ]
	then
		touch ${RUCKUS_DB_OUTPUT}
	fi
	ruckus -b ${instance_name} d >> "${RUCKUS_DB_OUTPUT}" 2>&1
	java -jar rid.jar ${RUCKUS_DB_OUTPUT} ${instance_name}
}

function list_db_logs(){
	local instance_db=$1
	local instance_name=$2
	RUCKUS_DB_LISTLOGS_OUTPUT=${LOGDIR}/ruckus_db_listlogs_output.log
	if [ ! -f RUCKUS_DB_LISTLOGS_OUTPUT ]
	then
		touch ${RUCKUS_DB_LISTLOGS_OUTPUT}
	fi
	bssh $instance_db --run-command "pbrun -p snow mysql-listlogs ${instance_name}" >> "${RUCKUS_DB_LISTLOGS_OUTPUT}" 2>&1
	java -jar rid.jar ${RUCKUS_DB_LISTLOGS_OUTPUT} ${instance_name}
}

function find_oti_sys_id(){
	local instance_name=$1
	local staging_row_sys_id=$2
	OTI_LISTING_OUTPUT=${LOGDIR}/oti_api_query_result.log
	if [ ! -f OTI_LISTING_OUTPUT ]
	then
		touch ${OTI_LISTING_OUTPUT}
	fi
	java -jar sgcjar/sgc.jar ${instance_name} ${staging_row_sys_id} > ${OTI_LISTING_OUTPUT}
	echo "done writing to logfile"
}


function Main(){
     

     #process single import set row 
     
       	
     #fetch output_target_item
     #echo ${INSTANCE}"+"${SOURCE_ID}  
     find_oti_sys_id ${INSTANCE} ${SOURCE_ID} || log_it "Cannot find output target item"
     #echo ${record_sys_id}


     #fetch db for the instance
     #instance_db=`find_dbinfo  ${INSTANCE}|| log_it "Cannot find database information for the instance"`
     #echo ${instance_db}

     #list db logs
     #`list_db_logs ${instance_db} ${INSTANCE}
}
Main
exit $?
