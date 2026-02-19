pipeline {
    agent any

    stages {
        stage('Backend') {
            steps {
                dir('backend') {
                    // Install backend dependencies
                    // Using 'ci' for cleaner, deterministic installs in CI environments, 
                    // or 'install' if lockfile issues arise.
                    sh 'npm install'
                    
                    // Run backend tests
                    sh 'npm test'
                }
            }
        }

        stage('Frontend') {
            steps {
                dir('frontend') {
                    // Install frontend dependencies
                    sh 'flutter pub get'
                    
                    // Run frontend unit and widget tests
                    // Integration tests are excluded here as they might require a connected device/emulator
                    sh 'flutter test'
                }
            }
        }
    }

    post {
        always {
            // Clean up or simple notification
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
