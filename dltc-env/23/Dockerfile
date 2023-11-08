# Using one of pandoc's official docker images
FROM pandoc/latex:edge-ubuntu
ARG base_image=pandoc/latex:edge-ubuntu
ARG pandoc_version=3.1.2
ARG texlive_version=2023

RUN apt-get update -y && apt-get upgrade -y

# LaTeX setup
# Official TeXLive installation instructions: https://tug.org/texlive/quickinstall.html
RUN cd /tmp && \
    wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
    zcat < install-tl-unx.tar.gz | tar xf - && \
    cd install-tl-* && \
    perl ./install-tl --no-interaction && \
    PATH=/usr/local/texlive/${texlive_version}/bin/x86_64-linux:$PATH
RUN echo "PATH=\"/usr/local/texlive/2023/bin/x86_64-linux:${PATH}\"" >> /root/.profile

# TeXLive full install doesn't have all packages, so we use tlmgr to force install absolutely everything possible
RUN tlmgr install --reinstall scheme-full

# Inkscape to process images, sometimes needed by pandoc
RUN apt-get -y install inkscape


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


# Script to launch different services
COPY /scripts/LaunchScript /usr/local/bin/
RUN chmod a+x /usr/local/bin/LaunchScript
# Remove read permissions for non root users
#RUN chmod -r /usr/local/bin/LaunchScript


# TODO: disallow container root access
# but needs to 'service ssh start' somehow
## Set root password
#ARG rootpw=epikur
#RUN echo "root:${rootpw}" | chpasswd
#ENV ROOT_PASSWORD="${rootpw}""

## Non-sudoer user configuration
#ARG CONTAINER_USER=copyeditor
#ARG CONTAINER_HOME=/home/$CONTAINER_USER
#ARG passw=copyeditor
#RUN useradd --create-home --shell=/bin/bash $CONTAINER_USER \
    #&& echo $CONTAINER_USER:$passw | chpasswd

#ENV ROOT_PASSWORD="${rootpw}""

#USER $CONTAINER_USER
#WORKDIR $CONTAINER_HOME



# Bash as entrypoint
ENTRYPOINT ["/bin/bash"]
#CMD ""
