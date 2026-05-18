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

dnf install nginx -y &>> $LOG_FILE_NAME
VALIDATE $? "Installing nginx"

systemctl enable nginx &>> $LOG_FILE_NAME
VALIDATE $? "enabling nginx server"

systemctl start nginx &>> $LOG_FILE_NAME
VALIDATE $? "starting nginx"

rm -rf /usr/share/nginx/html/* &>> $LOG_FILE_NAME
VALIDATE $? "Removing the existing content"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>> $LOG_FILE_NAME
VALIDATE $? "Downloading the code"

cd /usr/share/nginx/html
VALIDATE $? "Moving to html directory"

unzip /tmp/frontend.zip &>> $LOG_FILE_NAME
VALIDATE $? "Unzipping the code"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf

systemctl restart nginx &>> $LOG_FILE_NAME
VALIDATE $? "Restarting nginx"




