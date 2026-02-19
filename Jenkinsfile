pipeline {
    agent any

    stages {
        stage('Backend') {
            agent {
                docker { image 'node:20-alpine' }
            }
            steps {
                dir('backend') {
                    withCredentials([file(credentialsId: 'backend_env', variable: 'BACKEND_ENV_FILE')]) {
                        // Copy the secret file to .env
                        sh 'cp $BACKEND_ENV_FILE .env'
                        // Alpine images might need --unsafe-perm for some npm packages or simple install
                        sh 'npm install'
                        sh 'npm test'
                    }
                }
            }
        }

        stage('Frontend') {
            agent {
                docker { image 'ghcr.io/cirruslabs/flutter:stable' }
            }
            steps {
                dir('frontend') {
                    withCredentials([file(credentialsId: 'frontend_env', variable: 'FRONTEND_ENV_FILE')]) {
                        // Copy the secret file to .env
                        sh 'cp $FRONTEND_ENV_FILE .env'
                        // Fix permission issues if any, usually okay in these images
                        sh 'flutter pub get'
                        sh 'flutter test'
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
        }
        failure {
            echo 'Pipeline failed.'
        }
        success {
            echo 'Pipeline succeeded.'
        }
    }
}
