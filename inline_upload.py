import boto3
import cfnresponse
import hashlib
import json
import logging
import signal
import zipfile

from urllib2 import build_opener, HTTPHandler, Request

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

def lambda_handler(event, context):
    # Setup alarm for remaining runtime minus a second
    try:
        signal.alarm((context.get_remaining_time_in_millis() / 1000) - 1)
        LOGGER.info('REQUEST RECEIVED: %s', event)
        LOGGER.info('REQUEST RECEIVED: %s', context)
        if event['RequestType'] == 'Create' or event['RequestType'] == 'Update':
            LOGGER.info('Creating or updating S3 Object')
            bucket_name = event['ResourceProperties']['BucketName']
            file_name = event['ResourceProperties']['FileName']
            content = event['ResourceProperties']['Content']
            create_zip = True if event['ResourceProperties']['CreateMode'] in ['zip', 'zip-literal'] else False
            literal_file = True if event['ResourceProperties']['CreateMode'] == 'plain-literal' else False
            literal_zip = True if event['ResourceProperties']['CreateMode'] == 'zip-literal' else False
            md5_hash = hashlib.md5(content).hexdigest()
            with open('/tmp/' + file_name, 'w') as lambda_file:
                lambda_file.write(content)
                lambda_file.close()
                s3 = boto3.resource('s3')
                if create_zip == True:
                    if literal_zip == True:
                        output_filename = ".".join(file_name.split(".")[:-1]) + '.zip'
                    else:
                        output_filename = file_name + '_' + md5_hash + '.zip'
                    zf = zipfile.ZipFile('/tmp/' + output_filename, mode='w')
                    try:
                        zf.write('/tmp/' + file_name, file_name)
                    finally:
                        zf.close()
                        data = open('/tmp/' + output_filename, 'rb')
                        s3.Bucket(bucket_name).put_object(Key=output_filename, Body=data)
                else:
                    if literal_file == True:
                        data = open('/tmp/' + file_name, 'rb')
                        s3.Bucket(bucket_name).put_object(Key=file_name, Body=content)
                    else:
                        extension = file_name.split(".")[-1]
                        output_filename = ".".join(file_name.split(".")[:-1]) + '_' + md5_hash + '.' + extension
                        data = open('/tmp/' + file_name, 'rb')
                        s3.Bucket(bucket_name).put_object(Key=output_filename, Body=content)
            cfnresponse.send(event, context, cfnresponse.SUCCESS, { 'Message': output_filename } )
        elif event['RequestType'] == 'Delete':
            LOGGER.info('DELETE!')
            cfnresponse.send(event, context, cfnresponse.SUCCESS, { 'Message': 'Resource deletion successful!'} )
        else:
            LOGGER.info('FAILED!')
            cfnresponse.send(event, context, cfnresponse.SUCCESS, { 'Message': 'There is no such success like failure.'} )
    except Exception as e: #pylint: disable=W0702
        LOGGER.info(e)
        cfnresponse.send(event, context, cfnresponse.SUCCESS, { 'Message': 'There is no such success like failure.' } )

def timeout_handler(_signal, _frame):
    '''Handle SIGALRM'''
    LOGGER.info('Time exceeded')
    raise Exception('Time exceeded')

signal.signal(signal.SIGALRM, timeout_handler)
