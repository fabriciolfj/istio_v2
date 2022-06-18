#o certificado precisa ficar no ns do istio
kubectl create -n istio-system secret tls webapp-credential \
--key /Users/fabriciojacob/Documents/repositorios/istio_v2/aula4/certs/3_application/private/webapp.istioinaction.io.key.pem \
--cert /Users/fabriciojacob/Documents/repositorios/istio_v2/aula4/certs/3_application/certs/webapp.istioinaction.io.cert.pem
