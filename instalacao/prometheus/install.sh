kubectl create ns prometheus
helm install prom prometheus-community/kube-prometheus-stack \
--version 37.2.0 -n prometheus