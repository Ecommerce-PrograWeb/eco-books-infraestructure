import aws_cdk as core
import aws_cdk.assertions as assertions
from infra_eco_books.infra_eco_books_stack import InfraEcoBooksStack


def test_vpc_created():
    app = core.App()
    stack = InfraEcoBooksStack(app, "test-stack")
    template = assertions.Template.from_stack(stack)

    # Verify VPC is created
    template.resource_count_is("AWS::EC2::VPC", 1)


def test_rds_database_created():
    app = core.App()
    stack = InfraEcoBooksStack(app, "test-stack")
    template = assertions.Template.from_stack(stack)

    # Verify RDS instance is created
    template.resource_count_is("AWS::RDS::DBInstance", 1)
    
    # Verify database properties
    template.has_resource_properties("AWS::RDS::DBInstance", {
        "Engine": "mysql",
        "DBName": "ecobooks",
        "PubliclyAccessible": False
    })


def test_ecr_repositories_created():
    app = core.App()
    stack = InfraEcoBooksStack(app, "test-stack")
    template = assertions.Template.from_stack(stack)

    # Verify 2 ECR repositories are created (backend and frontend)
    template.resource_count_is("AWS::ECR::Repository", 2)


def test_ecs_cluster_created():
    app = core.App()
    stack = InfraEcoBooksStack(app, "test-stack")
    template = assertions.Template.from_stack(stack)

    # Verify ECS cluster is created
    template.resource_count_is("AWS::ECS::Cluster", 1)


def test_fargate_services_created():
    app = core.App()
    stack = InfraEcoBooksStack(app, "test-stack")
    template = assertions.Template.from_stack(stack)

    # Verify 2 Fargate services are created (backend and frontend)
    template.resource_count_is("AWS::ECS::Service", 2)


def test_load_balancers_created():
    app = core.App()
    stack = InfraEcoBooksStack(app, "test-stack")
    template = assertions.Template.from_stack(stack)

    # Verify 2 Application Load Balancers are created
    template.resource_count_is("AWS::ElasticLoadBalancingV2::LoadBalancer", 2)


def test_security_groups_created():
    app = core.App()
    stack = InfraEcoBooksStack(app, "test-stack")
    template = assertions.Template.from_stack(stack)

    # Verify security groups are created
    # At least 3: database, backend, frontend
    template.resource_count_is("AWS::EC2::SecurityGroup", assertions.Match.at_least(3))


def test_secrets_manager_secret_created():
    app = core.App()
    stack = InfraEcoBooksStack(app, "test-stack")
    template = assertions.Template.from_stack(stack)

    # Verify Secrets Manager secret is created for database credentials
    template.resource_count_is("AWS::SecretsManager::Secret", 1)


def test_stack_outputs():
    app = core.App()
    stack = InfraEcoBooksStack(app, "test-stack")
    template = assertions.Template.from_stack(stack)

    # Verify important outputs exist
    outputs = template.find_outputs("*")
    
    assert "BackendRepositoryUri" in outputs
    assert "FrontendRepositoryUri" in outputs
    assert "BackendURL" in outputs
    assert "FrontendURL" in outputs
    assert "DatabaseEndpoint" in outputs
    assert "DatabaseSecretArn" in outputs
