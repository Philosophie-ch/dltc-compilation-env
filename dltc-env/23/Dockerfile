# Using one of pandoc's official docker images
FROM pandoc/latex:edge-ubuntu
ARG base_image=pandoc/latex:edge-ubuntu
ARG pandoc_version=3.1.2
ARG texlive_version=2023

# LaTeX setup
RUN apt-get update -y && apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y texlive-full
# Ubuntu's texlive-full doesn't have all packages, so we use tlmgr to install the rest
RUN tlmgr install --reinstall scheme-full

# Font setup
RUN mkdir -p /usr/share/fonts/myfonts
COPY fonts/*.otf /usr/share/fonts/myfonts/
RUN fc-cache -f
RUN apt-get autoremove -y

# Dialectica scripts setup
COPY  scripts/dltc-make /usr/local/bin/
RUN chmod +x /usr/local/bin/dltc-make
RUN mkdir -p /template
COPY template/ /template/


ENTRYPOINT ["/bin/bash"]
