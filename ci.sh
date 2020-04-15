#!/bin/bash
echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
GO111MODULE="on" go get sigs.k8s.io/kind@v0.7.0
kind create cluster
kubectl cluster-info
kubectl get pods -A
echo "current-context:" $(kubectl config current-context)
echo "environment-kubeconfig:" ${KUBECONFIG}
curl -sSL https://cli.openfaas.com | sudo -E sh
kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
helm repo add openfaas https://openfaas.github.io/faas-netes/
helm upgrade openfaas --install openfaas/openfaas     --namespace openfaas      --set functionNamespace=openfaas-fn     --set generateBasicAuth=true
sleep 30 
kubectl port-forward --address 0.0.0.0 svc/gateway -n openfaas 8080:8080 &
kubectl get pods -A
export PASSWORD=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode)
echo -n $PASSWORD | faas-cli login --username=admin --password-stdin
faas-cli new faas-kind-ci --lang python3
cd faas-kind-ci/faas-kind-ci 
faas-cli up -f faas-kind-ci.yml --prefix=jrcichra
sleep 5
faas-cli up -f faas-kind-ci.yml --prefix=jrcichra