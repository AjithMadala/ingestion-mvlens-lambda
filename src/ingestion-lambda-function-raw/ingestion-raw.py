import json
from datetime import datetime
import boto3
import os
import logging

logging.basicConfig(
    level=logging.INFO,
    format=f"%(asctime)s  %(lineno)d    %(levelname)s   %(message)s",
)
log = logging.getLogger("Ingest-Raw")
log.setLevel(logging.INFO)
log.info("Log message here")

current_date = datetime.now() 
year = current_date.year
month = current_date.month
day = current_date.day

code_bucket = os.environ['codebucket']
print(codebucket)
s3 = boto3.resource('s3')
s3_client=boto3.client('s3')
sns_client=boto3.client('sns')

def msg(message):     
    response = sns_client.publish(
    TopicArn='arn:aws:sns:us-east-2:977746141011:data-pipeline-notfication',
    Message=message,
    Subject='Message from Lambda Code',
    )
    
def lambda_handler(event, context):
    
    try:
        dataset=event.get("dataset")
        log.info(f"{dataset} is key")    
        response = s3_client.get_object(Bucket=code_bucket, Key=f"{dataset}/config/process_config.json")
        msg("Bucket and key are Successfully Excecuted")
    except Exception as e:
        log.exception(f"error {e}")
        msg("Error From Key and Bucket {e}")
        
    try:
        config_data = response.get('Body').read().decode('utf-8')
        config_json = json.loads(config_data)    
        source_bucket = config_json.get('source-bucket')
        source_folder = config_json.get('source-folder')
        target_bucket = config_json.get('target-bucket')
        log.info(source_bucket)
        msg("Configuring of Bucket is Successful")
        
    except Exception as e:
        log.exception(f"error {e}")
        msg(f"Error from configuring bucket {e}")
        
    try:    
        response = s3_client.list_objects_v2(Bucket=source_bucket)
        log.info(response)

        file_list = []

        for obj in response['Contents']:
            file_name = obj['Key']
            file_name = file_name.replace(source_folder + '/', '')
            file_list.append(file_name)
        log.info(file_list)

        for file in file_list[1:]:
            file_part = file.split('.')[0]
            file_ext = file.split('.')[1]
            log.info(file_part)
            otherkey = f"{source_folder}/{file_part}/year={year}/month={month}/day={day}/{file_part}_{current_date}.{file_ext}"
            log.info(otherkey)
            
            copy_source = {
            'Bucket': source_bucket,
            'Key': f"{source_folder}/{file}"
                
            }
            bucket = s3.Bucket(target_bucket)
            bucket.copy(copy_source, otherkey)
            msg("Processing Files is Successful")
       
    except Exception as e:
        log.exception(f"error {e}")
        msg(f"Error from files processing {e}")
        
        response = sns_client.publish(
        TopicArn='arn:aws:sns:us-east-2:977746141011:data-pipeline-notfication',
        Message='Successfully Ingested Raw Data',
        Subject='Ingest Raw Data',)
        

    
    return {
        'statusCode': 200,
        'body': json.dumps(otherkey)
        }
