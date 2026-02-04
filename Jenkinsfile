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

        stage('Resolve Environment') {
            steps {
                script {
                    if (params.ENV == 'dev') {
                        env.FRONTEND_BRANCH = 'main_dev'
                        env.BACKEND_BRANCH  = 'main_dev'
                    } else if (params.ENV == 'prod') {
                        env.FRONTEND_BRANCH = 'main'
                        env.BACKEND_BRANCH  = 'main'
                    }else{
			error("Unknown ENV: ${params.ENV}")	
		}

                    echo "🚀 ENV            : ${params.ENV}"
                    echo "📦 Frontend branch: ${env.FRONTEND_BRANCH}"
                    echo "📦 Backend branch : ${env.BACKEND_BRANCH}"
                }
            }
        }

        stage('Checkout Frontend') {
            steps {
                dir('frontend-src') {
                    git branch: env.FRONTEND_BRANCH,
                        url: 'git@github.com:thinkvalleyacademy/DBA-SOFTWARE.git'
                }
            }
        }

        stage('Checkout Backend') {
            steps {
                dir('backend-src') {
                    git branch: env.BACKEND_BRANCH,
                        url: 'git@github.com:thinkvalleyacademy/alld-backend.git'
                }
            }
        }

        stage('Sync Code to Server') {
            steps {
                sh """
                  ssh ${DEPLOY_USER}@${DEPLOY_HOST} '
                    mkdir -p ${APP_DIR}/frontend/app
                    mkdir -p ${APP_DIR}/backend/app
                  '

                  rsync -az --delete frontend-src/ \
                    ${DEPLOY_USER}@${DEPLOY_HOST}:${APP_DIR}/frontend/app/

                  rsync -az --delete backend-src/ \
                    ${DEPLOY_USER}@${DEPLOY_HOST}:${APP_DIR}/backend/app/

                  # 🛡️ Safety: remove nested git repos if any
                  ssh ${DEPLOY_USER}@${DEPLOY_HOST} '
                    rm -rf ${APP_DIR}/frontend/app/.git
                    rm -rf ${APP_DIR}/backend/app/.git
                  '
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
            echo "✅ ${params.ENV.toUpperCase()} deployment successful"
        }
        failure {
            echo "❌ ${params.ENV.toUpperCase()} deployment failed"
        }
    }
}

