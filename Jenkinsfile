// Perform various regression runs after a checkin

pipeline {
    agent any

    stages {
        stage('Clean') {
            steps {
                echo 'Clean..'
                sh 'make -C jenkins Clean'
            }
        }
        stage('Checkout') {
            steps {
                echo 'Checkout..'
                sh 'make -C jenkins Checkout'
            }
        }
        stage('Build') {
            steps {
                echo 'Building..'
                sh 'make -C jenkins Build'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
                sh 'make -C jenkins Test'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
                sh 'make -C jenkins Deploy'
            }
        }
    }
}
