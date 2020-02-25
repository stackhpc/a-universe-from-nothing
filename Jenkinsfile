pipeline {
    agent { dockerfile true }
    stages {
        stage('Test') {
            steps {
                sh 'kayobe configuration dump'
            }
        }
    }
}
