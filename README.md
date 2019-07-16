# Serverless and in-line Lambda

AWS has support for Serverless transformations, however: it requires you to
upload the Lambda function to S3 prior to deployment. The reason for this is
that the CodeUri property of an AWS::Serverless::Function cannot use intrinsic
functions and thus you must hardcode the s3 artifact URL into your template.

If you want to automate this process, your CI CD pipeline has to upload the
Lambda function to S3 first. The disadvantage of that practice is that the
code of your Lambda function is not versioned. It would be if we could use the
Lambda in-line. However, maintaining in-line Lambda in CloudFormation is rather
ugly.

## Solution

To work around this limitation I've created a small script with Rubycfn. This
script converts your Lambda function file to in-line code in CloudFormation,
so that you only have to maintain the file containing your Lambda code.

In addition, the CloudFormation template contains a Custom Resource that
creates a zip file from your in-line Lambda and uploads it to S3.

Et voila! You can now deploy the CloudFormation template, while keeping your
Lambda function under version control and keeping it maintainable.

This demo assumes you have Ruby installed. Ruby 2.3 or higher is recommended.

## Creating the Template

```
gem install rubycfn
https://github.com/binxio/serverless-inline-lambda.git
cd serverless-inline-lambda
export DEMO_BUCKET="my-s3-bucket"
cat template.rb | rubycfn > my_template.json
```

And you're done! Don't forget to export DEMO_BUCKET to an S3 bucket that you
own.