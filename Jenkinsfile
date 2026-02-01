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
        APP_DIR     = '/opt/dbaalld01_project/deploy-dba_alld_project'
        COMPOSE     = 'docker compose -f docker-compose.app.yml'
    }

    stages {

        stage('Checkout Frontend') {
            steps {
                dir('frontend-src') {
                    git url: 'git@github.com:thinkvalleyacademy/DBA-SOFTWARE.git',
                        branch: 'main'
                }
            }
        }

        stage('Checkout Backend') {
            steps {
                dir('backend-src') {
                    git url: 'git@github.com:thinkvalleyacademy/alld-backend.git',
                        branch: 'main'
                }
            }
        }

        stage('Sync Code to Deploy Dir') {
            steps {
                sh """
                  ssh ${DEPLOY_USER}@${DEPLOY_HOST} '
                    mkdir -p ${APP_DIR}
                  '

                  rsync -az --delete frontend-src/ \
                    ${DEPLOY_USER}@${DEPLOY_HOST}:${APP_DIR}/frontend/

                  rsync -az --delete backend-src/ \
                    ${DEPLOY_USER}@${DEPLOY_HOST}:${APP_DIR}/backend/
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

        stage('Health Check') {
            steps {
                sh """
                  ssh ${DEPLOY_USER}@${DEPLOY_HOST} '
                    docker ps &&
                    curl -f http://localhost:5082 || exit 1
                  '
                """
            }
        }
    }

    post {
        success {
            echo "✅ ${params.ENV} deployment successful"
        }
        failure {
            echo "❌ Deployment failed"
        }
    }
}
