############
# SETUP
############

# pandoc-extra 08/10/2023
FROM pandoc/extra:latest
ARG base_image=pandoc/extra:latest
ARG pandoc_version=3.1.1
ARG texlive_version=2022


# Font setup
RUN apk add --no-cache fontconfig freetype
RUN mkdir -p /usr/share/fonts/myfonts
COPY fonts/*.otf /usr/share/fonts/myfonts/
RUN fc-cache -f


ENTRYPOINT ["/bin/sh"]
