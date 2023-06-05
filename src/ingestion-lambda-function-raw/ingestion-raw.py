import json
from datetime import datetime
import boto3
import os

current_date = datetime.now() 
year = current_date.year
month = current_date.month
day = current_date.day

code_bucket = os.environ['codebucket']
print(code_bucket)

s3 = boto3.resource('s3')
s3_client=boto3.client('s3')

def lambda_handler(event, context):
    dataset=event.get("dataset")
    
    response = s3_client.get_object(Bucket=code_bucket, Key=f"{dataset}/config/process_config.json")
    config_data = response.get('Body').read().decode('utf-8')
    config_json = json.loads(config_data)
    
    source_bucket = config_json.get('source-bucket')
    source_folder = config_json.get('source-folder')
    target_bucket = config_json.get('target-bucket')
    print(source_bucket)
    
    response = s3_client.list_objects_v2(Bucket=source_bucket)
    print(response)
 
    file_list = []
 
    for obj in response['Contents']:
        file_name = obj['Key']
        file_name = file_name.replace(source_folder + '/', '')
        file_list.append(file_name)
    print(file_list)

    for file in file_list[1:]:
        file_part = file.split('.')[0]
        file_ext = file.split('.')[1]
        print(file_part)
        otherkey = f"{source_folder}/{file_part}/year={year}/month={month}/day={day}/{file_part}_{current_date}.{file_ext}"
        print(otherkey)
        copy_source = {
        'Bucket': source_bucket,
        'Key': f"{source_folder}/{file}"
             
        }
        bucket = s3.Bucket(target_bucket)
        bucket.copy(copy_source, otherkey)
        
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
             
        }