import json
import boto3
from aws_lambda_powertools import Logger, Tracer
from lambdas.helpers.auth import get_client_params, exchange_auth_code, get_parameter, encrypt_data

logger = Logger(service="my-lambda-service")
tracer = Tracer(service="my-lambda-service")

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users')

@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event, context):
    logger.info(event)

    expected_state = get_parameter('strava_callback_state', True)
    recieved_state = event['queryStringParameters']['state']

    if recieved_state != expected_state:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Invalid state parameter."})
        }

    client_params = get_client_params()

    auth = exchange_auth_code(
        **client_params,
        auth_code=event['queryStringParameters']['code']
    )

    token = auth['refresh_token']
    user = auth['athlete']

    encrypted_token = encrypt_data(token)

    table.put_item(
        Item={
            'id': user['id'],
            'username': user['username'],
            'refresh_token': encrypted_token,
            'activity_replication': []
        }
    )

    return {"statusCode": 200, "body": "Hello from callback!"}