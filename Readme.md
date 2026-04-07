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
    helm upgrade --install go-app ./k8s/helm/go-app \
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

## 🛠️ 4. Infraestrutura de Suporte (Shared Services)

Para garantir alta disponibilidade, gerenciamento de tráfego e saúde da aplicação, instalamos serviços essenciais utilizando Helm.

---

### 🚦 4.1. Traefik Ingress Controller
O **Traefik** atua como o ponto de entrada único (Ingress Controller) para o cluster, gerenciando o tráfego externo através de um **AWS Load Balancer**.

* **Instalação:**
    ```bash
    helm upgrade --install traefik traefik/traefik \
      --namespace traefik \
      --create-namespace
    ```
* **Ingress Rule:** Configuramos regras de roteamento para mapear o DNS do Load Balancer diretamente para o `go-api-service`, eliminando a necessidade de múltiplos IPs externos.

---

### 📊 4.2. Kube-Prometheus-Stack
Implementação da stack completa de observabilidade (**Prometheus + Grafana**) para coleta de métricas e visualização de saúde do cluster.

#### 🧲 Monitoramento da Aplicação
A aplicação é monitorada automaticamente através de **Service Discovery**. Adicionamos as seguintes anotações ao serviço da aplicação:

| Anotação | Valor | Descrição |
| :--- | :--- | :--- |
| `prometheus.io/scrape` | `"true"` | Ativa a coleta automática |
| `prometheus.io/port` | `"8080"` | Porta onde a aplicação expõe as métricas |

#### 🔐 Acesso ao Grafana
O acesso ao dashboard do Grafana é feito de forma segura via `port-forward`.

1.  **Recuperar senha do administrador:**
    ```bash
    kubectl get secret --namespace monitoring -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode ; echo
    ```

2.  **Expor o Grafana localmente:**
    ```bash
    # Redireciona a porta 3000 do serviço para sua máquina
    kubectl --namespace monitoring port-forward svc/kube-stack-grafana 3000:80
    ```
    > Acesse em seu navegador: `http://localhost:3000`

---

## 📈 5. Roadmap de Melhorias

- [ ] **Cert-Manager:** Provisionamento automático de certificados TLS/SSL (HTTPS) via Let's Encrypt.
- [ ] **AlertManager:** Configuração de disparos de alertas para canais como Slack ou E-mail em caso de downtime.
- [ ] **Log Centralization:** Implementação de Loki ou ELK Stack para persistência de logs.

---

### 🟢 Status da Infraestrutura: `Operacional e Automatizada`
