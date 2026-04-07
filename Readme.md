# 🚀 Go-API Infrastructure & CI/CD no AWS EKS

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)
![Helm](https://img.shields.io/badge/helm-%230F1628.svg?style=for-the-badge&logo=helm&logoColor=white)

Este repositório contém a implementação de uma esteira automatizada de entrega contínua (CI/CD), utilizando práticas modernas de segurança, alta disponibilidade e monitoramento em um cluster **AWS EKS**.

---

## 🏗️ Arquitetura da Solução

A solução segue o princípio de separação de responsabilidades:

* **CI (Integração Contínua):** Build otimizado e análise de vulnerabilidades.
* **CD (Entrega Contínua):** Deploy automatizado via Helm em múltiplos ambientes.
* **Ingress Controller:** **Traefik** como porta de entrada única para o cluster.
* **Observabilidade:** Stack **Kube-Prometheus** para métricas e dashboards.

---

## ⚙️ Pipeline de CI/CD (GitHub Actions)

A pipeline é dividida em dois workflows desacoplados para garantir que o deploy só ocorra após a validação total do build.

### 1. Build e Scan (`build.yml`)
* **Docker Multi-stage:** Otimizamos o Dockerfile para reduzir a superfície de ataque e o custo de armazenamento.
    * *Resultado:* Imagem reduzida de **800MB** para apenas **15MB**.
* **Segurança (Trivy):** Varredura automática em busca de vulnerabilidades `CRITICAL` e `HIGH`.
    * *Ação:* Atualizamos o **Go** e o **Alpine** para as versões mais recentes para mitigar falhas conhecidas.
* **Amazon ECR:** Envio da imagem com tags duplicadas (`latest` e `hash do commit`) para facilitar o rastreio e rollback.

### 2. Deploy (`deploy.yml`)
Este workflow é disparado automaticamente após o sucesso do build:
* **Contexto AWS:** Configuração dinâmica do `kubeconfig` para o cluster EKS.
* **Helm Deploy:** Gerenciamento do ciclo de vida da aplicação.
    ```bash
    helm upgrade --install go-api ./k8s/helm/go-api \
      --namespace go-app-dev \
      -f ./k8s/helm/values-dev.yaml \
      --set global.CONTAINER_GIT_HASH=${{ github.sha }} \
      --wait
    ```

---

## 📦 Estrutura do Helm Chart

O Chart foi desenhado para ser reutilizável entre ambientes (Dev/Prod).

* **HPA (Horizontal Pod Autoscaler):** Configurado para escalar a aplicação automaticamente sob carga.
* **Resources & Limits:** Definição estrita de CPU e Memória para evitar que um Pod consuma todos os recursos do nó.
* **Segurança do Runtime:** Aplicação configurada para rodar como **Non-Root User (UID 65534)**.
* **Probes:** Implementação de `liveness` e `readiness` no endpoint `/healthz`.

---

## 🌐 Serviços de Infraestrutura (Shared Services)

### Traefik Ingress Controller
Responsável por expor a aplicação para a internet através de um **AWS Load Balancer**.
```bash
helm upgrade --install traefik traefik/traefik --namespace traefik --create-namespace

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