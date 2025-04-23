pipeline {
    agent any

    triggers {
        pollSCM('H/5 * * * *') // Резервный триггер
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/master']],
                    extensions: [],
                    userRemoteConfigs: [[
                        credentialsId: 'github-token', // УКАЖИТЕ ВАШ REAL ID ЗДЕСЬ
                        url: 'https://github.com/stds58/project_work_11_ci.git'
                    ]]
                ])
            }
        }

        stage('Build') {
            steps {
                sh 'docker build -t nginx-ci .'
            }
        }

        stage('Deploy') {
            steps {
                sh 'docker stop nginx-ci || true'
                sh 'docker rm nginx-ci || true'
                sh 'docker run -d -p 9889:80 --name nginx-ci nginx-ci'
            }
        }

        stage('Verify') {
            steps {
                sh '''
                curl -sSf http://localhost:9889 || {
                    echo "Nginx не отвечает"
                    exit 1
                }
                '''
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f'
        }
        failure {
            sh '''
            curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
                -d "chat_id=$TELEGRAM_CHAT_ID&text=❌ CI Failed: ${BUILD_URL}"
            '''
        }
    }
}