// Perform various regression runs after a checkin

pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo 'Checkout..'
                sh 'make -f jenkins/Makefile Checkout'
            }
        }
        stage('Build') {
            steps {
                echo 'Building..'
                sh 'make -f jenkins/Makefile Build'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
                sh 'make -f jenkins/Makefile Test'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
                sh 'make -f jenkins/Makefile Deploy'
            }
        }
    }
}
