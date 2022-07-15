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
- um virtual service com tls no modo PASSTHROUGH, significa que o gwt vai inspecionar o cabeçalho SNI (para ver o backend de destino), vai encaminhar o tráfego para o backend e este validará/encerrará a conexão tls.
- ou seja, o gwt vai delegar a responsabilidade para o aplicativo lidar com o tls
- ideal para aplicativos com comunicação TCP com tls, por exemplo:  banco de dados, cache, serviços de mensagerias e etc

# Deployment vs release
- podemos implantar uma nova versão do serviço, mas as requisições continuam sendo tratadas pela versão antiga
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
- o modelo acima, o redirecionamento e feito a partir do gateway, mas podemos fazer chamada interna, mudando no mesmo o valor da propriedade gateways para mesh (funciona para chamadas dentro da malha de serviços)
- o redirecionamento pode ser feito também, via informação inserida no header da requisição. obs: ainda faz necessária o manifesto destinationrule

## Implantação incremental
- podemos utilizar a implantação canary de forma diferente, onde direcionamos um percentual de requisição para a nova versão do serviço e outra a versão antiga.
- por ex:
  - 90% das requisições irão para a v1
  - 10% das requisições irão para a v2 

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog
spec:
  hosts:
  - catalog
  gateways:
  - mesh
  http:
  - route:
    - destination:
        host: catalog
        subset: version-v1
      weight: 90
    - destination:
        host: catalog
        subset: version-v2
      weight: 10
```

## Automatização de releases
- podemos utilizar o flagger, onde automatiza os lançamentos canary.
- para instalar:
```
helm repo add flagger https://flagger.app
kubectl apply -f \
https://raw.githubusercontent.com/fluxcd/\
flagger/main/artifacts/flagger/crd.yaml
 
helm install flagger flagger/flagger \
     --namespace=istio-system \
     --set crd.create=false \
     --set meshProvider=istio \
     --set metricsServer=http://prometheus:9090
```
- o flagger utiliza algumas métricas para ir aumentando o percentual de requisição, sendo direcionada a nova versão.
````
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: catalog-release
  namespace: istioinaction
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: catalog
  progressDeadlineSeconds: 60
  # Service / VirtualService Config
  service:
    name: catalog
    port: 80
    targetPort: 3000
    gateways:
    - mesh
    hosts:
    - catalog
  analysis:
    interval: 45s intervalor de 45 segundos
    threshold: 5 se ocorrer 5 erros, voltar o direcionamento para versão antiga
    maxWeight: 50 máximo de direcionamento
    stepWeight: 10 vou aumentando 10% de direcionamento a cada 45s
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 30s
````
- após a implantação do manifesto, podemos ver se este foi aplicado: kubectl get canary

## Mirror
- podemos utilizar o recurso de espelhamento, onde a requisição entra no serviço em produção e também na sua nova versão, mas esta no modo mirror
- no modo mirror é ignorado qualquer tipo de falha, para não impactar na parte real

````
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog
spec:
  hosts:
  - catalog
  gateways:
    - mesh
  http:
  - route:
    - destination:
        host: catalog
        subset: version-v1
      weight: 100
    mirror:
      host: catalog
      subset: version-v2
````

# Resiliência
- como o envoy/proxy ou sidecar fica próximo a aplicação, neste o istio faz as tratavias diante a falhas, como:
  - retry
  - circuit breaker
  - fallback
  
## Balanceador de carga do lado do cliente
- O servidor informa ao cliente os endereços das instâncias disponíveis, e este pode utilizar seu algoritimo para direcionamento
- por padrão o istio utiliza o Round robin, que funciona da seguinte forma:
  - diante uma lista de ip do servidores
  - enviamos a requisição para o primeiro e este vai para o final da fila
  - a proxima requisição vai para o proximo da fila, quando este atender, ele vai para o final
  - e assim segue.
  
## Algoritmos de balanceador de carga
- dentre os algoritmos random, round robin e o last connection, o melhor é o last connection.
- é o unico que leva em consideração a latência dos endpoints, e rediciona o que responde mais rápido.
- Abaixo um exemplo de uso desses algoritmos. obs: o padrão do istio é o round robin:
````
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: simple-backend-dr
spec:
  host: simple-backend.istioinaction.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN ou RANDOM ou ROUND_ROBIN
````
- uma boa ferramenta para teste desses algoritmos, é o fortio

## Zona de localidade e disponibilidade
- através de labels nos deployments da aplicação, o istio pode redicionar chamadas dentro da mesma zona de disponibilidade, por exemplo:\
  - app1 chama app2(onde tem 2 instancias)
    - app1 zone sa-east-1 
    - app2 inst1 sa-east-2
    - app2 inst2 us-west1-a
  - dentro do istio, quando app1 chamar app2, ele direcionará a requisição para a instância 1, que encontra-se na mesma zona de disponibilidade

## Timeout
- podemos definir um timeout no istio, através do recurso VirtualService

## Retry
- por padrão o istio realiza uma retentativa até 2 vezes
- similar ao timeout, podemos configurar explicitamente o retry, através do virtual service
  - obs: existe um comportamente padrão do istio para retry, por ex: status 503 ele efetua o retry, 500 não 
  - podemos mudar esse comportamente atráves do virtual service, como no exemplo abaixo:
```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: simple-backend-vs
spec:
  hosts:
  - simple-backend
  http:
  - route:
    - destination:
        host: simple-backend
    retries:
      attempts: 2
      retryOn: 5xx
```
- outro ponto importante é o tempo entre as retentativas, onde elas são multiplicada a cada tentativa, deve ser menor que o timeout configurado.
- por exemplo:
  - 3 tentativas a cada 500ms, mas temos um timeout de 1 segundo
  - 1 - 500, 2 - 1000, 3 - 1500 (não vai funcionar) 
  - a configuração de tempo entre as retentativas e através da propriedade filha do retry = perTryTimeout
- Existe algumas configurações que modificam o comportamento padrão do istio, através do envoy filter (o sidecar), no entanto pode ter problemas de compatibilidade dependente da versão que você atualizar futuramente.

# Circuit breaking
- o istio não possui uma configuração explícita chamada circuitbreaking, e sim configurações para diminuir o direcionamento de solicitações a microservice com problema
- algumas formas de configuração, descritas a seguir.
- podemos também limitar as solicitações, criando um circuitbreaker conforme abaixo via destination rule:

```
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: simple-backend-dr
spec:
  host: simple-backend.istioinaction.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1 -maximo de conexao no endpoint      
      http:
        http1MaxPendingRequests: 1 -maximo de solicitação em espera no endpoint      
        maxRequestsPerConnection: 1 -> maximo de requisição por conexao no endpoint      
        maxRetries: 1 -> máximo de retry no endpoint      
        http2MaxRequests: 1 -> maximo de conexao paralela no endpoint      
``` 
- no exemplo acima se entrar mais uma requisição enquanto existir outra pendente, ocorrerá uma falha, pois somente é permitido 1 conexão pendente

## Pool de conexão: 
- pulamos os endpoints com falha dentro do pool, e se esgotar os endpoints, o circuitbreaker e aberto
- exemplo de configuração

```
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: simple-backend-dr
spec:
  host: simple-backend.istioinaction.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 1 # somente erros na caso do code 5xx
      interval: 5s tempo que o istio leva checa se o host pode ser retirado da lista de chamada, dentro do pool (tempo que pode cair solicitações e levar a erro, onde serão direcionadas ao host com problema)
      baseEjectionTime: 5s tempo que o host fica inativo para chamada (numero de vezes que ele ficou inativo vezes esse tempo)
      maxEjectionPercent: 100 percentual de hosts do pool que posso inativar, com o critério 5xx, nesse caso todos e o circuit breaker e aberto
```

# Observabilidade
- é uma característica de um sistema, que é medida de forma a compreender sobre seu estado interno, olhando seu comportamento em tempo de execução.
- como a maioria dos recursos do istio está em nível de rede, para solicitações, a sua capacidade de coletar métricas tambem está nesse nível.

## Observabilidade x monitoramento
- monitoramento é a prática de colegar métricas, logs, traces e etc.
- observabilidade é o desenho do estado ideal do sistema, como base no monitoramento e tomando decisões quando este está se degradando.

## Metricas
- o proxy do istio ja coleta diversas métricas pra gente, sem necessidade de mudar nada na app
- quando falamos proxy é o sidecar envoy ok
- mas podemos personalizar essa coleta, adicionando mais metricas, no entanto cuidado para não sobrecarregar o serviço de coleta
- exemplo abaixo:

````
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: webapp
  name: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |-
          proxyStatsMatcher:
            inclusionPrefixes:
            - "cluster.outbound|80||catalog.istioinaction" --solicitacoes indo para catalog
   etc...         
````
### Alguns exemplos de metricas
- /stats é um plugin do envoy que espões as métricas
- para coletar metricas via curl, podemos executar:
````
kubectl exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15000/stats | grep catalog
`````
- cluster.outbound|80||catalog.circuit_breakers -> dados do circuit breaker
- cluster.outbound|80||catalog.internal.upstream_rq_2xx -> requisições com sucesso dentro da malha (interna)
- cluster.outbound|80||catalog.ssl.* -> dados de trafego ssl, dentro da malha
- cluster.outbound|80||catalog.upstream_cx_* -> mostra o que está ocorrendo dentro da rede, se a conexão foi com sucesso, total de bytes e etc.
- para listar os dados de todos os namespaces/cluster:
````
kubectl exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15000/clusters
````
- não precisamos ir a cada envoy para olhar essas métricas, podemos utilizar um serviço que efetua essa raspagem como prometheus.

### Raspagem de métricas com prometheus
- Prometheus é um componente de coleta de métricas e um conjunto de ferramenta para monitoramente/alerta.
- diferente de outros dispositivos, o prometheus puxa as métricas em vez de aguardar um agente enviá-las.
- se já possuimos o istio configurado no nosso cluster, ele já expõe um rota que mostra os logs no formato que o prometheus reconhece
```
kubectl exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15090/stats/prometheus
```

#### Configuração prometheus
- para o prometheus coletar as métricas, este precisa de alguns operadores, como ServiceMonitor ou PodMonitor (pega as métricas dos pods que possui um sidecar istio-proxy), abaixo um exemplo:
```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: istio-component-monitor
  namespace: prometheus
  labels:
    monitoring: istio-components
    release: prom
spec:
  jobLabel: istio
  targetLabels: [app]
  selector:
    matchExpressions:
    - {key: istio, operator: In, values: [pilot]}
  namespaceSelector:
    any: true
  endpoints:
  - port: http-monitoring
    interval: 15s
```
- algumas métricas conhecidas:
  - istio_requests_total
  - istio_request_duration_milliseconds
  - istio_request_bytes
  - istio_request_messages_total
  - istio_response_messages_total

### Metricas, dimensões e atributos
- metrica é um contador, medidor ou histograma/distribuição de telemetria
- dimensão é o contexto da medição 
- atributo são os participantes, utilizados para definir um valor da dimensão
- as métricas do istio são configuradas no plugin proxy de estatísticas, usando um recurso EnvoyFilter.
- os filtros pegando os dados e disponibilizam via /stats
- para adicionar novas dimensões a métrica, por exemplo a métrica istio_request_total, temos que utilizar o recurso IstioOperator, conforme abaixo:
```
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: demo
  values:
    telemetry:
      v2:
        prometheus:
          configOverride:
            inboundSidecar: #entrada no sidecar
              metrics:
              - name: requests_total
                dimensions:
                  upstream_proxy_version: upstream_peer.istio_version #nova dimensão
                  source_mesh_id: node.metadata['MESH_ID'] #nova dimensão
                tags_to_remove:
                - request_protocol #estamos removendo essa métrica
            outboundSidecar: #saida do sidecar
              metrics:
              - name: requests_total
                dimensions:
                  upstream_proxy_version: upstream_peer.istio_version
                  source_mesh_id: node.metadata['MESH_ID']
                tags_to_remove:
                - request_protocol #estamos removendo essa métrica
            gateway:
              metrics:
              - name: requests_total
                dimensions:
                  upstream_proxy_version: upstream_peer.istio_version
                  source_mesh_id: node.metadata['MESH_ID']
                tags_to_remove:
                - request_protocol
```
- para instalar utilize o istioctl
```
istioctl install operador.yml
```
- para ver essa nova dimensão, precisamos anotar o deployment da nossa aplicação, com anotação sidecar.istio.io/extraStatTags, na tag spec.template.metadata. Conforme exemplo abaixo:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: webapp
  name: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |-
          extraStatTags: 
          - "upstream_proxy_version"
          - "source_mesh_id"
      labels:
        app: webapp
    spec:
```
- efetua uma chamada ao serviço, e verifique se consta a nova métrica via:
```
kubectl -n istioinaction exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15000/stats/prometheus | grep istio_requests_total
```

### Criando sua própria métrica
- acima adicionamos uma nova dimensão a uma métrica existente.
- as novas métricas ou modificação de existentes, serve a todo o cluster, novas versões do istio podemos granular por namespace por exemplo.
- abaixo um exemplo de criação de métricas:
```
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: demo
  values:
    telemetry:
      v2:
        prometheus:
          configOverride:
            inboundSidecar:
              definitions:
              - name: get_calls
                type: COUNTER #tipo contagem
                value: "(request.method.startsWith('GET') ? 1 : 0)"
            outboundSidecar:
              definitions:
              - name: get_calls
                type: COUNTER
                value: "(request.method.startsWith('GET') ? 1 : 0)"
            gateway:
              definitions:
              - name: get_calls
                type: COUNTER
                value: "(request.method.startsWith('GET') ? 1 : 0)"
```
- obs: por padrão o istio coloca um prefixo istio_, nesse caso ficará isito_get_calls (quantas chamdas get de entrada e saida, no caso acima)
- para aplicar o manifesto acima, utilizamos o istioctl:
```
istioctl install -f new-metric.yaml
```
- para nossas aplicações participarem dessa métrica, conforme dito acima, precisamos da anotação correspondente no seu deplomente:
```
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |-
          proxyStatsMatcher:
            inclusionPrefixes:
            - "istio_get_calls"
```
- faça algumas chamadas ao serviço e depois consulte:
```
kubectl -n istioinaction exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15000/stats/prometheus | grep istio_get_calls
```

### Criando atributos
- podemos adicionar novos atributos ou novos atributos que na verdade é a combinação de atributos existentes.
```
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: attribute-gen-example
  namespace: istioinaction
spec:
  configPatches:
  ## Sidecar Outbound 
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_OUTBOUND
      listener:
        filterChain:
          filter:
            name: envoy.filters.network.http_connection_manager
            subFilter:
              name: istio.stats
      proxy:
        proxyVersion: ^1\.13.*
    patch:
      operation: INSERT_BEFORE
      value:
        name: istio.attributegen
        typed_config:
          '@type': type.googleapis.com/udpa.type.v1.TypedStruct
          type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
          value:
            config:
              configuration:
                '@type': type.googleapis.com/google.protobuf.StringValue
                value: |
                  {
                    "attributes": [
                      {
                        "output_attribute": "istio_operationId", #novo atributo
                        "match": [
                         {
                           "value": "getitems",
                           "condition": "request.url_path == '/items' && request.method == 'GET'" #identificar e contar chamadas para api /items usando get
                         },
                         {
                           "value": "createitem",
                           "condition": "request.url_path == '/items' && request.method == 'POST'"
                         },     
                         {
                           "value": "deleteitem",
                           "condition": "request.url_path == '/items' && request.method == 'DELETE'"
                         }                                             
                       ]
                      }
                    ]
                  }
              vm_config:
                code:
                  local:
                    inline_string: envoy.wasm.attributegen
                runtime: envoy.wasm.runtime.null
```
- para aplicar utiliza o kubectl
- após a adição desse atributos, criamos dimensões que farão uso deles:
```
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: demo
  values:
    telemetry:
      v2:
        prometheus:
          configOverride:
            outboundSidecar:
              metrics:
              - name: requests_total
                dimensions:
                  upstream_operation: istio_operationId #a dimensao usando o novo atributo
```
- para instalar o istio operator utilize o istioctl install -y -f new-operator.yaml
- por fim vincule a dimensão no deployment da sua aplicação
```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: webapp
  name: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |-
          extraStatTags: 
          - "upstream_operation"
      labels:
        app: webapp
    spec:
```
- para consultar se o novo atributo da nova dimensão está em uso:
```
kubectl -n istioinaction exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15000/stats/prometheus | grep istio_requests_total
```