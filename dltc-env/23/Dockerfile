# Using one of pandoc's official docker images
FROM pandoc/latex:edge-ubuntu
ARG base_image=pandoc/latex:edge-ubuntu
ARG pandoc_version=3.1.2
ARG texlive_version=2023
SHELL ["/bin/bash", "-c"]


RUN apt-get update -y && apt-get upgrade -y

# LaTeX setup
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Zurich
RUN apt-get install -y texlive-full
# Ubuntu's texlive-full doesn't have all packages, so we use tlmgr to install the rest
### TeXLive Manager: set mirror automatically, update, install EVERYTHING
RUN tlmgr option repository https://mirror.ctan.org/systems/texlive/tlnet
RUN tlmgr update --self \
    && tlmgr update --all
RUN tlmgr install --reinstall scheme-full

# Inkscape to process images, sometimes needed by pandoc
RUN apt-get -y install inkscape

# SSH server setup
RUN apt-get install -y openssh-server
COPY config/sshd_config /etc/ssh/sshd_config


# Font setup
RUN mkdir -p /usr/share/fonts/myfonts
COPY fonts/*.otf /usr/share/fonts/myfonts/
RUN fc-cache -f
RUN apt-get autoremove -y

# Dialectica scripts setup
COPY scripts/dltc-make /usr/local/bin/
RUN chmod +x /usr/local/bin/dltc-make
RUN mkdir -p /template
COPY template/ /template/

# The entrypoint script will be at PATH, so it can be called from anywhere
COPY LaunchScript /usr/local/bin/
RUN chmod a+x /usr/local/bin/LaunchScript

# Non-sudoer user configuration
ARG CONTAINER_USER=copyeditor
ARG CONTAINER_HOME=/home/$CONTAINER_USER
ARG passw=copyeditor
RUN useradd --create-home --shell=/bin/bash $CONTAINER_USER \
    && echo $CONTAINER_USER:$passw | chpasswd


USER $CONTAINER_USER
WORKDIR $CONTAINER_HOME


ENTRYPOINT ["LaunchScript"]
