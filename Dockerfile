# ===========================
# Base Image
# ===========================
FROM ubuntu:22.04

# ===========================
# Environment Variables
# ===========================
ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/root
ENV TOOLS=${HOME}/tools

# ===========================
# Working Directory Setup
# ===========================
WORKDIR $HOME
RUN mkdir -p $HOME/tools $HOME/wordlists $HOME/tools/repositories

# ===========================
# Install System Essentials
# ===========================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Essential system tools
    build-essential tmux gcc make unzip curl wget vim nano git \
    iputils-ping net-tools software-properties-common tzdata \
    # Networking & security tools
    nmap whois nikto dnsutils dnsrecon hydra sqlmap dirb \
    # Python & related tools
    python3 python3-pip python3-venv pipx python3-pycurl python3-dnspython \
    # Perl & Ruby dependencies
    perl cpanminus libwww-perl ruby-dev \
    # Libraries & development packages
    libldns-dev libcurl4-openssl-dev libxml2 libxml2-dev \
    libxslt1-dev libgmp-dev zlib1g-dev libpcap-dev \
    # AWS CLI
    awscli \
    # Powerline fonts & tools
    powerline fonts-powerline zsh

# ===========================
# Install Tools from GitHub
# ===========================
# Dnsenum
RUN cd ${TOOLS}/repositories && \
    git clone https://github.com/fwaeytens/dnsenum.git && chmod +x dnsenum/dnsenum.pl && \
    ln -s ${TOOLS}/repositories/dnsenum/dnsenum.pl ${TOOLS}/dnsenum && \
    cpanm String::Random Net::IP Net::DNS Net::Netmask XML::Writer
# Sublist3r
RUN cd ${TOOLS}/repositories && \
    git clone https://github.com/aboul3la/Sublist3r.git && cd Sublist3r && \
    pip install -r requirements.txt && \
    ln -s ${TOOLS}/repositories/Sublist3r/sublist3r.py ${TOOLS}/sublist3r
#theHarvester
RUN cd ${TOOLS}/repositories && \
    git clone https://github.com/AlexisAhmed/theHarvester.git && cd theHarvester \
    pip install -r requirements.txt && chmod +x theHarvester.py && \
    ln -s ${TOOLS}/repositories/theHarvester/theHarvester.py ${TOOLS}/theHarvester
# XSStrike
RUN cd ${TOOLS}/repositories && \
    git clone https://github.com/s0md3v/XSStrike.git && cd XSStrike && \
    pip install -r requirements.txt && chmod +x xsstrike.py && \
    ln -s ${TOOLS}/repositories/XSStrike/xsstrike.py ${TOOLS}/xsstrike
# MassDNS
RUN cd ${TOOLS}/repositories && \
    git clone https://github.com/blechschmidt/massdns.git && cd massdns && \
    make && ln -s ${TOOLS}/repositories/massdns/bin/massdns ${TOOLS}/massdns
#whatweb
RUN cd ${TOOLS}/repositories && \
    git clone https://github.com/urbanadventurer/WhatWeb.git && cd WhatWeb \
    make install && chmod +x whatweb && \
    ln -s ${TOOLS}/repositories/WhatWeb/whatweb ${TOOLS}/whatweb

# SecLists Wordlists
RUN cd $HOME/wordlists && wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O SecList.zip && unzip SecList.zip && rm -f SecList.zip && mv SecLists-master seclists


# ===========================
# Install Go
# ===========================
RUN wget -q https://go.dev/dl/go1.24.0.linux-amd64.tar.gz -O /tmp/go.tar.gz && \
    tar -xzf /tmp/go.tar.gz -C /usr/local && \
    rm -rf /tmp/go.tar.gz
ENV GOPATH=/usr/local/go
ENV PATH=${GOPATH}/bin:$PATH

# ===========================
# Install Go-based Tools
# ===========================
RUN \
    # gobuster
    go install github.com/OJ/gobuster/v3@latest && \  
    # subfinder
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest && \
    # katana
    go install github.com/projectdiscovery/katana/cmd/katana@latest && \
    # nuclei
    go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest && nuclei -update-templates && \
    # assetfinder
    go install github.com/tomnomnom/assetfinder@latest && \
    # httpx
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    # waybackurls
    go install github.com/tomnomnom/waybackurls@latest && \
    # amass
    go install github.com/owasp-amass/amass/v4/...@master \
    # puredns
    go install github.com/d3mondev/puredns/v2@latest \ 
    # anew 
    go install github.com/tomnomnom/anew@latest     

RUN cd ${TOOLS} && wget https://raw.githubusercontent.com/trickest/resolvers/main/resolvers-trusted.txt  
# ===========================
# Install Python-based Tools
# ===========================
RUN \
    # arjun
    pipx install arjun && \
    # fierce
    pipx install fierce && \
    # wfuzz
    pip install wfuzz

# ===========================
# Install Rust & Cargo
# ===========================
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV CARGOPATH=$HOME/.cargo/bin
ENV PATH=$PATH:${CARGOPATH}
# ===========================
# Install Cargo-based tools
# ===========================
RUN \
    # feroxbuster    
    cargo install feroxbuster

# ===========================
# Configure ZSH & Plugins
# ===========================
RUN git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh && \
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh-syntax-highlighting" --depth 1 && \
    echo "export PATH=${TOOLS}:$PATH" >> "$HOME/.zshrc" && \
    echo "alias python='python3'" >> "$HOME/.zshrc" && \
    echo "source $HOME/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$HOME/.zshrc"


# ===========================
# Create Symlinks in TOOLS Folder
# ===========================
RUN ln -s /usr/local/go/bin/* ${TOOLS}/ && \
    ln -s $HOME/.local/bin/* ${TOOLS}/

# ===========================
# Cleanup
# ===========================
RUN go clean -cache -testcache -modcache && \
    rm -rf /var/lib/apt/lists/* ~/.cache/pip

# ===========================
# Set Default Shell
# ===========================
CMD ["/bin/zsh"]
