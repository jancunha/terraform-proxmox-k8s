# Terraform para Cluster Kubernetes no Proxmox

Este projeto utiliza Terraform para automatizar a criação de um cluster Kubernetes no Proxmox. Ele provisiona as máquinas virtuais para os nós master e workers, prontas para a instalação do Kubernetes.

## O que este código faz?

De forma simples, este código:

1.  Conecta-se à sua API do Proxmox.
2.  Clona um template de VM (que você precisa ter previamente) para criar novas máquinas.
3.  Cria um número definido de VMs para os **masters** do Kubernetes.
4.  Cria um número definido de VMs para os **workers** do Kubernetes.
5.  Utiliza o Cloud-Init para configurar cada VM na primeira inicialização com:
    *   Nome de usuário e senha.
    *   Sua chave SSH para acesso.
    *   Configurações de rede (DHCP por padrão).

Ao final do processo, você terá as VMs prontas e acessíveis na sua rede, com os endereços IP exibidos no final da execução do Terraform.

## Como usar

### Pré-requisitos

1.  **Terraform Instalado:** Você precisa ter o Terraform instalado na sua máquina.
2.  **Template no Proxmox:** É necessário ter um template de VM no Proxmox. O código está configurado para usar um template chamado `ubuntu-2204-cloud-init-zfs`. Você pode alterar isso no arquivo `locals.tf`. O template **precisa** ter o `qemu-guest-agent` instalado.
3.  **Credenciais da API Proxmox:** Você precisará de um usuário e uma senha (ou token de API) com permissões para criar VMs no Proxmox.

## Criando o Template no Proxmox

O Terraform precisa de um template de VM para clonar as novas máquinas. Se você ainda não tem um, aqui estão os passos para criar um template do Ubuntu 22.04 com Cloud-Init no seu nó Proxmox.

**Execute estes comandos diretamente no shell do seu nó Proxmox.**

### 1. Instale as dependências

```bash
apt update
apt install libguestfs-tools -y
```

### 2. Baixe a imagem do Ubuntu Cloud

```bash
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
```

### 3. Instale o QEMU Guest Agent na imagem

O Guest Agent é essencial para que o Proxmox possa se comunicar com a VM.

```bash
virt-customize -a jammy-server-cloudimg-amd64.img --install qemu-guest-agent
```

### 4. Crie a VM base

Este comando cria uma nova VM com as configurações básicas. O ID `202` é um exemplo, você pode usar outro que esteja livre.

```bash
qm create 202 \
  --name ubuntu-2204-cloud-init-zfs \
  --numa 0 \
  --ostype l26 \
  --cpu cputype=host \
  --cores 2 \
  --sockets 1 \
  --memory 2048 \
  --net0 virtio,bridge=vmbr0 \
  --ide2 zfs-vm:cloudinit \
  --agent enabled=1 \
  --serial0 socket \
  --vga serial0
```

### 5. Importe o disco para a VM

Substitua `local` pelo nome do seu storage.

```bash
qm importdisk 202 jammy-server-cloudimg-amd64.img local
```

### 6. Anexe o disco à VM

```bash
qm set 202 --scsihw virtio-scsi-pci --scsi0 local:vm-202-disk-0
```

### 7. Configure o disco de boot

```bash
qm set 202 --boot c --bootdisk scsi0
```

### 8. Aumente o tamanho do disco (Opcional)

A imagem cloud tem um tamanho pequeno por padrão. Você pode aumentá-la com o comando abaixo.

```bash
qm resize 202 scsi0 32G
```

### 9. Converta a VM em um template

Tudo pronto! Agora, transforme a VM em um template. A partir dele, o Terraform poderá criar seus clones.

```bash
qm template 202
```

Agora você tem um template chamado `ubuntu-2204-cloud-init-zfs` pronto para ser usado pelo Terraform!


### Configuração

1.  **Clonando o repositório:**
    ```bash
    git clone <URL_DO_SEU_REPOSITORIO>
    cd proxmox-k8s/terraform
    ```

2.  **Variáveis de Ambiente (Opcional, mas recomendado):**
    Para não expor suas credenciais, você pode configurar as variáveis de ambiente para o provedor Proxmox. O código já está configurado para usá-las.
    ```bash
    export PM_API_TOKEN_ID="seu-usuario@pve!seu-token-id"
    export PM_API_TOKEN_SECRET="seu-token-secret"
    ```
    *Observação: O `provider.tf` está usando a URL da API diretamente. Para mais segurança, você pode remover a configuração do provedor de lá e usar a variável de ambiente `PM_API_URL`.*

3.  **Criando o arquivo de variáveis:**
    O Terraform precisa de algumas informações que são específicas do seu ambiente. Crie um arquivo chamado `terraform.tfvars` e preencha-o com os seguintes dados:

    ```hcl
    # terraform.tfvars

    # Senha para o usuário criado pelo cloud-init (ex: "minhasenhaforte")
    ci_password = "SUA_SENHA_AQUI"

    # Sua chave SSH pública (o conteúdo do seu arquivo ~/.ssh/id_rsa.pub)
    ssh_public_key = "ssh-rsa AAAA..."

    # Caminho para a sua chave SSH privada (para que o Terraform possa se conectar à VM)
    ssh_private_key_path = "/home/seu_usuario/.ssh/id_rsa"
    ```

### Executando o Terraform

1.  **Inicialize o Terraform:**
    Este comando baixa o provedor Proxmox.
    ```bash
    terraform init
    ```

2.  **Planeje a execução:**
    O Terraform mostrará o que ele vai criar. É sempre bom verificar antes de aplicar.
    ```bash
    terraform plan
    ```

3.  **Aplique a configuração:**
    Este comando vai, de fato, criar as VMs.
    ```bash
    terraform apply
    ```

    Digite `yes` quando for solicitado.

Ao final, o Terraform mostrará os endereços IP das suas novas VMs. Agora você pode acessá-las via SSH e começar a instalar o seu cluster Kubernetes!

## Para destruir o ambiente

Se quiser remover todas as VMs criadas pelo Terraform, basta executar:

```bash
terraform destroy
```