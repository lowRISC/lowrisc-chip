#!/usr/bin/env groovy

pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                sh 'git clone -b refresh-v0.6 --recursive https://github.com/lowrisc/lowrisc-chip.git lowrisc-chip-refresh-v0.6'                
            }
        }
        stage('Build') {
            steps {
                echo 'Building..'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}
