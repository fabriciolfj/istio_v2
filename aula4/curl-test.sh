curl -H "Host: webapp.istioinaction.io" \
https://webapp.istioinaction.io:443/api/catalog \
--cacert /Users/fabriciojacob/Documents/repositorios/istio_v2/aula4/certs/2_intermediate/certs/ca-chain.cert.pem \
--resolve webapp.istioinaction.io:443:10.102.146.250