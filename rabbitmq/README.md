# RabbitMQ HA deployment in k8s
[Reference chart](https://github.com/bitnami/charts/tree/master/bitnami/rabbitmq)

## Requirements
- kubernetes cluster
- helm3

## Global variables
```
NAMESPACE=rabbitmq
CHART_PROVIDER=bitnami
CHART_REPO=https://charts.bitnami.com/bitnami
CHART_APP_NAME=rabbitmq
CHART_VERSION=7.6.7
```

## Initialization
* Add chart repository
  ```
  helm repo add ${CHART_PROVIDER} ${CHART_REPO}
  helm repo update
  ```
* Get chart values
  ```
  helm inspect values ${CHART_PROVIDER}/${CHART_APP_NAME} --version ${CHART_VERSION} >default_values.yaml
  ```

## Installation
```
kubectl create ns ${NAMESPACE}
helm install ${CHART_APP_NAME} ${CHART_PROVIDER}/${CHART_APP_NAME} -f default_values.yaml -f custom_values.yaml -n ${NAMESPACE}
```

## Upgrade
```
export RABBITMQ_PASSWORD=$(kubectl get secret --namespace ${NAMESPACE} rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 --decode)
export RABBITMQ_ERLANG_COOKIE=$(kubectl get secret --namespace ${NAMESPACE} rabbitmq -o jsonpath="{.data.rabbitmq-erlang-cookie}" | base64 --decode)
helm upgrade ${CHART_APP_NAME} ${CHART_PROVIDER}/${CHART_APP_NAME} -f default_values.yaml -f custom_values.yaml --set auth.password=$RABBITMQ_PASSWORD --set auth.erlangCookie=$RABBITMQ_ERLANG_COOKIE -n ${NAMESPACE}
```
* Note: rabbitmq.conf and advanced.config changes take effect after a node restart.
```
kubectl rollout restart sts/rabbitmq -n ${NAMESPACE}
```

## Tear down
```
helm del ${CHART_APP_NAME} -n ${NAMESPACE}
kubectl delete ns ${NAMESPACE}
```
