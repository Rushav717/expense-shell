#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
mkdir -p $LOGS_FOLDER

LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
if [ $1 -ne 0 ]
then
    echo -e "$2 is..... $R FAILURE $N"
    exit 1
else
    echo -e "$2 is..... $G SUCCESS $N"
fi
}

CHECK_ROOT()
{
if [ $USERID -ne 0 ]
then
    echo "ERROR:: required sudo access to execute this script"
    exit 1
fi
}

echo "Script started executing at:: $TIMESTAMP" &>> $LOG_FILE_NAME

CHECK_ROOT

dnf install nginx -y &>> $LOG_FILE_NAME
VALIDATE $? "Installing nginx server"

systemctl enable nginx &>> $LOG_FILE_NAME
VALIDATE $? "Enabling the nginx server"

systemctl start nginx &>> $LOG_FILE_NAME
VALIDATE $? "Starting the nginx server"

rm -rf /usr/share/nginx/html/* &>> $LOG_FILE_NAME
VALIDATE $? "removing existing version of code"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>> $LOG_FILE_NAME
VALIDATE $? "downloading latest code"

cd /usr/share/nginx/html
VALIDATE $? "moving to html directory"

unzip /tmp/frontend.zip &>> $LOG_FILE_NAME
VALIDATE $? "unzipping the frontend code"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf

systemctl restart nginx &>> $LOG_FILE_NAME
VALIDATE $? "restarting the nginx"