# Purpose

To prepare to run SMG managed EC2 instances in an aws account.
This terraform creates a programmatic user that has the access
required to launch EC2 instances and have automated snapshots
taken to provide some capability for disaster data recovery.


# Prerequisites

AWS account with enterprise VPC and IPAM managed IPv4 space.
SMG currently supports just the us-east-2 region and campus
facing subnets. Other variations are possible if there 
is a business case for doing so.

# Instructions

Run the terraform and send SMG the access key and secret
along with the AWS account id and subnets you wish to use
to run your ec2 instances. SMG will add this information to its
infrastructure metadata so hosts can be requested on the
new subnet(s).


# References

[AWS Enterprise VPC IAC](https://github.com/techservicesillinois/aws-enterprise-vpc/)
[AWS VPC Guide](https://answers.illinois.edu/illinois/page.php?id=71015)
