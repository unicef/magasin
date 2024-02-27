# Use the official Debian Slim image as the base image
FROM python:slim

# Install necessary and useful packages packages
RUN apt-get update && apt-get install -y \
  curl \
  bash-completion \
  jed \
  nano \
  jq \
  procps \
  yq \
  iputils-ping \
  nmap \  
  gpg \
  net-tools \ 
  zsh

# Install kubectl
RUN apt-get update   
      # apt-transport-https may be a dummy package; if so, you can skip that package    
RUN apt-get install -y apt-transport-https ca-certificates curl
      # Note: In releases older than Debian 12 and Ubuntu 22.04, /etc/apt/keyrings does not exist by default, and can be created using sudo mkdir -m 755 /etc/apt/keyrings
#RUN mkdir -m 755 /etc/apt/keyrings
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
      # This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
RUN echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubectl

# Install helm
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
RUN apt-get install apt-transport-https --yes
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
RUN apt-get update
RUN apt-get install helm

RUN echo `$(dpkg --print-architecture)`
RUN ARCH=$(dpkg --print-architecture) && curl https://dl.min.io/client/mc/release/linux-$ARCH/mc \
    --create-dirs \
    -o /usr/local/bin/mc \
  && chmod +x /usr/local/bin/mc

# Install mag-cli Python package
RUN pip3 install mag-cli

# Set up autocompletion for kubectl, helm, mc for zsh and bash
RUN echo 'source <(kubectl completion bash)' >> ~/.bashrc \
  && echo 'source <(helm completion bash)' >> ~/.bashrc \
  && echo 'source <(mc --autocompletion bash)' >> ~/.bashrc \
  && echo 'source <(kubectl completion zsh)' >> ~/.zshrc \
  && echo 'source <(helm completion zsh)' >> ~/.zshrc \
  && echo 'source <(mc --autocompletion zsh)' >> ~/.zshrc

# Same for mag
RUN echo '_MAG_COMPLETE=bash_source mag > ~/.mag-complete.bash' \
    && echo 'eval "$(_MAG_COMPLETE=zsh_source mag)" >> ~/.zshrc' 

ARG VERSION
RUN echo $VERSION

# Display project name in bash
RUN apt-get install -y figlet
RUN echo "figlet magsh $VERSION && echo \"\nDockerized for magasin (https://github.com/unicef/magasin) \n\n\"" > /etc/bash.bashrc

# Add PS1 environment variable to /etc/bash.bashrc
RUN echo 'export PS1="\[\033[01;34;43m\]k8s: $(kubectl config current-context) |\[\033[00m\]\[\033[00m\]\[\033[1m\] \u\[\033[00m\]:\w \$ "' >> /etc/bash.bashrc

# Clean apt cache
RUN apt clean

# Add magasin helm repo
RUN helm repo add magasin http://unicef.github.io/magasin

# kubernetes kubeconfig to be /kube/config 
# -v ~/.kube/config:/kube/config 
ENV KUBECONFIG=/kube/config

# Ports that can be forwarded by `mag` command
# 3000 Dagster
# 8001 Daskhub
# 8047 Drill
# 8088 Superset UI
# 9000 MinIO API
# 9090 MinIO UI (no ssl)
# 9443 Minio UI (ssl)
#
# 11000 (Available for user)
# 11001 (Available for user)
# 11002 (Available for user)
EXPOSE 3000 8001 8047 8088 9000 9090 9443 11000 11001 11002

# Set the default command to bash
CMD ["bash"]
