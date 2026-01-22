import boto3

# CHANGE ONLY THIS VALUE
TAG_VALUE = "portfolio-project"

ec2 = boto3.client('ec2')

response = ec2.describe_instances(
    Filters=[
        {
            'Name': 'tag:Name',     # Tag KEY (usually Name)
            'Values': [TAG_VALUE]   # Tag VALUE
        },
        {
            'Name': 'instance-state-name',
            'Values': ['stopped']
        }
    ]
)

instance_ids = []

for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        instance_ids.append(instance['InstanceId'])

if instance_ids:
    ec2.start_instances(InstanceIds=instance_ids)
    print(f"Started EC2 instance(s): {instance_ids}")
else:
    print("No stopped EC2 instances found")
