pipeline {
  agent any

  parameters {
    choice(name: 'ENV', choices: ['dev','prod'])
  }

  environment {
    TAG = "${env.BUILD_NUMBER}"
  }

  stages {

    stage('Build Backend') {
      steps {
        dir('backend') {
          git branch: params.ENV == 'prod' ? 'main' : 'main_dev',
              url: 'git@github.com:thinkvalleyacademy/alld-backend.git'
          sh "docker build -t dba-backend:${TAG} ."
        }
      }
    }

    stage('Build Frontend') {
      steps {
        dir('frontend') {
          git branch: params.ENV == 'prod' ? 'main' : 'main_dev',
              url: 'git@github.com:thinkvalleyacademy/DBA-SOFTWARE.git'
          sh "docker build -t dba-frontend:${TAG} ."
        }
      }
    }

    stage('Deploy') {
      steps {
        sh """
          export TAG=${TAG}
          docker compose up -d
        """
      }
    }
  }
}

