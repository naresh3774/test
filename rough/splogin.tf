- name: Log in to Azure using a service principal
  azure.azcollection.azure_rm_auth:
    client_id: "{{ azure.client_id }}"
    secret: "{{ azure.client_secret }}"
    tenant: "{{ azure.tenant_id }}"
    subscription_id: "{{ azure.subscription_id }}"


- name: Login to Azure with Service Principal
  ansible.builtin.command:
    cmd: >
      az login --service-principal
      --username "{{ azure_client_id }}"
      --password "{{ azure_client_secret }}"
      --tenant "{{ azure_tenant_id }}"
  register: login_output
  # ignore_errors: yes