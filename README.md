# Auto Code Deployment from BitBucket Pipelines to AWS EC2
<hr />

Purpose of this readme is to shorten the lengthy task of code committing, testing, building and then deploying on to the server.

There is actually an easier way to do that all. Won't it be nice if one `git push` and done, code is committed to the remote repository as well as built and deployed to your aws ec2 account? 

Following steps might help you to do just that. 


## Getting Started
<hr />

Following are some prerequisites before we can start. 

> Note : This demo is meant for `BitBucket` ONLY and not for gitlab or github. 


### Prerequisites
1. AWS Account (For this demo purpose I am gonna use a free aws account which you can also get for free for 1 year if it's your first time creating one. [Create AWS account](https://aws.amazon.com/account/) 

2. BitBucket account with at least one repository in it.
3. Code Editor (vs code <~~ My choice ).
4. And of course a project ready to be deployed or you can clone this very project (It's nothing fancy , just a simple hello world app in react)


## Setting up AWS environment 

For auto-deployment from bit bucket to AWS is done in three stages 

1. Push the repository code to AWS S3 storage 
2. AWS CodeDeploy will pull the code from s3 and deploy it to an EC2 instance 
3. EC2 instance is where the code will compile , build and will be served.


### Step 1 : Setting Up IAM Account in AWS 

Follow the steps to create a new IAM user which bitbucket will use. 

1. Under "Your Name" menu on top right , select `My Security Credentials`. 
2. Go to `Users` tab and click "Add User"
3. Give an appropriate name.
4. Make sure to check `Programmatic access` and NOT `AWS Management Console access` as these credentials will only be used by bitbucket
5. In `Add user to group` create a new group and from policy list make sure the group has *AmazonS3FullAccess* and *AWSCodeDeployFullAccess* checked. 
Once clicking on the group name , the should look like the following 


6. Make sure the new created group is checked and proceed and click `Create User` on the next page 

7. NOTE : This step is very important as you can do it only once. 
Click on the newly created user's `Secret access key` show. And note that key down because we will need it. note down the Access Id Key as well. 


Now select `Roles` from the left navigation bar

1. Create role , Select `EC2` from the services and `EC2` again in `Select your use case`. 

2. Select *AWSCodeDeployRole* & *AmazonS3FullAccess* from policy list

3. Give a proper name to the role and create role 

4. Select the role which was just created , go to `Trust Relationship` and select 'Edit Trust Relationship' and enter the following in there 

```js 
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com",
                    "codedeploy.us-east-2.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
            }
        ]   
    }
```

Change the region (us-west-2) according to your region. Just check your url in the address bar. it will be something like 

https://console.aws.amazon.com/iam/home?region=`us-east-2`[#/roles/CodeDeployerRole?section=trust](#)


### Step 2 : Setting up S3 Bucket

1. Go to Services and select `S3`. 
2. Create a New Bucket
3. Give a proper Name to it and select a Region. Make sure the region you select is the same as the region you have entered while creating IAM user's role. 
4. Click `Create` and select the created bucket. 
5. Go to `Permission` tab and select `Bucket Policy` and from bottom select `Policy Generator`

6. Enter the details. For Principal enter your IAM `User ARN`and resource enter your bucket name. 

Once done click `Add Statement` then `Generate Policy` and copy and paste that into your bucket policy. 

```js
{
  "Id": "Policy1529562969022",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1529562962433",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::code-deployer-bucket/*",
      "Principal": {
        "AWS": [
          "arn:aws:iam::894665445897:user/BitBucket_User"
        ]
      }
    }
  ]
}
```
> Put a /* in Resource after your bucket name and press save. 


### Step 3 : Setting up EC2

Time to create an EC2 instance where the real code would be deployed

1. From Service menu select EC2 to open EC2 dashboard and select `Launch Instance` to launch a new EC2 instance 

2. Select the appropriate Amazon Machine Image (AMI). For this demo I have chosen 'Ubuntu Server 16.04 LTS (HVM), SSD Volume Type - ami-6a003c0f'. 

3. Choose an Instance Type, in free tier you will get 'General purpose | t2.micro' , select and proceed to `Configure Instance Details`

4. In the details , leave everything default or select as per your requirement, but make sure to select `IAM role` and select the IAM role which we created in IAM settings and proceed. 

5. Add storage, leave everything default and and `Add Tag` , create a new tag "NAME" and give it a value like 'EC2_INSTANCE_FOR_DEMO_RUN' then proceed to Configure Security Group

6. Give a proper Name to the security Group 
then `Add Rule`, Select Type : Custom TCP Rule , Port Range : 3000 (for my project) , Source : Anywhere (for the site to be accessible for all user) and finally press 'Review & Launch'  

7. Select a new key pair, give a proper name and download the key and keep it safe. You will need this key file to ssh to your EC2 instance. 

> Note : You might need to convert the key file to .ppk . Use putty to convert your pem file to ppk 

You need to install code deploy agent in your newly created instance. So, ssh to your instance and run the following commands

```bash
sudo apt-get update

sudo apt-get install ruby -y

cd /home/ubuntu

wget https://bucket-name.s3.amazonaws.com/latest/install

chmod +x ./install

sudo ./install auto
```

> `bucket-name` is the NOT then name of S3 bucket you created. 

>For the US East (Ohio) Region, replace `bucket-name` with aws-codedeploy-us-east-2. For a list of bucket names, see [Resource Kit Bucket Names by Region.](https://docs.aws.amazon.com/codedeploy/latest/userguide/resource-kit.html#resource-kit-bucket-names) 

To check if the code deploy agent is working or not , run the following command 

```bash
sudo service codedeploy-agent status
```

If the status is Active then everything is ok else run following command

```bash
sudo service codedeploy-agent start 
```

### Step 4 : Setting up AWS CodeDeploy

This would be the last setting for AWS. 

1. From the services menu select AWS `Code Deploy`

2. If this is your first application then select `Custom Deployment` else select `Create Application`

3. Give a proper name and group name to the application and make sure `Compute Platform` is  __EC2/On Premisses__

4. Deployment type : Inplace Deployment

5. In Environment Configuration select the tab `Amazon EC2 Instances` and select KEY , select the TAG KEY and value created while configuring EC2 instance.

6. If everything worked fine then under `Matching instances` it will show your EC2 instance and it's current status 

7. Set `Deployment configuration` to "CodeDeployDefault.OneAtTime" 

8. In `Service role ARN` select your "Role ARN". It will be a dropdown so just select the role which you have created in the IAM setting steps. 

9. Click on `Create Application`


## Setting up Bit Bucket Environment  

### Pipeline Environment Variables

Go to your bit bucket account , open your repository, enable pipelines, then go to settings, `PIPELINES` and set these environment variables 

|Key              | Value                   | Desc          | 
|-----------------|-------------------------|---------------|
|AWS_ACCESS_KEY_ID|AKIAJVF47GKFNRKX2X5Q| IAM user ACCESS KEY ID|
|AWS_SECRET_ACCESS_KEY|****************| IAM user SECRET ACCESS KEY |
|APPLICATION_NAME|BitBucket_Deployer_Application| Your Code Deploy Application name|
|AWS_DEFAULT_REGION|us-east-2|Region of your aws S3 & EC2 |
|DEPLOYMENT_CONFIG|CodeDeployDefault.OneAtATime|CodeDeploy Deployment configuration value|
|DEPLOYMENT_GROUP_NAME|Deployer_APP_GP1|Code Deploy application Group Name|
|S3_BUCKET|code-deployer-bucket| S3 bucket name|


### Setting Scripts - [1] bitbucket-pipelines.yml

Create or update if already present `bitbucket-pipelines.yml` and add the following 

```bash
# This is a sample build configuration for JavaScript.
# Check our guides at https://confluence.atlassian.com/x/14UWN for more examples.
# Only use spaces to indent your .yml configuration.
# -----
# You can specify a custom docker image from Docker Hub as your build environment.

pipelines:
  default:
    - step: 
         name: Deploy to AWS
         deployment: production
         image: atlassian/pipelines-awscli
         script:
          - aws deploy push --application-name $APPLICATION_NAME --s3-location s3://$S3_BUCKET/helloworld.zip --no-ignore-hidden-files
          - aws deploy create-deployment --application-name $APPLICATION_NAME --deployment-config-name $DEPLOYMENT_CONFIG --deployment-group-name $DEPLOYMENT_GROUP_NAME --s3-location bucket=$S3_BUCKET,key=helloworld.zip,bundleType=zip 
```

### Setting Scripts - [2] appspec.yml

Create a new file `appspec.yml` in your app's root directory and add the following lines

```bash
version: 0.0
os: linux
files:
  - source: /
    destination: /home/ubuntu/helloworld/
hooks:
  BeforeInstall:
    - location: scripts/install_dependencies.sh
      runas: root
  ApplicationStop:
    - location: scripts/stop_server.sh
      runas: root
  ApplicationStart:
    - location: scripts/start_server.sh
      runas: root
```

|Key| Value| Desc| 
|---|---|---|
source|/|Source for Code Deploy to copy files from. Here it's root directory for your S3 bucket| 
|destination| /home/ubuntu/helloworld/ | Destination in your EC2 instance where code deploy will paste and uzip the files|
|BeforeInstall|scripts/install_dependencies.sh|Script which will be run before your app starts or gets build. Install all the dependencies here like installing node , or npm install etc.<br /> Location : `yourapp/scripts/install_dependencies`|
|ApplicationStop|scripts/stop_server.sh|CodeDeploy will run this scripts before any other lifecyles hooks. Write your cleanup code like stopping the old server or cleaning older residue files etc.<br /> Location : `yourapp/scripts/stop_server`|
|ApplicationStart|scripts/start_server.sh|Add your code to run your server or start your application in this script. <br /> Location:`yourapp/scripts/start_server`|
|runas|root|Run the scripts as given privilege|


### scripts/install_dependencies.sh

Following install dependencies script to install node & npm on EC2 instance 

```bash

#install nvm 
sudo curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash

#activate nvm (node version manager)
. ~/.nvm/nvm.sh

#install latest version of node with long term support  
nvm install --lts

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

node --version 
npm --version  
```

### scripts/start_Server.sh

Following script is to start server or application 

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

cd /home/ubuntu/helloworld/

#install forever script 
npm install forever -g

# install node dependencies 
npm install 

# build app 
npm run build

#start server.js 
npm server.js & 
```

### scripts/stop_server.sh 

Following is to stop any older instance of node running before start_script runs

```bash
#!/bin/bash
# stop any old running servers 
 killall -s KILL node -q || true 

# remove older app files
cd /home/ubuntu/
rm -rf  helloworld/
```

That's pretty much it. 
Git commit and git push and see the pipeline working.

<hr />

## Quick Setting and Deployment

Just apply/cross-check the following settings while creating/modifying each one of the entity. 

> Note : Settings like ARN(s) , ID(s), SID(s), region etc are auto generated. They need not to match the following. Those data are specific to every user.

```js
var autoDeploymentSettings = {

    AWS_Settings: {

        IAM_Settings: {

            Users: {
                User_name: 'BitBucket_User',
                User_ARN: 'arn:aws:iam::894665445897:user/BitBucket_User',
                User_Group: 'CodeDeployerGroup'
            },

            Group: {
                Group_Name: 'CodeDeployerGroup',
                Group_ARN: 'arn:aws:iam::894665445897:group/CodeDeployerGroup',
                Permissions: [
                    'AmazonS3FullAccess', 'AWSCodeDeployFullAccess'
                ]
            },

            Roles: {
                Role_Name: 'CodeDeployerRole',
                Role_ARN: 'arn:aws:iam::894665445897:role/CodeDeployerRole',
                Policy_Name: [
                    'AmazonS3FullAccess', 'AWSCodeDeployRole'
                ],
                Trust_Relationships: {
                    Trusted_Entities: [
                        'The identity provider(s) codedeploy.us-east-2.amazonaws.com',
                        'The identity provider(s) ec2.amazonaws.com '
                    ],
                    Policy_Document: {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Effect": "Allow",
                                "Principal": {
                                    "Service": [
                                        "codedeploy.us-east-2.amazonaws.com",
                                        "ec2.amazonaws.com"
                                    ]
                                },
                                "Action": "sts:AssumeRole"
                            }
                        ]
                    }
                }
            }
        },

        S3_Settings: {
            Bucket_Name: 'code-deployer-bucket',
            Bucket_Permission: {
                Bucket_Policy: {
                    "Version": "2012-10-17",
                    "Id": "Policy1529562969022",
                    "Statement": [
                        {
                            "Sid": "Stmt1529562962433",
                            "Effect": "Allow",
                            "Principal": {
                                "AWS": "arn:aws:iam::894665445897:user/BitBucket_User"
                            },
                            "Action": [
                                "s3:GetObject",
                                "s3:PutObject"
                            ],
                            "Resource": "arn:aws:s3:::code-deployer-bucket/*"
                        }
                    ]
                }
            }
        },

        EC2_Settings: {
            Tags: [
                {
                    NAME: 'EC2_INSTANCE_FOR_DEMO_RUN'
                }
            ],
            InstanceID: 'i-0bfc305950fa638ef',
            AMI: 'Ubuntu Server 16.04 LTS (HVM), SSD Volume Type -ami-6a003c0f',
            Instance_Type: 't2-micro',
            IAM_role: 'CodeDeployerRole',
            Security_groups: 'CodedeploySecurityGroup',
            Key_pair_name: 'newEc2Instance',
            Public_DNS: 'ec2-52-15-176-74.us-east-2.compute.amazonaws.com',
        },

        CODE_DEPLOY_Settings: {
            Application_Name: ' BitBucket_Deployer_Application',
            Compute_Platform: 'EC2/On-premises',
            Deploymnet_Group_Name: 'Deployer_APP_GP1',
            Deployment_type: 'In-place deployment',
            Amazon_EC2_instance: [
                {
                    Key: 'NAME',
                    Value: 'EC2_INSTANCE_FOR_DEMO_RUN'
                }
            ], 
            Deployment_configuration : 'CodeDeployDefault.OneAtATime', 
            Service_role_ARN : 'arn:aws:iam::894665445897:role/CodeDeployerRole'
        }
    },

    BitBucket_repository_Settings: {
        name: 'helloworld',
        url: 'https://bitbucket.org/mehtaakshay22/quikdeal-dev-java/src/master/',
        
        Pipeline_Environment_Vars: {
            AWS_ACCESS_KEY_ID: 'AKIAJVF47GKFNRKX2X5Q',
            AWS_SECRET_ACCESS_KEY: YourSecretAccessKey,
            AWS_DEFAULT_REGION: 'us-east-2',
            APPLICATION_NAME: 'BitBucket_Deployer_Application',
            DEPLOYMENT_GROUP_NAME: 'Deployer_APP_GP1',
            DEPLOYMENT_CONFIG: 'CodeDeployDefault.OneAtATime',
            S3_BUCKET: 'code-deployer-bucket',
        }
    },
} 
```

If there is any problem while applying then please follow the extended version above. 


## Issues (I've faced) and Fixes  

`CodeDeploy` Log file location <br />

*/opt/codedeploy-agent/deployment-root/deployment-logs/codedeploy-agent-deployments.log*

Following are the list of issues/errors and their fix which I've faced while getting the code deploy to work. This might come in handy. 

|Issue / Error  | Solution |
|---|---|---|
|`wget https://bucket-name.s3.amazonaws.com/latest/install` results in <br />403 Forbidden |Make sure the bucket name in command <br />`wget https://bucket-name.s3.amazonaws.com/latest/install` <br /> is **NOT** your actual S3_Bucket name. It should be like `aws-codedeploy-us-east-2`. <br /> For complete list go to this link - [Resource Kit Bucket Names by Region.](https://docs.aws.amazon.com/codedeploy/latest/userguide/resource-kit.html#resource-kit-bucket-names) 
|CodeDeploy : Application Stop Fails| If CodeDeploy's Application stop phase always fails regardless of what command you have written in `stop_server.sh` then you can try one of these two : <br /> <br /> 1. Delete everything from this path <br /> `/opt/codedeploy-agent/deployment-root` on your EC2 instance and try to deploy again again.  <br />  <br /> 2. Follow step 1 +  delete your CodeDeploy Application itself and create a new one. New application can have the same name and group name as the deleted one. If new Application has a different name and group, remember to reflect the changes in bitbucket pipeline environment variables| 
|Unable to Change path  <br /> `cd : /home/ubuntu/helloworld/ not a file of directory`| Add the following in the beginning of your start_server and stop_server scripts <br /><br /> `export NVM_DIR="$HOME/.nvm"` <br />`[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"` <br />`[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"`
 |

