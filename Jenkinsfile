pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo 'Checkout..'
                git clone -b refresh-v0.6 --recursive https://github.com/lowrisc/lowrisc-chip.git lowrisc-chip-refresh-v0.6
            }
        }
        stage('Build') {
            steps {
                echo 'Building..'
                cd lowrisc-chip-refresh-v0.6/rocket-chip/riscv-tools/
                bash ./build.sh
                
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
