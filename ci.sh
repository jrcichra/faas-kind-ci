#!/bin/bash
echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
go get sigs.k8s.io/kind
kind create cluster --config kind.yaml
kubectl cluster-info
kubectl get pods -A
echo "current-context:" $(kubectl config current-context)
echo "environment-kubeconfig:" ${KUBECONFIG}
curl -sSL https://cli.openfaas.com | sudo -E sh
kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
helm repo add openfaas https://openfaas.github.io/faas-netes/
helm upgrade openfaas --install openfaas/openfaas     --namespace openfaas      --set functionNamespace=openfaas-fn     --set generateBasicAuth=true
sleep 120 
nohup kubectl port-forward svc/gateway --address 0.0.0.0 -n openfaas 8080:8080 &
sleep 20
kubectl get pods -A
export PASSWORD=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode)
echo -n $PASSWORD | faas-cli login --username=admin --password-stdin
faas-cli new faas-kind-ci --lang python3 --prefix=jrcichra
cd faas-kind-ci/faas-kind-ci/
faas-cli up -f faas-kind-ci.yml 
sleep 5
faas-cli up -f faas-kind-ci.yml