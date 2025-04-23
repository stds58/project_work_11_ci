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
        // Копируем необходимые файлы из Ansible роли в рабочую директорию
        sh '''
            mkdir -p docker-build
            cp ansible/roles/docker/files/Dockerfile docker-build/
            cp ansible/roles/docker/files/index.html docker-build/
        '''

        // Собираем Docker образ с указанием правильного контекста
        dir('docker-build') {
            sh 'docker build -t nginx-ci .'
        }
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
            // Проверка HTTP-статуса
            def httpStatus = sh(
                script: 'curl -s -o /dev/null -w "%{http_code}" http://localhost:9889',
                returnStdout: true
            ).trim()

            // Получаем MD5 локального файла
            def localMd5 = sh(
                script: "md5sum docker-build/index.html | awk '{print \$1}'",
                returnStdout: true
            ).trim()

            // Получаем MD5 удаленного файла
            def remoteMd5 = sh(
                script: "curl -s http://localhost:9889 | md5sum | awk '{print \$1}'",
                returnStdout: true
            ).trim()

            echo "Результаты проверки: HTTP=${httpStatus}, localMD5=${localMd5}, remoteMD5=${remoteMd5}"

            // Явное сравнение результатов
            if (httpStatus != "200") {
                error("HTTP проверка не пройдена: статус ${httpStatus}")
            }
            if (localMd5 != remoteMd5) {
                error("MD5 проверка не пройдена: local=${localMd5} remote=${remoteMd5}")
            }

            echo "Проверка успешно пройдена"
        }
    }
}
    }

    post {
    always {
        // Архивируем правильный файл
        archiveArtifacts artifacts: 'docker-build/index.html', fingerprint: true

        // Очистка Docker
        sh 'docker system prune -f'
    }
    failure {
        // Оповещение в Telegram (исправленная версия)
        script {
            withCredentials([
                string(credentialsId: 'TELEGRAM_BOT_TOKEN', variable: 'BOT_TOKEN'),
                string(credentialsId: 'TELEGRAM_CHAT_ID', variable: 'CHAT_ID')
            ]) {
                sh '''
                    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
                    -d "chat_id=${CHAT_ID}&text=❌ CI Failed: ${env.BUILD_URL}"
                '''
            }
        }
    }
    success {
        // Оповещение об успехе
        script {
            withCredentials([
                string(credentialsId: 'TELEGRAM_BOT_TOKEN', variable: 'TELEGRAM_BOT_TOKEN'),
                string(credentialsId: 'TELEGRAM_CHAT_ID', variable: 'TELEGRAM_CHAT_ID')
            ]) {
                sh '''
                    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                    -d "chat_id=${TELEGRAM_CHAT_ID}&text=✅ CI Success: ${env.BUILD_URL}"
                '''
            }
        }
    }
}
}
