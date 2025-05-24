#!/bin/bash
 
systemctl start php8.3-fpm
systemctl start apache2
 
#############################################
#  FOR SQS WORKER SUPERVISORD SERVICE START
#############################################
systemctl start supervisord
 
 
 
#############################################
#  SERVICE CHKCONFIG ON
#############################################
chkconfig httpd on
chkconfig php-fpm on
chkconfig supervisord on
