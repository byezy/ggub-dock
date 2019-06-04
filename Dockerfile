# FIRST STAGE OF BUILD static data #

FROM busybox AS data

# get sample spatial data
RUN wget --no-check-certificate -O data.tar.gz https://github.com/byezy/sample-spatial-data/archive/v1.1.tar.gz && \
    tar -xzf data.tar.gz  && rm data.tar.gz

# SECOND STAGE OF BUILD alpine + glibc #

FROM alpine:latest AS alp_glibc

# set C.UTF-8 locale as default
ENV LANG=C.UTF-8

# install GNU libc (aka glibc)
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.29-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
         "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
         "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && apk del .build-dependencies && \
    rm "/root/.wget-hsts" && \
    rm "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

RUN apk update
RUN apk add --no-cache bash 
RUN apk upgrade

# THIRD STAGE OF BUILD conda #

FROM alp_glibc AS alp_glibc_conda

# get conda 
ENV CONDA_VERSION="4.6.14"
ENV CONDA_MD5_CHECKSUM="718259965f234088d785cad1fbd7de03"
WORKDIR /
RUN wget "http://repo.continuum.io/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh" -O miniconda.sh && \
    echo "$CONDA_MD5_CHECKSUM  miniconda.sh" | md5sum -c

# install conda
ENV CONDA_DIR="/opt/conda"
RUN mkdir -p "$CONDA_DIR" && \
    bash miniconda.sh -f -b -p "$CONDA_DIR" && \
    echo "export PATH=$CONDA_DIR/bin:\$PATH" > /etc/profile.d/conda.sh && \
    rm miniconda.sh && rm -r "$CONDA_DIR/pkgs/" && \
    mkdir -p "$CONDA_DIR/locks" && chmod 777 "$CONDA_DIR/locks"

ENV PATH="$CONDA_DIR/bin:$PATH"

RUN conda update conda && conda config --set auto_update_conda False

# FOURTH STAGE OF BUILD python/jupyter #

FROM alp_glibc_conda

MAINTAINER dbye68@gmail.com

# configure conda packages
RUN conda config --append channels conda-forge && conda install -y numpy pandas geopandas gdal shapely rasterio fiona \
    rasterstats descartes pySAL xarray scikit-image scikit-learn folium pyproj ipython jupyterlab ipywidgets beakerx tk qgrid
RUN conda update --all && conda clean --all -f -y

RUN pip install gis-metadata-parser pycrsx

# Jupyyter listens on port 8888

EXPOSE 8888

# add user
RUN mkdir -p /home/ggj/host
RUN mkdir -p /home/ggj/sample_data
RUN adduser -D -g '' ggj
USER ggj
WORKDIR /home/ggj

COPY --from=data /sample-spatial-data-1.1 /home/ggj/sample_data
# COPY --from=data /sample_data/mcass /home/gg/sample_data

# gg
RUN wget --no-check-certificate -O ggj.tar.gz https://github.com/byezy/ggj/archive/v17-dev.tar.gz && \
    tar -xzf ggj.tar.gz && rm ggj.tar.gz

# Run Jupyter notebook

CMD ["jupyter", "lab", "--notebook-dir=/home/ggj", "--ip='0.0.0.0'", "--port=8888", "--NotebookApp.token=''", "--NotebookApp.password=''", "--allow-root", "--no-browser"]
