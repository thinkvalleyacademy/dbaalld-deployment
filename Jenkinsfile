pipeline {
    agent any

    parameters {
        choice(
            name: 'ENV',
            choices: ['dev', 'prod'],
            description: 'Deployment environment'
        )
        booleanParam(
            name: 'ROLLBACK',
            defaultValue: false,
            description: 'Rollback to previous image'
        )
    }

    environment {
        DEPLOY_USER = 'dbadev01'
        DEPLOY_HOST = 'localhost'
        APP_DIR     = '/opt/dbaalld01_project/deploy-dba_alld_project'
        COMPOSE     = 'docker compose -f docker-compose.app.yml'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify SSH') {
            steps {
                sh """
                  ssh ${DEPLOY_USER}@${DEPLOY_HOST} 'whoami && docker version'
                """
            }
        }

        stage('Build Images') {
            when { expression { !params.ROLLBACK } }
            steps {
                sh """
                  ssh ${DEPLOY_USER}@${DEPLOY_HOST} '
                    cd ${APP_DIR} &&
                    ${COMPOSE} \
                      --env-file env/common.env \
                      --env-file env/${ENV}.env \
                      build
                  '
                """
            }
        }

        stage('Deploy') {
            steps {
                sh """
                  ssh ${DEPLOY_USER}@${DEPLOY_HOST} '
                    cd ${APP_DIR} &&
                    ${COMPOSE} \
                      --env-file env/common.env \
                      --env-file env/${ENV}.env \
                      up -d
                  '
                """
            }
        }

        stage('Health Check') {
            steps {
                sh """
                  ssh ${DEPLOY_USER}@${DEPLOY_HOST} '
                    cd ${APP_DIR} &&
                    docker ps
                  '
                """
            }
        }
    }

    post {
        success {
            echo "✅ Deployment to ${params.ENV} successful"
        }
        failure {
            echo "❌ Deployment failed"
        }
    }
}
