pipeline {
    agent any
    parameters{
        string(name: 'GIT_URL', defaultValue: '', description: 'GIT URL')
        string(name: 'DOCKER_USER', defaultValue: 'neeabhishek@gmail.com', description: 'Docker User')
        password(name: 'DOCKER_PASS', defaultValue: 'pkhR0adlqx@123#', description: 'Docker Password')
    }

    stages{
        stage('Cloning the Repository') {
            steps {
                echo "** Cloning the source-code"
                git branch: 'main', credentialsId: 'GIT-CRED', url: params.GIT_URL 
            }
        }

        stage('Setting up the setUpShell') {
            steps {
                echo "**** Passing values to variables ****"
                def WORKSPACE = env.WORKSPACE
                def DOCKER_USER = params.DOCKER_USER
                def DOCKER_PASS = params.DOCKER_PASS
                sh """
                    cd ${WORKSPACE}/IaC/modules/aws_machine/ && \
                    sed -i 's/^DOCKER_USER="[^"]*"/DOCKER_USER="'"${DOCKER_USER}"'"/' setHostDep.sh && \
                    sed -i 's/^DOCKER_PASS="[^"]*"/DOCKER_PASS="'"${DOCKER_PASS}"'"/' setHostDep.sh && \
                    chmod -R 755 setHostDep.sh 
                """
                echo "**** Activity done, exiting from the stage ****"
                
            }
        }

        stage('Terraform Init and Plan creation') {
            steps {
                script {
                    def WORKSPACE = env.WORKSPACE
                    def DOCKER_USER = params.DOCKER_USER
                    def DOCKER_PASS = params.DOCKER_PASS
                    echo "***** Init and Plan the Terraform Configuration *****"
                    sh """
                        cd ${WORKSPACE}/IaC/ && \
                        terraform init && \
                        sleep 4 && \
                        terraform plan && \
                        sleep 4
                    """    
                }
            }
        }
        stage('Generating Visual representation of the Infrastructure') {
            steps{
                script {
                    def WORKSPACE = env.WORKSPACE
                    echo "**** Generating the visual representation of the Infa ****"
                    sh """
                         cd ${WORKSPACE}/IaC/ && \
                         terraform graph | dot -Tsvg > graph.svg 
                    """
                }
            }
        }
        stage('Applying the Infrastructure') {
            steps{
                script {
                    def WORKSPACE = env.WORKSPACE
                    echo "**** Creating the Infrastructure ****"
                    sh """
                         cd ${WORKSPACE}/IaC/ && \
                         terraform apply -auto-approve 
                    """
                }
            }
        }
    }
}
