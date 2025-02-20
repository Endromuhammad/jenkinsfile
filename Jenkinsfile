#!/usr/bin/env groovy
// vim: sw=4 ts=4

pipeline {
    environment {
        // Semantic Versioning
        int VERSION_MAJOR = 1
        int VERSION_MINOR = 0
        int VERSION_PATCH = 0

        // Params
        String APP = 'maple'
        String SERVICE = 'be-domain-order'
        String ENVIRONMENT = 'uat'
        String GIT_BRANCH = 'release/uat'
        String GIT_CREDENTIALS_ID = 'jenkins-dev'
        String IMAGE_REPO = 'asia-southeast2-docker.pkg.dev/it-infrastructure-service'
        String IMAGE_ENV = 'uat'
        String MAIL_TO = 'v.irkham.hidayat@adira.co.id v.muhammad.haikal@adira.co.id'

        // Sonarqube Params
        String SONAR_ENV = 'sonarqube'

        // Kubernetes Params
        String KUBE_CONFIG = 'mapl-nonprod-hwc'
        String KUBE_NAMESPACE = 'mapl-uat'

        // Auto Generated Params
        String DEPLOYMENT_DIR = "${WORKSPACE}/${APP}/${SERVICE}"
        String SOURCE_DIR = "${WORKSPACE}/source"
        String HELM_CHART = "${DEPLOYMENT_DIR}/adira-one"
        String DOCKERFILE = "${DEPLOYMENT_DIR}/Dockerfile"
        String IMAGE_NAME = "${IMAGE_REPO}/${IMAGE_ENV}/${SERVICE}"
        String IMAGE_TAG = "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}-${BUILD_TIMESTAMP}-${BUILD_NUMBER}"
        String SONAR_PROJECT_NAME = "${ENVIRONMENT}:${APP}:${SERVICE}"
        String SONAR_PROJECT_KEY = "${ENVIRONMENT}:${APP}:${SERVICE}"
    }

    agent {
        kubernetes {
            defaultContainer 'jnlp'
            inheritFrom 'default'
            yamlMergeStrategy merge()
            yaml '''
                spec:
                  containers:
                    - name: maven
                      image: maven:3.8.4-openjdk-17
                      command:
                        - cat
            '''
        }
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                dir("${SOURCE_DIR}") {
                    git([
                        branch: "${GIT_BRANCH}",
                        credentialsId: "${GIT_CREDENTIALS_ID}",
                        url: "https://bitbucket.org/adira-it/${SERVICE}"
                    ])
                }
            }
        }

        stage('Build') {
            steps {
                dir("${SOURCE_DIR}") {
                    container('maven') {
                        sh '''
                            mvn clean package --quiet -DskipTests
                        '''
                    }
                }
            }
        }

        // stage('Analyze') {
        //     steps {
        //         dir("${SOURCE_DIR}") {
        //             container('sonarqube') {
        //                 withSonarQubeEnv("${SONAR_ENV}") {
        //                     sh """
        //                         sonar-scanner \
        //                           -Dproject.settings="${SONAR_SETTINGS}" \
        //                           -Dsonar.projectName="${SONAR_PROJECT_NAME}" \
        //                           -Dsonar.projectKey="${SONAR_PROJECT_KEY}"
        //                     """
        //                 }
        //             }
        //         }
        //     }
        // }

        stage('Build & Push Image') {
            steps {
                dir("${SOURCE_DIR}") {
                    container('kaniko') {
                        sh """
                            cp --recursive --force \
                              --no-target-directory ${DEPLOYMENT_DIR} ${SOURCE_DIR}
                            cp --recursive --force \
                              --no-target-directory ${WORKSPACE}/resources ${SOURCE_DIR}/resources
                            executor \
                              --destination="${IMAGE_NAME}:${IMAGE_TAG}" \
                              --dockerfile="${DOCKERFILE}" \
                              --log-format=text \
                              --context="${SOURCE_DIR}"
                        """
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                dir("${SOURCE_DIR}") {
                    container('k8s') {
                        withKubeConfig(credentialsId: "${KUBE_CONFIG}", namespace: "${KUBE_NAMESPACE}", restrictKubeConfigAccess: true) {
                            sh """
                                helm repo add adira https://adira-it.bitbucket.io/charts
                                helm template ${SERVICE} adira/adira-one \
                                  --set=image.tag=${IMAGE_TAG} \
                                  --version=1.2.6 \
                                  --values=values.yaml \
                                  | kubectl apply -f -
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            emailext(
                attachLog: true,
                subject: '$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS!',
                body: '${JELLY_SCRIPT,template="html"}',
                to: "${MAIL_TO}"
            )
        }
    }
}
