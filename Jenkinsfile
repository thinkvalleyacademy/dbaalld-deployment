pipeline {
  agent none

  options {
    disableConcurrentBuilds()
    timeout(time: 30, unit: 'MINUTES')
    timestamps()
  }

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
    TAG         = "${BUILD_NUMBER}"
  }

  stages {

    stage('Resolve Environment') {
      agent { label 'built-in' }
      steps {
        script {
          env.FRONTEND_BRANCH = params.ENV == 'prod' ? 'main' : 'main_dev'
          env.BACKEND_BRANCH  = params.ENV == 'prod' ? 'main' : 'main_dev'

          echo "ENV            : ${params.ENV}"
          echo "Frontend branch: ${env.FRONTEND_BRANCH}"
          echo "Backend branch : ${env.BACKEND_BRANCH}"
          echo "Image TAG      : ${TAG}"
        }
      }
    }

    stage('Checkout Repositories') {
      agent { label 'built-in' }
      steps {
        dir('frontend-src') {
          git branch: env.FRONTEND_BRANCH,
              url: 'git@github.com:thinkvalleyacademy/DBA-SOFTWARE.git'
        }

        dir('backend-src') {
          git branch: env.BACKEND_BRANCH,
              url: 'git@github.com:thinkvalleyacademy/alld-backend.git'
        }
      }
    }

    stage('Sync Code to App Directory') {
      agent { label 'built-in' }
      steps {
        sh '''
          rsync -az --delete frontend-src/ \
            ${DEPLOY_USER}@${DEPLOY_HOST}:${APP_DIR}/frontend-src/

          rsync -az --delete backend-src/ \
            ${DEPLOY_USER}@${DEPLOY_HOST}:${APP_DIR}/backend-src/
        '''
      }
    }

    stage('Build Docker Images (limited)') {
      agent { label 'built-in' }
      steps {
        sh '''
          ssh ${DEPLOY_USER}@${DEPLOY_HOST} '
            set -e
            cd ${APP_DIR}

            export TAG=${TAG}

            docker compose \
              -f docker-compose.app.yml \
              --env-file ${APP_DIR}/env/common.env \
              --env-file ${APP_DIR}/env/${ENV}.env \
              build
          '
        '''
      }
    }

    stage('Deploy') {
      agent { label 'built-in' }
      steps {
        sh '''
          ssh ${DEPLOY_USER}@${DEPLOY_HOST} '
            set -e
            cd ${APP_DIR}

            export TAG=${TAG}

            docker compose \
              -f docker-compose.app.yml \
              --env-file ${APP_DIR}/env/common.env \
              --env-file ${APP_DIR}/env/${ENV}.env \
              up -d
          '
        '''
      }
    }
  }

post {
  success {
    echo "✅ ${params.ENV.toUpperCase()} deployment successful"
  }
  failure {
    echo "❌ Deployment failed"
  }
  always {
    node('built-in') {
      cleanWs()
    }
  }
}


}

