#!/usr/bin/env python3
import os
import aws_cdk as cdk
from infra_eco_books.infra_eco_books_stack import InfraEcoBooksStack

app = cdk.App()

# Get environment from context or use default
env = cdk.Environment(
    account=os.environ.get('CDK_DEFAULT_ACCOUNT'),
    region=os.environ.get('CDK_DEFAULT_REGION', 'us-east-2')
)

InfraEcoBooksStack(
    app, 
    "InfraEcoBooksStack",
    env=env,
    description="Infrastructure for Eco-Books Backend and Frontend"
)

app.synth()
