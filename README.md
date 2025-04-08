Point 1: 
a. To setup and run the Infrastructure, first fork this repository.
b. Update the variable.tf present inside the IaC/modules/aws_machine. Pass your IAM user access and secret key and your email address for SNS (Simple Notification Service) alert for CPU and Memory utlization of the EC2.
c. Update the Jenkinfile file in the root directory with your docker username and password in the parameter block. This is done so that when the Pipeline is triggered; the docker credentials will be updated/altered in the setHostDep.sh which will be used by remote-exec provider to install packages and deploy the container.  

Point 2: 
a. The deployment pipeline will poll the main branch every 5 mins to check if any new commits are made, if the Jenkins server detects the change the pipeline will be triggered.
Note: We can use githubPush() triggers for sending push events to Jenkins server to trigger the pipeline, but for that a webhook needs to be created. For this implementation we will be using polling trigger.

Point 3:
a. For monitoring we are using CloudWatch; through the Terraform configuration we are creating two alarms for memory and CPU utlization and SNS is enabled to alert the user about the flask application usage.
b. This implematation uses providers like remote-exec and file for configuration management capabilities rather than using ansible playbooks.

Point 4:
a. This Infrastructure is not in a virtual private cloud (VPC), for better security it is recommended to setup the compute machine in a VPC with NAT attached to it or in VPC and bastion host for accessing the private IP of the EC2. The costing needs to be considered for that.
