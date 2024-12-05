# groovy practice
# Terraform


Migration from SQL Managed Instance (MI) to SQL Database: Findings and Proposed Solutions
Findings:
User Logins Not Working:

During the migration, we observed that user logins within the database were not functioning.
After further investigation, it was identified that Microsoft does not allow passwords to be migrated for security reasons. As a result, user logins must be reconfigured post-migration.
Dynamic Nature of the Database:

The database is under constant updates, which poses a challenge for online migration. Currently, there is no direct method to perform an online migration from SQL Managed Instance to SQL Database while maintaining data consistency.
Proposed Solutions:
Manual Password Configuration:

For user logins, passwords will need to be reset manually within each database post-migration. This ensures access continuity and adheres to security protocols.
Online Migration Alternatives:

Further exploration is required to address the challenge of database consistency during migration. Potential solutions could include:
Implementing change tracking or replication mechanisms before and after the migration to capture and apply delta changes.
Utilizing downtime windows for incremental migrations to minimize disruptions while ensuring data accuracy.
Next Steps:

Evaluate the feasibility of automated solutions for password configuration.
Assess tools or processes that can facilitate online or near-real-time migration while addressing consistency concerns.





