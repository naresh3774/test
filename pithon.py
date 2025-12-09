from azure.identity import ClientSecretCredential
from azure.mgmt.resource import ResourceManagementClient

ARM_SCOPE = "https://management.core.usgovcloudapi.net/.default"

credential = ClientSecretCredential(
    tenant_id=TENANT_ID,
    client_id=CLIENT_ID,
    client_secret=CLIENT_SECRET,
    authority="https://login.microsoftonline.us"
)

print("Successfully created ClientSecretCredential.")

resource_client = ResourceManagementClient(
    credential,
    SUBSCRIPTION_ID,
    base_url="https://management.usgovcloudapi.net",
    credential_scopes=[ARM_SCOPE]
)

print(f"Successfully connected to Azure Government subscription: {SUBSCRIPTION_ID}")

# Example: List resource groups
for rg in resource_client.resource_groups.list():
    print(rg.name)
