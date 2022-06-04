# Istio
- função de facilitar a remoção de códigos de rede dos aplicativos
- fazer roteamento com base em metadados externos que fazem parte da solicitação
- controle de tráfico e roteamento de baixa granularidade
- protege e impõe políticas de cotas de uso

### Plano de controle
- fornece maneiras para o usuário controlar, observar, gerenciar e configurar a malha
- é implementado pelo istiod, que pega as configurações especificadas pelo usuário, que são expresas através de recursos

### Gerenciamento de identidade
- quando 2 serviços se comunicam dentro da malha, os proxies de ambos de comunicam, podemos encriptar o tráfego atráves de certificados x.509
