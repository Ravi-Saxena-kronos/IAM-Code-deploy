#!/bin/bash

# Skip deployment if commit message contains "skip cd"
if [[ $LAST_COMMIT_MESSAGE == *"skip cd"* ]]; then
  echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
  echo "SKIPPING CODEDEPLOY"
  echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
  exit 0
fi

echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
echo "Zipping of the code to application.zip is already done in Prerequisite Step"
echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
echo "Pushing application.zip to S3 bucket..."
echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"

NOW=$(date +"%Y%m%d%H%M%S")
BUCKET_KEY="$APPLICATION_NAME/$NOW-bitbucket_builds.zip"
aws s3 cp /tmp/artifact.zip "s3://my-webr1/$BUCKET_KEY"
echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
echo "Creating CodeDeploy Deployment"
echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"

deploy_groups=()

if [ "$BITBUCKET_BRANCH" == "master" ]; then
  deploy_groups=("code-deploy-group")
elif [ "$BITBUCKET_BRANCH" == "staging" ]; then
  deploy_groups=("code-deploy-staging-group")
fi

if [ ${#deploy_groups[@]} -eq 0 ]; then
  echo "❌ No deployment group matched for branch: $BITBUCKET_BRANCH"
  exit 1
fi

for deploy_group in "${deploy_groups[@]}"; do
  echo "Creating deployment for: $deploy_group"
  aws deploy create-deployment \
    --application-name "$APPLICATION_NAME" \
    --deployment-group-name "$deploy_group" \
    --s3-location bucket="$S3_BUCKET",key="$BUCKET_KEY",bundleType=zip \
    --deployment-config-name "$DEPLOYMENT_CONFIG" \
    --description "New deployment from BitBucket Pipeline" \
    --ignore-application-stop-failures
done
