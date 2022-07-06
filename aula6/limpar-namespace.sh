kubectl config set-context $(kubectl config current-context) \
 --namespace=istioinaction

kubectl delete virtualservice,deployment,service,\
destinationrule,gateway --all