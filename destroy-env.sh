#!/bin/bash

#getting the value of running instances
instance_id_running=`aws ec2 describe-instances --filters "Name=instance-state-code,Values=16" --query 'Reservations[*].Instances[].InstanceId'`

echo $instance_id_running

#getting the value of instances launched using client token
instance_id=`aws ec2 describe-instances --filters "Name=client-token,Values=$1" --query 'Reservations[*].Instances[].InstanceId'`

echo $instance_id

#detach load balancer from autoscaling group
aws autoscaling detach-load-balancers --load-balancer-names lb-itmo-544 --auto-scaling-group-name webservercap

#detach instances from autoscaling group
aws autoscaling detach-instances --instance-ids $instance_id --auto-scaling-group-name webservercap --should-decrement-desired-capacity

#set desired capacity of autoscaling group to zero
aws autoscaling set-desired-capacity --auto-scaling-group-name webservercap --desired-capacity 0

#deregistering instances from load balancer
aws elb deregister-instances-from-load-balancer --load-balancer-name lb-itmo-544 --instances $instance_id

#destroy load balancer
aws elb delete-load-balancer --load-balancer-name lb-itmo-544

#terminate instances from load balancer
aws ec2 terminate-instances --instance-ids $instance_id

#wait
aws ec2 wait instance-terminated --instance-ids $instance_id

aws ec2 wait instance-terminated --instance-ids $instance_id_running

#delete autoscaling group
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name webservercap

#delete launch configuration
aws autoscaling delete-launch-configuration --launch-configuration-name webserver
