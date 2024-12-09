- name: Log in to Azure using a service principal
  azure.azcollection.azure_rm_auth:
    client_id: "{{ azure.client_id }}"
    secret: "{{ azure.client_secret }}"
    tenant: "{{ azure.tenant_id }}"
    subscription_id: "{{ azure.subscription_id }}"