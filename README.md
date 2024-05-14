# Real-time Credit Scoring with Feast on AWS

## Overview

![credit-score-architecture@2x](data/architecture.jpeg)

This tutorial demonstrates the use of Feast as part of a real-time credit scoring application.
* The primary training dataset is a loan table. This table contains historic loan data with accompanying features. The dataset also contains a target variable, namely whether a user has defaulted on their loan.
* Feast is used during training to enrich the loan table with zipcode and credit history features from a S3 files. The S3 files are queried through Redshift.
* Feast is also used to serve the latest zipcode and credit history features for online credit scoring using DynamoDB.

## Requirements

* AWS CLI (v2.2 or later)

* You also need an EC2 instance for setup, training and testing. Please launch an ubuntu instance in the default VPC
  - Once the instance is created, [Authorize ec2 to access the ElastiCache cluster](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/GettingStarted.AuthorizeAccess.html)
  - For Troubleshooting login issues on the EC2 instance : [Error connecting to your instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/TroubleshootingInstancesConnecting.html#TroubleshootingInstancesConnectionTimeout)

* Install project specific dependencies
  - ``` pip install -r requirements.txt ```

## Setup
Open a terminal and go to folder ```infra``` by doing
```
cd infra
```
and complete the setup as explained below:

Set the parameters in ```config``` file. There are three parameters you need to set:
1. EC_FS_STACK: the stack name
1. SUBNET_ID: The subnet where the redshift cluster will be created 
1. PROJECT_NAME: Project name is used in naming s3 buckets and redshift cluster. If you get an error that the s3 bucket exists, just change the PROJECT_NAME to be something unique.

Once the config has your values, run deploy.sh in your terminal. This will spin up the required resources in 'us-west-2' account

```
./deploy.sh
```

You should see output in `Outputs` tab in the cloudformation stack. Please use them below.

Next we create a mapping from the Redshift cluster to the external catalog
```
aws redshift-data execute-statement \
    --region us-west-2 \
    --cluster-identifier "SET YOUR redshift_cluster_identifier HERE" \
    --db-user admin \
    --database dev --sql "create external schema spectrum from data catalog database 'dev' iam_role \
    'SET YOUR redshift_spectrum_arn here' create external database if not exists;"
```

To see whether the command was successful, please run the following command (substitute your statement id)
```
aws redshift-data describe-statement --id "SET YOUR STATEMENT ID HERE" --region "us-west-2"
``` 

You should now be able to query actual zipcode features by executing the following statement
```
aws redshift-data execute-statement \
    --region us-west-2 \
    --cluster-identifier "SET YOUR redshift_cluster_identifier HERE" \
    --db-user admin \
    --database dev --sql "SELECT * from spectrum.zipcode_features LIMIT 1;"
```
which should print out results by running
```
aws redshift-data get-statement-result --id "SET YOUR STATEMENT ID HERE" --region "us-west-2"
```

Return to the root of the credit scoring repository
```
cd ..
```

### Setting up Feast

We have already set up a feature repository in [feature_repo/](feature_repo/). It isn't necessary to create a new
feature repository, but it can be done using the following command
```
feast init -t aws feature_repo # Command only shown for reference.
```

Since we don't need to `init` a new repository, all we have to do is configure the 
[feature_store.yaml/](feature_repo/feature_store.yaml) in the feature repository. Please set the fields under `online_store` with the redis endpoint

`online_store` values will look like this:
```
    type: redis
    redis_type: redis_cluster
    connection_string: ec-featurestore-cache-xxxxxx.serverless.usw2.cache.amazonaws.com:6379,ssl=true
```
*connection_string* : Refer to `RedisConnectionString` in Cloudformation stack `Outputs` section

Set `offline_store` to the configuration you have received when deploying your Redshift cluster and S3 bucket(you can get this from the Output section of the Cloudformation template).

 `offline_store` values will look like this:
```
    cluster_id: <redshift-cluster-id>
    s3_staging_location: s3://<demo-feast-project-aws-bucket>/* 
    iam_role: arn:aws:iam::<enter-your-account-id>:role/s3_spectrum_role
```
*cluster_id* : Refer to `RedshiftClusterIdentifier` in CloudFormation stack `Outputs`\
*s3_staging_location* : Refer to `FeastS3BucketUri` in CloudFormation stack `Outputs`\
*iam_role* : Refer to `RedshiftSpectrumArn` in CloudFormation stack `Outputs`

Deploy the feature store by running `apply` from within the `feature_repo/` folder
```
cd feature_repo/
feast apply
```

If the command is successful, you should see the below output:

```
Registered entity dob_ssn
Registered entity zipcode
Registered feature view credit_history
Registered feature view zipcode_features
Deploying infrastructure for credit_history
Deploying infrastructure for zipcode_features
```



Next we load features into the online store using the `materialize-incremental` command. This command will load the
latest feature values from a data source into the online store.

```
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S")
feast materialize-incremental $CURRENT_TIME
```

Return to the root of the repository
```
cd ..
```

## Train and test the model

Finally, we train the model using a combination of loan data from S3 and our zipcode and credit history features from Redshift
(which in turn queries S3), and then execute online inferencing by reading those same features from Amazon ElastiCache.  

```
python run.py
```
The script should then output the result of a single loan application

`
loan rejected!
`


## Interactive demo (using Streamlit)

Once the credit scoring model has been trained it can be used for interactive loan applications using Streamlit:

Simply start the Streamlit application
```
streamlit run streamlit_app.py
```
Then navigate to the URL on which Streamlit is being served. You should see a user interface through which loan applications can be made:

![Streamlit Loan Application](data/streamlit.png)