# SAT-Comp Cloud Track Instructions


Prerequisites: To run this example, you will need the following tools installed:
- python3
- awscli
- boto3


The goal of the SAT-Comp Cloud Track infrastructure is to make it straightforward to build solvers that will be used in the SAT-Comp competition, and to run them at scale on Amazon Web Services (AWS) resources.

Preparing tools and testing them involves four phases, which will be described in greater detail later on in the document:

1. Creation of a test AWS Account for building your solver and running limited-scale experiments.
2. Creating an ECS cluster where your solver will be run
3. Sharing your tools with us to run tests at scale

This project provides some sample code to set up your account and test your solver.

For each step, we have a CloudFormation template that can be used to set up the account for use with minimal effort.  
These files are available in the github project at: https://github.com/aws-samples/aws-batch-comp-infrastructure-sample (which also contains this README file).
CloudFormation is AWS&#39;s approach to &quot;infrastructure as code&quot;, and it allows bulk creation of AWS resources using a relatively straightforward (if verbose) YAML format to construct resources.  
It is not necessary that teams become expert CloudFormation users, but some understanding of the rudiments of CloudFormation are useful.  
See: [https://aws.amazon.com/cloudformation/](https://aws.amazon.com/cloudformation/) for information and a tutorial on CloudFormation.  
At each stage, we will tell you how to invoke CloudFormation to install resources into the account.

Parallel solvers are constructed by running multiple copies of a single Docker image that can communicate with one another using IP, TCP, SSH, or any number of higher-level protocols such as MPI.  We provide a Docker container image that by default has support for the use of MPI over SSH.

The containers will be hosted in an ECS cluster. See [https://aws.amazon.com/ecs/] for more details

When solvers are stable, we will use the scripts and github information to build the solver and run tests at scale.  This will allow us to report results to you as to how well the solver is performing on a set of test benchmarks when running at scale.

## Creating the Test Account

Please create a &quot;fresh&quot; account in order to simplify billing for the account.  If you have not created an AWS previously, it is straightforward to do, requiring a cell phone #, credit card, and address.  Please navigate to aws.amazon.com and follow the instructions on the web site to create an account.

If you have already created an account based on your email address, please create a separate AWS account for managing the SAT-Comp tool construction and testing.  This makes it straightforward for us to manage account credits and billing.   **Once the account is created please email us the account number at sat-comp-2022@amazon.com** so that we can apply credits to your account.
To find your account ID, click on your account name in the top right corner, and then click "My Account". You should see Account ID in the Account Settings



**N.B.:** It is very important that you tell us your account number immediately after creating the account, so that we 
can assign you a resource budget for your experiments. We also need to grant you access to the shared problem set which is in a separate S3 bucket.
Once we hear from you, we will email you in acknowledgement that the accounts have been set up with resources. 



### Installing the AWS CLI.

In order to work with AWS, you must install the AWS CLI for your platform.

To use the AWS CLI, please follow the directions for your operating system here:
  [https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)

When setting up an account, we recommend the use of named profiles as they allow some flexibility in later connecting to multiple accounts:
  [https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)
  
Once you have installed AWS CLI, to get the named profiles working, you should create (or modify) a ~/.aws/config file that
looks like has this:

    [profile PROFILE-NAME]
    region=us-east-1
    account=ACCOUNT-ID

where the PROFILE-NAME is any name you would like to use, and the ACCOUNT-ID is your account ID that got in the previous section.
Examples of valid regions are us-east-1 (N. Virginia), us-west-2 (Oregon), eu-west-2 (London), etc...

We also need to set up credentials to access the account. For the purposes of making the competition simple, we will use the root level
access key. This is NOT the best practice, which would be to create a user but it will suffice for the competition. If you continue
using the account beyond the competition, we recommend that you follow AWS best practices as described here:
    [https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users)
    
To create a root level access key, click services, and then type "IAM" into the search bar and click the resulting link. 
On the Identity and Access Management page, click on "Delete your root access keys" and then choose "My Security Credentials" from the account drop down menu on the top right of the screen.

Then click on "Access keys (access key ID and secret access key)" and then "Create New Access Key", and then "Show Access Key"
This will give you an Acess Key ID and a Secret Access Key.

Create a ~/.aws/credentials file with the following:

    [PROFILE-NAME]
    aws_access_key_id=ACCESS_KEY_ID
    aws_secret_access_key=ACCESS_KEY


After installing the AWS CLI and gaining credentials, make sure that the CLI is installed properly by attempting to run an AWS command.  An example command that should work is:

aws --profile [YOUR PROFILE NAME HERE] s3api list-buckets

If it does not work, see the troubleshooting section at the bottom of this document.

## Account Setup

### Note that any charges that accrue in your account beyond the AWS credits provided for the competition are your responsibility!  Please monitor your account carefully.  

We will use CloudFormation to do a basic account setup.  The account-setup.yaml script is an optional cloudformation script that can help you track your spending.  It will set up notification emails to be sent to an email address you provide when the account reaches 20%, 40%, 60%, 80%, and 100% of the monthly account budget so that you have a window into the current spend rate for building and testing your solver.  

Here is the command to run it:

    aws --profile [YOUR PROFILE NAME HERE] cloudformation create-stack --stack-name setup-account-stack --template-body file://setup-account.yaml --parameters ParameterKey=emailAddress,ParameterValue=[ENTER EMAIL ADDRESS HERE]

Be sure to double check the email address is correct!

The --profile argument should be the profile associated with the account, and the emailAddress parameter is the email address that notification messages related to budgeting and account spending will be sent.

After running the aws cloudformation command, you can monitor the installation process from the CloudFormation console  [console.aws.amazon.com/cloudformation](console.aws.amazon.com/cloudformation). 
Log into your AWS account and navigate to the CloudFormation console. Make sure you are in the region you chose in your profile (Region is selected in the top right corder)  
You should see a stack named &quot;setup-account-stack&quot;.

 ![](cloudformation.png)
_Figure 1: Cloudformation result_

By clicking on this stack, and choosing &quot;events&quot;, you can see the resources associated with the stack.  After a short time, you should see the &quot;CREATE\_SUCCEEDED&quot; event.   If not (e.g., the email address was not valid email address syntax), you will see a &quot;CREATE\_FAILED&quot; event.  In this case, delete the stack and try again.  If you have trouble, please email us at: [sat-comp-2022@amazon.com](mailto:sat-comp-2022@amazon.com) and we will walk you through the process.

Although it is handy to get emails when certain account budget thresholds have been met, it is both useful and important to check by-the-minute account spending on the console: [https://console.aws.amazon.com/billing/home](https://console.aws.amazon.com/billing/home).

## Building the Solver and Storing it in ECS

Solvers should be buildable from source code using a standard process.  It is expected that you will provide a GitHub repo that has a Dockerfile in the top directory. We have provided the following Github repo as an example: https://github.com/aws-samples/aws-batch-mallob-sample.

The process is to first create an Elastic Container Repository (ECR) for the solver in the AWS account that you set up previously.  The command to create a repository is as follows: 

	aws --profile [YOUR PROFILE NAME HERE] ecr create-repository --repository-name [PROJECT_NAME]

Where `PROJECT_NAME` is the name of the repository.  **N.B.:** `PROJECT_NAME` must start with a letter and can only contain lowercase letters, numbers, hyphens (-), underscores (_), and forward slashes (/).

Once you have created a repository, it is possible to push a docker image into the repository from your local machine using the procedure described here: [https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html).  

If you have trouble, please email us at: [sat-comp-2022@amazon.com](mailto:sat-comp-2022@amazon.com) and we will walk you through the process.


## Building the ECS cluster that will run the solver

The next step is to build the Batch environment that will run the solver.  This is relatively straightforward, and a script is provided to construct the batch environment.

The batch environment is designed to allow testing at small scale, and consists of four 16-core machines.  This should be sufficiently large to allow testing that the communication between containers works properly and that parallel solving is working, but not so large as to become expensive for testing.  For large-scale testing, we ask that, after the solver is stable, you provide us with links to the repository/S3, and we will run your solver at large-scale.

To set up the batch pipeline, run the job-queue.sh file:

    ./build-job-queue.sh PROFILE REGION PROJECT_NAME INSTANCE_TYPE INSTANCE_AMI
where:
   PROFILE is a AWS CLI profile with administrator access to the account**

**   PROJECT\_NAME is the name of the project.  MUST BE ALL LOWERCASE.**

** The INSTANCE_TYPE is the machine you want to run on. For the cloud track, this should be m4.4xlarge, and for parallel track it should be m4.16xlarge 

** INSTANCE_AMI To get the instance AMI, please go to https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html and select the Amazon Linux 2 AMI for your region. These are both region specific and are updated frequently which is why we cannot give a default.

**      Regular expression for names is:**

**      (?:[a-z0-9]+(?:[.\_-][a-z0-9]+)\*/)\*[a-z0-9]+(?:[.\_-][a-z0-9]+)\*&quot;**

PROJECT\_NAME must be the same name that you used earlier for the build-solver-pipeline script.


     
Once again, monitor the creation of resources from the script by navigating to the CloudFormation console.



## Running the Solver

To run the solver, we have to point it at a test directory and pass in arguments.  The solver will run in AWS Batch as a multi-node parallel job: [https://docs.aws.amazon.com/batch/latest/userguide/multi-node-parallel-jobs.html](https://docs.aws.amazon.com/batch/latest/userguide/multi-node-parallel-jobs.html)

This approach allocates resources for parallel execution, sets up a &#39;leader node&#39; with an IP address that is started first.  Once executing, a set of &#39;worker nodes&#39; is started, and the IP address of the leader node is passed to all worker nodes, so that they can communicate back to the leader node.

The infrastructure we are using to run the examples is EC2 clusters managed using ECS. 
In order to use this cluster, you will have to explicitly spin up EC2 instances.

Since you will now be responsible for spinning up and down your own instances, if you want to run an experiment, you will have to manually modify your cluster to include the number of instances you need, and then manually spin it down. 

__IMPORTANT!!!: If you do not spin down your cluster, you will be responsible for the cost of accidentally leaving instances running__
 
To control the instances in your cluster, go to the ECS console and click on the SatCompCluster. Then click the tab that says ECS Instances and click the link that says “Auto Scaling”.
 In the list, you will see an autoscaling group called something like job-queue-PROJECT_NAME-EcsInstanceAsg-.... 
 Select that, and click Edit. 
 Set the Desired Capacity __and__ Maximum Capacity to 2 (or however many instances you need). 
 When you are finished you experiment, please set these values back to 0.
 
Please allow 2-3 minutes for the instances to boot up and register with the cluster. 
If you get the following error, it means that your instances have not yet booted up:

    An error occurred (InvalidParameterException) when calling the RunTask operation: No Container Instances were found in your cluster.
     
If they fail to boot up after 5 minutes, please verify that both Desired Capacity and Maximum Capacity are set correctly.
 
You will incur costs for the time the machines are running.

__Do not forget to spin down the cluster when it is not in use!!!__
### run_example.py

TODO: this section is no longer accurate and needs replacing.



### Monitoring and Logging

The ECS console allows you to monitor the logs of all running tasks. For information about the ECS console please refer to the documentation: https://aws.amazon.com/ecs/

## Example

We have an example repository with a Dockerfile that builds and runs Mallob in the following git repo: https://github.com/aws-samples/aws-batch-mallob-sample



## Troubleshooting

TBD
