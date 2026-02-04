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
    TAG         = "${env.BUILD_NUMBER}"
  }

  stages {

    stage('Resolve Environment') {
      steps {
        script {
          env.FRONTEND_BRANCH = (params.ENV == 'prod') ? 'main' : 'main_dev'
          env.BACKEND_BRANCH  = (params.ENV == 'prod') ? 'main' : 'main_dev'

          echo "🚀 ENV            : ${params.ENV}"
          echo "📦 Frontend branch: ${env.FRONTEND_BRANCH}"
          echo "📦 Backend branch : ${env.BACKEND_BRANCH}"
          echo "🏷️  Image TAG     : ${TAG}"
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
          rsync -az --delete frontend-src/ \
            ${DEPLOY_USER}@${DEPLOY_HOST}:${APP_DIR}/frontend-src/

          rsync -az --delete backend-src/ \
            ${DEPLOY_USER}@${DEPLOY_HOST}:${APP_DIR}/backend-src/
        """
      }
    }

    stage('Build Images (rootless docker on server)') {
      steps {
        sh """
          ssh ${DEPLOY_USER}@${DEPLOY_HOST} '
            set -e
            cd ${APP_DIR}

            TAG=${TAG} docker compose \
              --env-file env/common.env \
              --env-file env/${params.ENV}.env \
              build backend frontend
          '
        """
      }
    }

    stage('Deploy') {
      steps {
        sh """
          ssh ${DEPLOY_USER}@${DEPLOY_HOST} '
            set -e
            cd ${APP_DIR}

            TAG=${TAG} docker compose \
              --env-file env/common.env \
              --env-file env/${params.ENV}.env \
              up -d
          '
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

