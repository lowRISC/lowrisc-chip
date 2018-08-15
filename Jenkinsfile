#!/usr/bin/env groovy

pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                def proc = 'git clone -b refresh-v0.6 --recursive https://github.com/lowrisc/lowrisc-chip.git lowrisc-chip-refresh-v0.6'.execute()
                Thread.start { System.err << proc.err }
                proc.waitForOrKill(1000)
                
            }
        }
        stage('Build') {
            steps {
                echo 'Building..'
/*
                def sout = new StringBuilder(), serr = new StringBuilder()
                def proc = 'cd lowrisc-chip-refresh-v0.6/rocket-chip/riscv-tools; bash ./build.sh'.execute()
                proc.consumeProcessOutput(sout, serr)
                proc.waitForOrKill(1000)
                println "out> $sout err> $serr"
*/                
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
