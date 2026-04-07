Documentação de Infraestrutura e CI/CD: Go-API no EKS
Esta documentação descreve a implementação de uma esteira automatizada de entrega contínua, utilizando práticas modernas de segurança e monitoramento em um cluster AWS EKS.

1. Arquitetura da Solução
A solução utiliza uma abordagem de separação de responsabilidades:

CI (Integração Contínua): Build e Scan de segurança.

CD (Entrega Contínua): Deploy automatizado via Helm.

Ingress: Traefik como porta de entrada única.

Monitoramento: Stack Kube-Prometheus para observabilidade.

2. Pipeline de CI/CD (GitHub Actions)
A pipeline foi dividida em dois arquivos para garantir que o deploy só ocorra após um build bem-sucedido e seguro.

2.1. Workflow de Build e Scan (build.yml)
Este workflow é responsável por:

Build Docker: Compila a aplicação Go usando um Dockerfile multi-stage. Foi configurado o multi-stage para a imagem ficar menor e mais eficiente antes a imagem dava 800mb hoje da 15mb 

Trivy Scan: Varre a imagem em busca de vulnerabilidades CRITICAL e HIGH. Se encontradas, a pipeline falha (exit code 1).Por esse modivo foi atualizado o go e o alpine para versões mais recentes devido a falhas de segurança 

ECR Push: Envia a imagem para o Amazon ECR com a tag do commit (github.sha). COm tag latest e hash para facilitar o deploy

2.2. Workflow de Deploy (deploy.yml)
Este workflow "escuta" o término do build e executa:

Autenticação AWS: Configura as credenciais e o contexto do cluster EKS.

Helm Upgrade: Realiza o deploy ou atualização da aplicação usando o comando:
Utilizado o Helm para facilidade de implementação para varios ambientes dev e prod e reutilização de codigo futuro

Bash
helm upgrade --install go-api ./k8s/helm/go-api \
  --namespace go-app-dev \
  -f ./k8s/helm/values-dev.yaml \
  --set global.CONTAINER_GIT_HASH=${{ github.sha }} \
  --wait
3. Estrutura do Helm Chart
O Helm Chart foi customizado para suportar múltiplos ambientes através de arquivos de valores específicos (values-dev.yaml).

Manifesto de Deployment (deployment.yaml)

Probes: Healthchecks configurados em /healthz.

Recursos: Limites de CPU e Memória definidos para evitar o consumo desenfreado do cluster.

Segurança: Configurado para rodar com usuário não-root (65534).

Hpa configurado para auto-scalling da aplicação 


4. Infraestrutura de Suporte (Shared Services)
Instalamos serviços essenciais no cluster para gerenciar o tráfego e a saúde da aplicação.

4.1. Traefik Ingress Controller
Instalado via Helm para expor a aplicação através de um único Load Balancer na AWS.

Comando de Instalação:

helm upgrade --install traefik traefik/traefik --namespace traefik --create-namespace
Ingress: Criamos uma regra de Ingress para mapear o DNS do Load Balancer diretamente para o go-api-service.

4.2. Kube-Prometheus-Stack
Utilizado para coletar métricas e visualizar dashboards no Grafana.

Monitoramento da App: Adicionamos anotações ao serviço Go para que o Prometheus colete métricas automaticamente:

prometheus.io/scrape: "true"

prometheus.io/port: "8080"

para ter acesso ao grafana será feito por port-ford e a senha e gerado com o comandos abaixo:

kubectl get secret --namespace monitoring -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode ; echo

Expor o grafana:

kubectl --namespace monitoring port-forward $POD_NAME 3000

5. Melhorias

Cert-Manager: Instalar para gerenciar certificados SSL (HTTPS) automaticamente via Let's Encrypt.

AlertManager: Configurar alertas no Prometheus para avisar no Slack/E-mail caso a API fique offline.

Status da Infraestrutura: 🟢 Operacional e Automatizada.