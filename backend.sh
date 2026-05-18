#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
mkdir -p $LOGS_FOLDER #folder will be created if not created
LOG_FILE=$(echo $0 | cut -d "." -f1)  #mysql
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE() { 
    if [ $1 -ne 0 ]
    then 
        echo -e "$2 ... $R failure $N"
        exit 1
    else 
        echo -e "$2 ... $G success $N"
    fi
}

CHECK_ROOT()
{
    if [ $USERID -ne 0 ]
    then
        echo "Error: you must have sudo access to execute the script"
    exit 1
    fi
}

echo "Script started executing at: $TIMESTAMP" &>> $LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>> $LOG_FILE_NAME
VALIDATE $? "Disabling existing default nodejs"

dnf module enable nodejs:20 -y &>> $LOG_FILE_NAME
VALIDATE $? "Enabling the nodejs"

dnf install nodejs -y &>> $LOG_FILE_NAME
VALIDATE $? "Installing the nodejs"

id expense &>> $LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense &>> $LOG_FILE_NAME
    VALIDATE $? "Adding expense user"
else
    echo -e "User expense already exists ... $Y SKIPPING $N"
fi

mkdir -p /app &>> $LOG_FILE_NAME
VALIDATE $? "creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>> $LOG_FILE_NAME
VALIDATE $? "downloading the backend code"

cd /app

unzip /tmp/backend.zip &>> $LOG_FILE_NAME
VALIDATE $? "unzipping the backend code"

npm install &>> $LOG_FILE_NAME
VALIDATE $? "Installing the dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>> $LOG_FILE_NAME
VALIDATE $? "installing mysql client"

mysql -h mysql.rushhav.fun -uroot -pExpenseApp@1 < /app/schema/backend.sql &>> $LOG_FILE_NAME
VALIDATE $? "setting up the transaction schema and tables"

systemctl daemon-reload &>> $LOG_FILE_NAME
VALIDATE $? "daemon reload"
 
systemctl enable backend &>> $LOG_FILE_NAME
VALIDATE $? "enabling the backend"

systemctl start backend &>> $LOG_FILE_NAME
VALIDATE $? "starting backend"



