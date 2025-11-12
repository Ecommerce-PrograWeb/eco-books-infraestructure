from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_ecs as ecs,
    aws_ecr as ecr,
    aws_ecs_patterns as ecs_patterns,
    aws_rds as rds,
    aws_secretsmanager as secretsmanager,
    aws_elasticloadbalancingv2 as elbv2,
    RemovalPolicy,
    Duration,
    CfnOutput,
)
from constructs import Construct
import json


class InfraEcoBooksStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # ============================================
        # VPC - Virtual Private Cloud
        # ============================================
        vpc = ec2.Vpc(
            self, "EcoBooksVPC",
            max_azs=2,  # 2 availability zones for high availability
            nat_gateways=1,  # 1 NAT Gateway to save costs (can increase to 2 for production)
        )

        # ============================================
        # Security Groups
        # ============================================
        # Security group for the database
        db_security_group = ec2.SecurityGroup(
            self, "DatabaseSecurityGroup",
            vpc=vpc,
            description="Security group for RDS MySQL database",
            allow_all_outbound=True
        )

        # Security group for backend service
        backend_security_group = ec2.SecurityGroup(
            self, "BackendSecurityGroup",
            vpc=vpc,
            description="Security group for backend ECS service",
            allow_all_outbound=True
        )

        # Security group for frontend service
        frontend_security_group = ec2.SecurityGroup(
            self, "FrontendSecurityGroup",
            vpc=vpc,
            description="Security group for frontend ECS service",
            allow_all_outbound=True
        )

        # Allow backend to connect to database on port 3306
        db_security_group.add_ingress_rule(
            peer=backend_security_group,
            connection=ec2.Port.tcp(3306),
            description="Allow backend to access MySQL"
        )

        # ============================================
        # RDS MySQL Database
        # ============================================
        # Secret for database credentials
        db_secret = secretsmanager.Secret(
            self, "DBSecret",
            secret_name="eco-books-db-credentials",
            generate_secret_string=secretsmanager.SecretStringGenerator(
                secret_string_template=json.dumps({"username": "admin"}),
                generate_string_key="password",
                exclude_punctuation=True,
                include_space=False,
                password_length=32
            )
        )

        # RDS MySQL Instance
        database = rds.DatabaseInstance(
            self, "EcoBooksDatabase",
            engine=rds.DatabaseInstanceEngine.mysql(
                version=rds.MysqlEngineVersion.VER_8_0_39
            ),
            instance_type=ec2.InstanceType.of(
                ec2.InstanceClass.BURSTABLE3,
                ec2.InstanceSize.SMALL  # db.t3.small - adjust based on needs
            ),
            vpc=vpc,
            vpc_subnets=ec2.SubnetSelection(
                subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS
            ),
            security_groups=[db_security_group],
            credentials=rds.Credentials.from_secret(db_secret),
            database_name="ecobooks",
            allocated_storage=20,
            max_allocated_storage=100,  # Auto-scaling storage
            backup_retention=Duration.days(7),
            deletion_protection=False,  # Set to True in production
            removal_policy=RemovalPolicy.SNAPSHOT,  # Take snapshot on deletion
            publicly_accessible=False,
        )

        # ============================================
        # ECR Repositories
        # ============================================
        backend_repo = ecr.Repository(
            self, "BackendRepository",
            repository_name="eco-books-backend",
            removal_policy=RemovalPolicy.RETAIN,  # Keep images on stack deletion
            image_scan_on_push=True,  # Scan images for vulnerabilities
        )

        frontend_repo = ecr.Repository(
            self, "FrontendRepository",
            repository_name="eco-books-frontend",
            removal_policy=RemovalPolicy.RETAIN,
            image_scan_on_push=True,
        )

        # ============================================
        # ECS Cluster
        # ============================================
        cluster = ecs.Cluster(
            self, "EcoBooksCluster",
            vpc=vpc,
            cluster_name="eco-books-cluster",
            container_insights=True  # Enable CloudWatch Container Insights
        )

        # ============================================
        # Backend Service (Fargate)
        # ============================================
        backend_task_definition = ecs.FargateTaskDefinition(
            self, "BackendTaskDefinition",
            memory_limit_mib=512,
            cpu=256,
        )

        # Add container to backend task
        backend_container = backend_task_definition.add_container(
            "BackendContainer",
            image=ecs.ContainerImage.from_ecr_repository(backend_repo, "latest"),
            logging=ecs.LogDrivers.aws_logs(stream_prefix="backend"),
            environment={
                "NODE_ENV": "production",
                "DB_HOST": database.db_instance_endpoint_address,
                "DB_PORT": "3306",
                "DB_NAME": "ecobooks",
            },
            secrets={
                "DB_USER": ecs.Secret.from_secrets_manager(db_secret, "username"),
                "DB_PASS": ecs.Secret.from_secrets_manager(db_secret, "password"),
            },
        )

        backend_container.add_port_mappings(
            ecs.PortMapping(container_port=3000, protocol=ecs.Protocol.TCP)
        )

        # Backend Fargate Service with Application Load Balancer
        backend_service = ecs_patterns.ApplicationLoadBalancedFargateService(
            self, "BackendService",
            cluster=cluster,
            task_definition=backend_task_definition,
            desired_count=1,  # Number of tasks to run
            public_load_balancer=True,
            listener_port=80,
            security_groups=[backend_security_group],
        )

        # Configure health check
        backend_service.target_group.configure_health_check(
            path="/health",
            interval=Duration.seconds(60),
            timeout=Duration.seconds(30),
            healthy_threshold_count=2,
            unhealthy_threshold_count=3,
        )

        # Grant database access to backend
        database.secret.grant_read(backend_task_definition.task_role)

        # ============================================
        # Frontend Service (Fargate)
        # ============================================
        frontend_task_definition = ecs.FargateTaskDefinition(
            self, "FrontendTaskDefinition",
            memory_limit_mib=512,
            cpu=256,
        )

        # Add container to frontend task
        frontend_container = frontend_task_definition.add_container(
            "FrontendContainer",
            image=ecs.ContainerImage.from_ecr_repository(frontend_repo, "latest"),
            logging=ecs.LogDrivers.aws_logs(stream_prefix="frontend"),
            environment={
                "NODE_ENV": "production",
                "NEXT_PUBLIC_API_URL": f"http://{backend_service.load_balancer.load_balancer_dns_name}",
            },
        )

        frontend_container.add_port_mappings(
            ecs.PortMapping(container_port=3000, protocol=ecs.Protocol.TCP)
        )

        # Frontend Fargate Service with Application Load Balancer
        frontend_service = ecs_patterns.ApplicationLoadBalancedFargateService(
            self, "FrontendService",
            cluster=cluster,
            task_definition=frontend_task_definition,
            desired_count=1,
            public_load_balancer=True,
            listener_port=80,
            security_groups=[frontend_security_group],
        )

        # Configure health check for frontend
        frontend_service.target_group.configure_health_check(
            path="/",
            interval=Duration.seconds(60),
            timeout=Duration.seconds(30),
            healthy_threshold_count=2,
            unhealthy_threshold_count=3,
        )

        # ============================================
        # CloudFormation Outputs
        # ============================================
        CfnOutput(
            self, "BackendRepositoryUri",
            value=backend_repo.repository_uri,
            description="Backend ECR Repository URI",
            export_name="EcoBooksBackendRepoUri"
        )

        CfnOutput(
            self, "FrontendRepositoryUri",
            value=frontend_repo.repository_uri,
            description="Frontend ECR Repository URI",
            export_name="EcoBooksFrontendRepoUri"
        )

        CfnOutput(
            self, "BackendURL",
            value=f"http://{backend_service.load_balancer.load_balancer_dns_name}",
            description="Backend Application Load Balancer URL",
            export_name="EcoBooksBackendURL"
        )

        CfnOutput(
            self, "FrontendURL",
            value=f"http://{frontend_service.load_balancer.load_balancer_dns_name}",
            description="Frontend Application Load Balancer URL",
            export_name="EcoBooksFrontendURL"
        )

        CfnOutput(
            self, "DatabaseEndpoint",
            value=database.db_instance_endpoint_address,
            description="RDS Database Endpoint",
            export_name="EcoBooksDatabaseEndpoint"
        )

        CfnOutput(
            self, "DatabaseSecretArn",
            value=db_secret.secret_arn,
            description="ARN of the database credentials secret",
            export_name="EcoBooksDatabaseSecretArn"
        )
