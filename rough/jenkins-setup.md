I.  Continuous Deployment (CD) Setup Process – Simplified Overview
    
1. Handoff from the CI Team
    The CI (Continuous Integration) team provides the initial setup. This includes:

    - Connecting the application’s GitHub repository to Jenkins.

    - Setting up webhooks so Jenkins knows when to act (like after a build is complete).

    - Providing the credentials and access we need.

    Once this is ready, the CD (Continuous Deployment) team takes over to handle the actual deployment of the application.


2. Setting Up the Jenkins Deployment Configuration

    We configure Jenkins to use a template-based deployment system. This is done using what's called a "Shared Library", which holds reusable deployment logic.

    - Connect Jenkins to a specific GitHub repository where the shared templates (library) live.

    - Specify which branch Jenkins should use (usually main, staging, development).
    - Define where the configuration files live inside that repo (e.g., which folder has the Jenkins templates).
    - Link this to our application’s deployment pipeline so Jenkins knows what to run and how.

3. Summary

    - CI team sets up the GitHub connection and hands it over.

    - CD team plugs in deployment templates using Jenkins.

    - These templates tell Jenkins how to deploy the app whenever needed.

II. GitHub Repository Structure for Jenkins Deployment.

Within the connected GitHub repository, there’s a configuration folder that holds all the files Jenkins needs to deploy the application:

1. Main Configuration Files

    Located under the pipeline-configuration/ folder:

    - Jenkinsfile – This is the main script Jenkins runs to start the deployment process.
    - pipeline_configuration.groovy – A supporting configuration file that defines key values like environment settings, app names, and paths.

2. Library Folder – Templates for Automation

    Inside the library/ folder, we keep reusable templates that Jenkins refers to at different stages:

    frontend_dependency_template.groovy – Instructions to set up or install frontend-related packages.

    - backend_dependency_template.groovy – Same as above but for backend systems.

    - sonarqube_template.groovy – Template to run code quality checks using SonarQube.

    - build_template.groovy – Contains steps to package or build the application.

    - deploy_template.groovy – Final deployment steps to push the application to the desired environment (like a cloud server or VM).

3. Summary

    This setup keeps all deployment logic clean and modular:

    - The main Jenkinsfile triggers the process.

    - The library templates handle specific tasks like installing, testing, building, and deploying.
