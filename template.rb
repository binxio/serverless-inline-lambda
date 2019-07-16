# Method to transform the contents of a file to an array of strings
def file_to_inline(filename)
  File.open(filename).read.split("\n")
end

# Enable CloudFormation Transformations
transform

# Allow dynamic configuration of Lambda bucket name.
# e.g.: export DEMO_BUCKET=my-bucket-name
variable :demo_bucket,
         default: "inline-lambda-demo",
         value: ENV["DEMO_BUCKET"],
         required: true

# Set stack description
description "Custom Resource to deploy Serverless Lambda function in-line"

# Custom resource to upload handler.rb to S3
resource :UploadZipToS3,
         type: "Custom::InlineUpload" do |r|
  r.depends_on "InlineS3UploadFunction"
  r.property(:service_token) { :inline_s3_upload_function.ref("Arn") }
  r.property(:bucket_name) { demo_bucket }
  r.property(:file_name) { "index.rb" }
  r.property(:create_mode) { "zip-literal" }
  r.property(:content) { file_to_inline("handler.rb").fnjoin("\n") }
end

# Create a Serverless Lambda function backed by API Gateway
resource :my_serverless_function,
         type: "AWS::Serverless::Function" do |r|
  r.depends_on "UploadZipToS3"
  r.property(:handler) { "index.lambda_handler" }
  r.property(:runtime) { "ruby2.5" }
  r.property(:code_uri) { "s3://#{demo_bucket}/index.zip" }
  r.property(:description) { "My Serverless Lambda Function" }
  r.property(:timeout) { 30 }
  r.property(:events) do
    {
      "compiler": {
        "Type": "Api",
        "Properties": {
          "Path": "/",
          "Method": "get"
        }
      }
    }
  end
end

# Lambda function to upload files to S3
resource :inline_s3_upload_function,
         type: "AWS::Lambda::Function" do |r|
  r.property(:code) do
    {
      "ZipFile": file_to_inline("inline_upload.py").fnjoin("\n")
    }
  end
  r.property(:handler) { "index.lambda_handler" }
  r.property(:role) { "LambdaExecutionRole".ref("Arn") }
  r.property(:runtime) { "python2.7" }
  r.property(:timeout) { "30" }
end

# Lambda execution role
resource :lambda_execution_role,
         type: "AWS::IAM::Role" do |r|
  r.property(:assume_role_policy_document) do
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": [
              "lambda.amazonaws.com"
            ]
          },
          "Action": [
            "sts:AssumeRole"
          ]
        }
      ]
    }
  end
  r.property(:path) { "/" }
  r.property(:policies) do
    [
      {
        "PolicyName": "root",
        "PolicyDocument": {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Action": %w(logs:CreateLogGroup logs:CreateLogStream logs:PutLogEvents),
              "Resource": "arn:aws:logs:*:*:*"
            },
            {
              "Effect": "Allow",
              "Action": "s3:*",
              "Resource": "arn:aws:s3:::*"
            }
          ]
        }
      }
    ]
  end
end
