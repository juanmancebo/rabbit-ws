pipeline {
    agent any

    parameters {
        string(name: 'ENVIRONMENT', defaultValue: 'testing', description: 'Environment files to use for deployment')
        booleanParam(name: 'ApplyAutoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        booleanParam(name: 'DestroyAutoApprove', defaultValue: false, description: 'Automatically run destroy after Ansible deploy?')
    }
    
    environment {
        TF_IN_AUTOMATION            = "1"
        TF_INPUT                    = "0"
        TF_WORK_DIR                 = "terraform"
        TF_DATA_DIR                 = "${TF_WORK_DIR}/.terraform"
        //ENVIRONMENT                 = "${params.ENVIRONMENT}"
        PRIVATE_KEY_PATH            = "id_dsa_${params.ENVIRONMENT}"
        PUBLIC_DNS_PATH             = "public_dns_${params.ENVIRONMENT}"
        ANSIBLE_HOST_KEY_CHECKING   = "false"
        NAMESPACE                   = "rabbitmq"
        CHART_PROVIDER              = "bitnami"
        CHART_REPO                  = "https://charts.bitnami.com/bitnami"
        CHART_APP_NAME              = "rabbitmq"
        CHART_VERSION               = "7.6.7"
        AN_WORK_DIR                 = "ansible"
        KUBECONFIG                  = "${AN_WORK_DIR}/kube_config.yaml"
    }

    stages {
        stage('build') {
            steps {

                //sh "echo ENVIRONMENT:${params.Environment}"
                sh "env"
                sh 'chmod +x gradlew && ./gradlew clean build -x test --no-daemon'        
            }
            post {
                always {
                    archiveArtifacts artifacts: 'build/libs/**/*.jar', fingerprint: true
                }
            }
        }
        stage('test') {
            steps {
                sh 'chmod +x gradlew && ./gradlew clean test --no-daemon'
            }
            post {
                always {
                    junit 'build/test-results/**/*.xml'
                }
            }
        }

        stage('terraform-validate') {
            steps {
                sh "terraform init ${TF_WORK_DIR}"
                sh "terraform validate ${TF_WORK_DIR}"
            }
        }
        stage('terraform-plan') {
            steps {
                script {
                    currentBuild.displayName = params.ENVIRONMENT
                }
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh "terraform init ${TF_WORK_DIR}"
                    sh "terraform plan -out=${TF_WORK_DIR}/tfplan -var=private_key_path=${PRIVATE_KEY_PATH} -var=public_dns_path=${PUBLIC_DNS_PATH} -var-file=${TF_WORK_DIR}/environments/${ENVIRONMENT}.tfvars ${TF_WORK_DIR}"
                    sh "terraform show -no-color ${TF_WORK_DIR}/tfplan |tee ${TF_WORK_DIR}/tfplan.txt"
                }
            }
        }
        stage('terraform-apply-confirmation') {
            when {
                not {
                    equals expected: true, actual: params.ApplyAutoApprove
                }
            }

            steps {
                script {
                    def plan = readFile "${TF_WORK_DIR}/tfplan.txt"
                    input message: "Do you want to apply the plan?",
                        parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                }
            }
        }

        stage('terraform-apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh "terraform apply ${TF_WORK_DIR}/tfplan"
                    sh "terraform show -no-color |tee terraform.tfstate.txt"
                }
            }
        }
        stage('ansible-deploy') {
            steps {
                //sh 'PUBLIC_DNS=$(cat ${PUBLIC_DNS_PATH}) && echo "ansible-playbook -i ${PUBLIC_DNS}, --private-key ${PRIVATE_KEY_PATH} terraform/${AN_WORK_DIR}/httpd.yml"'
                sh 'PUBLIC_DNS=$(cat ${PUBLIC_DNS_PATH}) && ansible-playbook -i ${PUBLIC_DNS}, --private-key ${PRIVATE_KEY_PATH} ${AN_WORK_DIR}/kubernetes.yml'
                sh 'PUBLIC_DNS=$(cat ${PUBLIC_DNS_PATH}) && sed -i "s/127.0.0.1/${PUBLIC_DNS}/g; s/certificate-authority-data:.*/insecure-skip-tls-verify: true/g" ${AN_WORK_DIR}/kube_config.yaml'
                //sh 'ansible-galaxy collection install community.kubernetes'
                //sh 'PUBLIC_DNS=$(cat ${PUBLIC_DNS_PATH}) && ansible-playbook -i ${PUBLIC_DNS}, --private-key ${PRIVATE_KEY_PATH} ${AN_WORK_DIR}/rabbitmq/rabbitmq.yml'
                sh 'helm repo add ${CHART_PROVIDER} ${CHART_REPO}'
                sh 'helm install ${CHART_APP_NAME} ${CHART_PROVIDER}/${CHART_APP_NAME} -f rabbitmq/default_values.yaml -f rabbitmq/custom_values.yaml --create-namespace -n ${NAMESPACE}'
                sh '''#!/bin/bash
                        PUBLIC_DNS=$(cat ${PUBLIC_DNS_PATH})
                        source gradle.sh
                        env
                        ansible-playbook -i ${PUBLIC_DNS}, --private-key ${PRIVATE_KEY_PATH} ${AN_WORK_DIR}/spring-boot.yml --extra-vars "PUBLIC_DNS=${PUBLIC_DNS}"
                   '''              
                //ansiblePlaybook(installation: 'ansible', inventory: "${PUBLIC_DNS},", playbook: 'terraform/${AN_WORK_DIR}/httpd.yml', extras: "--private-key ${PRIVATE_KEY_PATH}")


            }
        }
        stage('terraform-destroy-confirmation') {
            when {
                not {
                    equals expected: true, actual: params.DestroyAutoApprove
                }
            }

            steps {
                script {
                    def destroy = readFile "terraform.tfstate.txt"
                    input message: "Are you sure to destroy this infraestructure?",
                        parameters: [text(name: 'Destroy', description: 'Destroy infraestructure confirmation', defaultValue: destroy)]
                }
            }
        }
        stage('terraform-destroy') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh "terraform destroy -var=private_key_path=${PRIVATE_KEY_PATH} -var=public_dns_path=${PUBLIC_DNS_PATH} -var-file=${TF_WORK_DIR}/environments/${ENVIRONMENT}.tfvars -auto-approve ${TF_WORK_DIR}"
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts "${TF_WORK_DIR}/tfplan.txt"
            archiveArtifacts "terraform.tfstate*"
        }
    }
}