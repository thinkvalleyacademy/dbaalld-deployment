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
        TAG = "${BUILD_NUMBER}"
        DEPLOY_DIR = "/home/dbadev01/dba-dev-testing/deploy-dba_alld_project"
    }

    stages {

        stage('Resolve Environment') {
            steps {
                script {
                    env.FRONTEND_BRANCH = params.ENV == 'prod' ? 'main' : 'main_dev'
                    env.BACKEND_BRANCH  = params.ENV == 'prod' ? 'main' : 'main_dev'

                    echo "🚀 ENV            : ${params.ENV}"
                    echo "📦 Frontend branch: ${env.FRONTEND_BRANCH}"
                    echo "📦 Backend branch : ${env.BACKEND_BRANCH}"
                    echo "🏷️  Image TAG     : ${TAG}"
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

        stage('Checkout Frontend') {
            steps {
                dir('frontend-src') {
                    git branch: env.FRONTEND_BRANCH,
                        url: 'git@github.com:thinkvalleyacademy/DBA-SOFTWARE.git'
                }
            }
        }

        stage('Build Backend Image') {
            steps {
                dir('backend-src') {
                    sh """
                      docker build \
                        -t dba-backend:${TAG} \
                        .
                    """
                }
            }
        }

        stage('Build Frontend Image') {
            steps {
                dir('frontend-src') {
                    sh """
                      docker build \
                        -t dba-frontend:${TAG} \
                        .
                    """
                }
            }
        }

        stage('Deploy') {
            steps {
                sh """
                  cd ${DEPLOY_DIR}

                  export TAG=${TAG}
                  export ENV=${params.ENV}

                  docker compose \
                    --env-file env/common.env \
                    --env-file env/${ENV}.env \
                    up -d --force-recreate
                """
            }
        }
    }

    post {
        success {
            echo "✅ ${params.ENV.toUpperCase()} deployment successful (TAG=${TAG})"
        }
        failure {
            echo "❌ Deployment failed"
        }
    }
}

