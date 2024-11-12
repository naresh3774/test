# groovy
def environment = 'staging' // Change this to 'dev' or 'staging' as needed

if (environment == 'dev') {
    sh 'cp src/environments/environment.dev.ts src/environments/environment.ts'
} else if (environment == 'staging') {
    sh 'cp src/environments/environment.test.ts src/environments/environment.ts'
} else {
    echo "Unknown environment: ${environment}"
}