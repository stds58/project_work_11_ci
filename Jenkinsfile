pipeline {
    agent any

    // Триггер при изменении index.html
    triggers {
        pollSCM('H/5 * * * *')  // Резервный триггер (каждые 5 минут)
    }

    environment {
        // Настройки для Telegram (добавьте в Jenkins Credentials)
        TELEGRAM_BOT_TOKEN = credentials('telegram-bot-token')
        TELEGRAM_CHAT_ID = credentials('telegram-chat-id')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/master']],
                    extensions: [[
                        $class: 'PathRestriction',
                        includedRegions: 'index.html'  // Триггер только при изменении index.html
                    ]],
                    userRemoteConfigs: [[
                        credentialsId: 'github-token',
                        url: 'https://github.com/stds58/project_work_11_ci.git'
                    ]]
                ])
            }
        }

        stage('Build') {
            steps {
                sh 'docker build -t nginx-ci -f /opt/ci-project/Dockerfile .'
            }
        }

        stage('Stop Old Container') {
            steps {
                script {
                    try {
                        sh 'docker stop nginx-ci || true'
                        sh 'docker rm nginx-ci || true'
                    } catch (err) {
                        echo "Ошибка при остановке контейнера: ${err}"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                sh 'docker run -d -p 9889:80 --name nginx-ci nginx-ci'
            }
        }

        stage('Verify') {
            steps {
                script {
                    // Проверка кода ответа
                    def status = sh(
                        script: 'curl -s -o /dev/null -w "%{http_code}" http://localhost:9889',
                        returnStdout: true
                    ).trim()

                    // Проверка MD5 (сравнение локального и удалённого файла)
                    def localMd5 = sh(
                        script: "md5sum index.html | awk '{print \$1}'",
                        returnStdout: true
                    ).trim()

                    def remoteMd5 = sh(
                        script: "curl -s http://localhost:9889 | md5sum | awk '{print \$1}'",
                        returnStdout: true
                    ).trim()

                    if (status != '200' || localMd5 != remoteMd5) {
                        error("Проверка не пройдена. HTTP: ${status}, MD5: local=${localMd5} remote=${remoteMd5}")
                    }
                }
            }
        }
    }

    post {
        always {
            // Очистка Docker
            sh 'docker system prune -f'

            // Логирование
            archiveArtifacts artifacts: 'index.html', fingerprint: true
        }

        failure {
            // Оповещение в Telegram
            script {
                def message = """
                ❌ CI Failed
                Build: ${env.BUILD_URL}
                Причина: ${currentBuild.currentResult}
                Изменения: ${env.GIT_COMMIT}
                """

                sh """
                curl -s -X POST \
                "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                -d "chat_id=${TELEGRAM_CHAT_ID}&text=${message}"
                """
            }
        }

        success {
            // Оповещение об успехе
            script {
                sh """
                curl -s -X POST \
                "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                -d "chat_id=${TELEGRAM_CHAT_ID}&text=✅ CI Success: ${env.BUILD_URL}"
                """
            }
        }
    }
}
