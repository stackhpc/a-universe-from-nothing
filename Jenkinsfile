pipeline {
    options { disableConcurrentBuilds() }
    agent { label 'docker' }
    parameters {
        credentials credentialType: 'com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey', defaultValue: '', description: 'Kayobe SSH Key', name: 'KAYOBE_SSH_CREDS', required: true
        password defaultValue: 'SECRET', description: 'Kayobe Ansible Vault Password', name: 'KAYOBE_VAULT_PASSWORD'
        string defaultValue: 'http://localhost:5000/', description: 'Docker Registry to push images to', name: 'DOCKER_REGISTRY', trim: true
        credentials credentialType: 'org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl', defaultValue: '', description: 'Kayobe SSH Config file', name: 'KAYOBE_SSH_CONFIG', required: true
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
        stage('Deploy') {
            stages {
                stage('Prepare Secrets') {
                    environment {
                        KAYOBE_VAULT_PASSWORD = "${params.KAYOBE_VAULT_PASSWORD}"
                        KAYOBE_SSH_CONFIG_FILE = credentials("${params.KAYOBE_SSH_CONFIG}")
                        KAYOBE_SSH_CREDS_FILE = credentials("${params.KAYOBE_SSH_CREDS}")
                    }
                    steps {
                        sh 'mkdir -p secrets/.ssh'
                        sh "cp $KAYOBE_SSH_CONFIG_FILE secrets/.ssh/config"
                        sh "cp $KAYOBE_SSH_CREDS_FILE secrets/.ssh/id_rsa"
                        sh(returnStdout: false, script: 'ssh-keygen -y -f secrets/.ssh/id_rsa > secrets/.ssh/id_rsa.pub')
                        sh(returnStdout: false, script: 'echo $KAYOBE_VAULT_PASSWORD > secrets/vault.pass')
                    }
                }
                stage('Run Kayobe') {
                    agent {
                        docker {
                            image "$KAYOBE_IMAGE"
                            registryUrl "$REGISTRY"
                            reuseNode true
                        }
                    }
                    environment {
                        KAYOBE_VAULT_PASSWORD = "${params.KAYOBE_VAULT_PASSWORD}"
                    }
                    steps {
                        sh 'cp -R secrets/. /secrets'
                        sh '/bin/entrypoint.sh echo READY'
                        sh 'kayobe control host bootstrap'
                        sh 'kayobe overcloud inventory discover'
                        sh 'kayobe overcloud service reconfigure'
                    }
                }
            }
        }
    }
    post {
        cleanup {
            dir('secrets') {
                deleteDir()
            }
        }
   }
}
