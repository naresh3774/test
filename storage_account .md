# how to enable write to fileshare

Enable Managed Identity on your App Service:

Go to your App Service in the Azure Portal.
Under Settings, select Identity.
Enable System-assigned managed identity and save the change.
Assign Storage File Data SMB Share Contributor Role:

Go to your Storage Account in the Azure Portal.
Under Security + networking, select Access control (IAM).
Click Add role assignment.
In the Role dropdown, select Storage File Data SMB Share Contributor.
In Assign access to, choose Managed identity and select your App Service.
Save the changes.