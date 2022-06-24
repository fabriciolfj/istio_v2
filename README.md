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
- proxy pode possuir algumas funções, como:
  - balancedor de carga
  - verificar integridade das instâncias no cluster e rotear o tráfego
- proxy envoy é especificamente um proxy de nível de aplicativo, que podemos inserir no caminho de solicitações
- podemos adicionar alguns comportamentos no envoy, como: circuit breaker, time limit, retry e etc.
- envoy pode coletar dados de telemetria

#### Alguns recursos do envoy
- Service discovery
- Load balancing
- Roteamento de tráfego e solicitação
- Deslocamento de tráfego e sombreamento de tráfego
  - deslocamento -> uso em entregas, como versão canary
  - sombreamento -> divisão do trafego, onde o serviço implantado, receberá cópias do tráfego. Ideal para testar serviços em produção, sem afetar o usuário
- Resiliência de rede
- Observabilidade
- Tracing
- Limitação de taxa

##### Exemplo
- neste projeto na pasta aula2, temos a configuração de um proxy envoy, onde redireciona toda requisição para o serviço httpbin

# Gateway
- Para o cliente fora do cluster acessar alguma serviço dentro da malha, ele utiliza o gateway
- O istio faz uso do istioingress, como porta de entrada para o cluster

## Virtual service
- roteia o tráfego do gateway a um serviço específico

## Uso de certificado
- o certificado (nada mais é uma chave) deve ser disponibilizado via kubernetes secrets
- o secrets precisa estar no ns do istio-system
- podemos utilizar o protocolo https e fazer uso do tls, que combina a chave publica do cliente com a chave privada do servidor, gerando uma chave de sessão, que será utilizada na criptografica/descriptografia
- o termo tls mutuo, é quando o cliente verifica a validade do certificado publico do servidor e o servidor verifica a validade do certificado publico do cliente
- arquivos para configuração do gwt istio com tls mútuo
```
aula4/coolstore-gw-mtls.yaml
add-certs.sh
curl-test-tls-mutuo.sh
para ver se o novo certificado está configurado: istioctl pc secret -n istio-system deploy/istio-ingressgateway (obs caso não, convém deletar o pod kubectl delete po -n istio-system -l app=istio-ingressgateway)
```
- existe a possibilidade de cada aplicação dentro da malha, tenha seu certificado. Podemos ver o manifesto coolstore-gw-multi-tls.yaml. obs: precisa ter os certificados no segredo kubernetes, dentro do namespace istio-system

## PASSTHROUGH
- um virtual service com tls no modo PASSTHROUGH, significa que o gwt vai inspecionar o cabeçalho SNI (para ver o backend de destino), vai encaminhar o tráfego par ao backend e este validará/encerrará a conexão tls.
- ou seja, o gwt vai delegar a responsabilidade para o aplicativo lidar com o tls
- ideal para aplicativos com comunicação TCP com tls, por exemplo:  banco de dados, cache, serviços de mensagerias e etc

# Deployment vs release
- podemos implantar uma nova versão so serviço, mas as requisições continuam sendo tratadas pela versão antiga
- para verificar a qualidade da nova versão, podemos aos poucos direcionar algumas requisições a ela
- dependendo do resultado, vamos direcionando mais e mais requisições ate que desligamos a versão antiga, soltando então a "release da nova versão"
- essa abordagem e conhecida como implantação canary

## Recurso istio para roteamento
- para direcionar o tráfico de uma requisição, faremos uso dos recursos abaixo do istio (na ordem de entrada de uma requisição):
  -  gateway -> virtual service (podemos setar o subset) -> destination rule (com base no subset, ele redireciona ao serviço que possua a label vinculada)

- abaixo códigos de exemplo:
```
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: catalog-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "catalog.istioinaction.io"
    
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog-vs-from-gw
spec:
  hosts:
  - "catalog.istioinaction.io"
  gateways:
  - catalog-gateway
  http:
  - route:
    - destination:
        host: catalog #nome do servico
        subset: version-v1 #propriedade no destination rule
    
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: catalog
spec:
  host: catalog.istioinaction.svc.cluster.local
  subsets:
  - name: version-v1
    labels:
      version: v1 #label vinculada ao deployment, que está vinculado ao servico
  - name: version-v2
    labels:
      version: v2
      
```
- o modelo acima, o redirecionamento e feito a partir do gateway, mas podemos fazer via chamada, mudando no virtual service o valor da propriedade gateways para mesh
- o redicionamento pode ser feito também, via informação inserida no header da requisição. obs: ainda faz necessária o manifesto destinationrule
