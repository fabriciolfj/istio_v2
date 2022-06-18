kubectl create -n istio-system secret \
generic webapp-credential-mtls --from-file=tls.key=\
/Users/fabriciojacob/Documents/repositorios/istio_v2/aula4/certs/3_application/private/webapp.istioinaction.io.key.pem \
--from-file=tls.crt=\
/Users/fabriciojacob/Documents/repositorios/istio_v2/aula4/certs/3_application/certs/webapp.istioinaction.io.cert.pem \
--from-file=ca.crt=aula4/certs/2_intermediate/certs/ca-chain.cert.pem