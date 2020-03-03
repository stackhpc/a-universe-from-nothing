pipeline {
    options { disableConcurrentBuilds() }
    agent { label 'docker' }
    parameters {
        credentials credentialType: 'com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey', defaultValue: '', description: 'Kayobe SSH Key', name: 'KAYOBE_SSH_CREDS', required: true
        password defaultValue: 'SECRET', description: 'Kayobe Ansible Vault Password', name: 'KAYOBE_VAULT_PASSWORD'
        string defaultValue: 'http://localhost:5000/', description: 'Docker Registry to push images to', name: 'DOCKER_REGISTRY', trim: true
        file description: 'Kayobe Custom SSH config', name: 'secrets/.ssh/config'
    }
    environment {
        REGISTRY = "${params.DOCKER_REGISTRY}"
        KAYOBE_IMAGE = "${currentBuild.projectName}:${env.GIT_COMMIT}"
    }
    stages {
        stage('Build and Push') {
            steps {
                script {
                    def kayobeImage = docker.build("$KAYOBE_IMAGE")
                    docker.withRegistry("$REGISTRY") {
                        kayobeImage.push()
                        kayobeImage.push('latest')
                    }
                }
            }
        }
        stage('Run') {
            agent {
                docker {
                    image "$KAYOBE_IMAGE"
                    registryUrl "$REGISTRY"
                    args '-v $WORKSPACE/secrets:/secrets'
                }
            }
            environment {
                KAYOBE_VAULT_PASSWORD = "${params.KAYOBE_VAULT_PASSWORD}"
                KAYOBE_SSH_CONFIG = "${params.KAYOBE_SSH_CONFIG}"
            }
            steps {
                sshagent (credentials: ["${params.KAYOBE_SSH_CREDS}"]) {
                    sh 'kayobe control host bootstrap'
                    sh 'kayobe overcloud inventory discover'
                    sh 'kayobe overcloud host command run --command "hostname" -v'
                }
            }
        }
    }
}
