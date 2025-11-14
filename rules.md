az network firewall application-rule create `
  --collection-name "AKS-Critical-Packages" `
  --firewall-name $firewallName `
  --resource-group $firewallRG `
  --action Allow `
  --priority 140 `
  --rule-name "All-Package-Repos" `
  --protocols Http=80 Https=443 `
  --source-addresses $aksSubnet `
  --target-fqdns "azure.archive.ubuntu.com" "security.ubuntu.com" "ports.ubuntu.com" "keyserver.ubuntu.com" "changelogs.ubuntu.com" "deb.nodesource.com" "packages.cloud.google.com" "apt.kubernetes.io" "dl.k8s.io" "cdn.dl.k8s.io" "registry.npmjs.org" "download.docker.com" "get.docker.com" "apt.dockerproject.org" "storage.googleapis.com" "snapshot.debian.org" "deb.debian.org" "security.debian.org"