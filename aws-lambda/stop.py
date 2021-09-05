# Stops an EC2 instance and reports back to Discord. I use it for scheduling automagic
# start/stops using AWS CloudWatch rules.
# This needs packaging with dependencies before uploading to a Lamdba function.. see 
# https://docs.aws.amazon.com/lambda/latest/dg/python-package.html for ezpz steps.
#
# https://github.com/agrondahl/dcs-server-start

import requests
import boto3

region = 'eu-north-1'
instances = ['i-31337']
ec2 = boto3.client('ec2', region_name=region)

def lambda_handler(event, context):
    ec2.stop_instances(InstanceIds=instances)

    url = "https://discord.com/api/webhooks/epsteindidntkillhimself" # Your hook here 

    data = {
        "content" : "Scheduled automation is stopping server Viktor Röd",
        "username" : "Viktor Röd Server"
    }

    result = requests.post(url, json = data)

    try:
        result.raise_for_status()
    except requests.exceptions.HTTPError as err:
        print(err)
    else:
        print("Payload delivered successfully, code {}.".format(result.status_code))
    
    print('stopped your instances: ' + str(instances))
    
