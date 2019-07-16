def lambda_handler(event:, context:)
  {
    statusCode: 200,
    body: "hello world!",
    headers: {
      "Access-Control-Allow-Headers": "*",
      "Access-Control-Allow-Origin": "*"
    }
  }
end
