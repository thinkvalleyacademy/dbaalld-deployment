pipeline {
    agent any

    parameters {
        choice(
            name: 'ENV',
            choices: ['dev', 'prod'],
            description: 'Deployment environment'
        )
    }

    environment {
        DEPLOY_USER = 'dbadev01'
        DEPLOY_HOST = 'localhost'
        APP_DIR     = '/home/dbadev01/dba-dev-testing/deploy-dba_alld_project'
        COMPOSE     = 'docker compose -f docker-compose.app.yml'
    }

    stages {

        stage('Checkout Frontend') {
            steps {
                dir('frontend-src') {
                    git branch: 'main',
                        url: 'git@github.com:thinkvalleyacademy/DBA-SOFTWARE.git'
                }
            }
        }

        stage('Checkout Backend') {
            steps {
                dir('backend-src') {
                    git branch: 'main',
                        url: 'git@github.com:thinkvalleyacademy/alld-backend.git'
                }
            }
        }

        stage('Sync Code to Server') {
            steps {
                sh """
                  ssh ${DEPLOY_USER}@${DEPLOY_HOST} 'mkdir -p ${APP_DIR}'

                  rsync -az --delete frontend-src/ \
                    ${DEPLOY_USER}@${DEPLOY_HOST}:${APP_DIR}/frontend/app/

                  rsync -az --delete backend-src/ \
                    ${DEPLOY_USER}@${DEPLOY_HOST}:${APP_DIR}/backend/app/
                """
            }
        }

        stage('Build Images') {
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
