# FIRST STAGE OF BUILD static data # ---------------------------------------------------------------------------------------------------

FROM busybox AS sample_data
RUN wget https://github.com/byezy/sample-spatial-data/archive/v1.1.tar.gz -O data.tar.gz && \
    tar -xzf data.tar.gz  && rm data.tar.gz

FROM busybox AS conda_files
ENV CONDA_VERSION="4.6.14" CONDA_MD5_CHECKSUM="718259965f234088d785cad1fbd7de03"
RUN wget "http://repo.continuum.io/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh" -O miniconda.sh && \
    echo "$CONDA_MD5_CHECKSUM  miniconda.sh" | md5sum -c

FROM busybox  AS glibc_files
# FROM scratch
# ADD rootfs.tar /

# CMD [ "/bin/sh" ]
RUN GLIBC_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    GLIBC_VER="2.29-r0" && \
    GLIBC_BASE="glibc-$GLIBC_VER.apk" && \
    GLIBC_BIN="glibc-bin-$GLIBC_VER.apk" && \
    GLIBC_I18N="glibc-i18n-$GLIBC_VER.apk" && \
    wget --no-check-certificate "$GLIBC_URL/$GLIBC_VER/$GLIBC_BASE" -O glibc_base.apk && \
    wget --no-check-certificate "$GLIBC_URL/$GLIBC_VER/$GLIBC_BIN" -O glibc_bin.apk && \
    wget --no-check-certificate "$GLIBC_URL/$GLIBC_VER/$GLIBC_I18N" -O glibc_i18n.apk 

# SECOND STAGE OF BUILD alpine + glibc # -----------------------------------------------------------------------------------------------

FROM alpine:latest AS alp_glibc

# set C.UTF-8 locale as default
ENV LANG=C.UTF-8

COPY --from=glibc_files *.apk /

RUN echo \
    "-----BEGIN PUBLIC KEY-----\
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
    y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
    tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
    m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
    KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
    Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
    1QIDAQAB\
    -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    apk add --no-cache glibc_base.apk glibc_bin.apk glibc_i18n.apk  && \
    \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && apk del .build-dependencies && \
    rm "/root/.wget-hsts" && \
    rm glibc_base.apk glibc_bin.apk  glibc_i18n.apk 


# # install GNU libc (aka glibc)
# RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
#     ALPINE_GLIBC_PACKAGE_VERSION="2.29-r0" && \
#     ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
#     ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
#     ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
#     apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
#     echo \
#         "-----BEGIN PUBLIC KEY-----\
#         MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
#         y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
#         tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
#         m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
#         KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
#         Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
#         1QIDAQAB\
#         -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
#     wget "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
#          "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
#          "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
#     apk add --no-cache "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
#     rm "/etc/apk/keys/sgerrand.rsa.pub" && \
# RUN apk add --no-cache glibc_base.apk glibc_bin.apk glibc_i18n.apk  && \
#     \
#     /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
#     echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
#     \
#     apk del glibc-i18n && apk del .build-dependencies && \
#     rm "/root/.wget-hsts" && \
#     rm glibc_base.apk glibc_bin.apk  glibc_i18n.apk 
#     rm "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"


# THIRD STAGE OF BUILD conda # ---------------------------------------------------------------------------------------------------------

FROM alp_glibc AS alp_glibc_conda

COPY --from=conda_files miniconda.sh miniconda.sh

# install conda
ENV CONDA_DIR="/opt/conda"
ENV PATH="$CONDA_DIR/bin:$PATH"
RUN mkdir -p "$CONDA_DIR" && \
    /bin/sh miniconda.sh -f -b -p "$CONDA_DIR" && \
    echo "export PATH=$CONDA_DIR/bin:\$PATH" > /etc/profile.d/conda.sh && \
    rm miniconda.sh && rm -r "$CONDA_DIR/pkgs/" && \
    mkdir -p "$CONDA_DIR/locks" && chmod 777 "$CONDA_DIR/locks" && \
    conda update conda && conda config --set auto_update_conda False

# FOURTH STAGE OF BUILD python/jupyter # -----------------------------------------------------------------------------------------------

FROM alp_glibc_conda

MAINTAINER dbye68@gmail.com

COPY --from=sample_data /sample-spatial-data-1.1 /home/ggj/sample_data

# configure conda packages
RUN conda config --append channels conda-forge && conda install -y numpy pandas geopandas gdal shapely rasterio fiona rasterstats \
    descartes pySAL xarray scikit-image scikit-learn folium pyproj ipython jupyterlab ipywidgets beakerx tk qgrid cached-property \
    dotmap && conda update --all && conda clean --all -f -y && pip install gis-metadata-parser pycrsx

# Jupyyter listens on port 8888
EXPOSE 8888

# add user
RUN mkdir -p /home/ggj/host && \
    mkdir -p /home/ggj/sample_data && \
    adduser -D -g '' ggj
USER ggj
WORKDIR /home/ggj

# ggj
ENV GDEV="21"
RUN wget --no-check-certificate -O ggj.tar.gz https://github.com/byezy/ggj/archive/v$GDEV-dev.tar.gz && \
    tar -xzf ggj.tar.gz && rm ggj.tar.gz && mv /home/ggj/ggj-$GDEV-dev/* /home/ggj && rm -rf /home/ggj/ggj-$GDEV-dev

# Run Jupyter notebook
CMD ["jupyter", "lab", "--notebook-dir=/home/ggj", "--ip='0.0.0.0'", "--port=8888", "--NotebookApp.token=''", "--NotebookApp.password=''", "--allow-root", "--no-browser"]
