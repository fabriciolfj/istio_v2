# Istio
- função de facilitar a remoção de códigos de rede dos aplicativos
- fazer roteamento com base em metadados externos que fazem parte da solicitação
- controle de tráfico e roteamento de baixa granularidade
- protege e impõe políticas de cotas de uso
```
istioctl install --set profile=demo -y
kubectl apply -f ./samples/addons
kubectl label namespace istioinaction istio-injection=enabled
```

### Plano de controle
- fornece maneiras para o usuário controlar, observar, gerenciar e configurar a malha
- é implementado pelo istiod, que pega as configurações especificadas pelo usuário, que são expresas através de recursos

### Gerenciamento de identidade
- quando 2 serviços se comunicam dentro da malha, os proxies de ambos de comunicam, podemos encriptar o tráfego atráves de certificados x.509

### Gateway do istio
- após aplicar o manifesto ingress-gateway.yaml, execute o tunnel minikube e o script abaixo para pegar o endpoint
```
kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
- para acessar o dashboard do grafana por exemplo, podemos executar o comando:
```
istioctl dashboard grafana
```

### Resiliência no istio
- podemos configurar um virtualService e nas propriedades de rota, incluir a configuração abaixo:
```
  http:
  - route:
    - destination:
        host: webapp
        port:
          number: 80
    retries: aqui
      attempts: 3 aqui
      perTryTimeout: 2s aqui
```

### DestinationRule
- quando temos mais de uma versão da nossa api, podemos direcionar a mesma via DestinationRule
```
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: catalog
spec:
  host: catalog
  subsets:
  - name: version-v1
    labels:
      version: v1
  - name: version-v2
    labels:
      version: v2
```

### Envoy
- é um proxy 
- proxy é um componente que fica no meio da comunicação entre cliente e servidor
- proxy tem a função
