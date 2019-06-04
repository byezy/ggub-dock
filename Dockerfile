# FIRST STAGE OF BUILD #

FROM busybox AS data

RUN mkdir /gg_sample_data
WORKDIR /gg_sample_data

# get sample Armidale spatial data
RUN wget --no-check-certificate -O armidale.tar.gz https://github.com/NSW-OEH-EMS-KST/grid-garage-sample-data/archive/GridGarage_SampleData_v1.0.2.tar.gz && \
    tar -xzf armidale.tar.gz && rm armidale.tar.gz

# get sample MCASS spatial data
RUN wget --no-check-certificate -O mcass.tar.gz https://github.com/byezy/mcassexample/archive/v1.0.tar.gz && \
    tar -xzf mcass.tar.gz && rm mcass.tar.gz

# # BeakerX
# RUN wget --no-check-certificate -O beakerx.tar.gz https://github.com/twosigma/beakerx/archive/1.4.1.tar.gz && \
#     tar -xzf beakerx.tar.gz && rm beakerx.tar.gz

# get conda 
ENV CONDA_VERSION="4.6.14"
ENV CONDA_MD5_CHECKSUM="718259965f234088d785cad1fbd7de03"
WORKDIR /
RUN wget "http://repo.continuum.io/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh" -O miniconda.sh && \
    echo "$CONDA_MD5_CHECKSUM  miniconda.sh" | md5sum -c

#######################

FROM alpine:latest AS alp_glibc

ENV LANG=C.UTF-8

# Here we install GNU libc (aka glibc) and set C.UTF-8 locale as default.

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
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

# SECOND STAGE OF BUILD

FROM alp_glibc

# ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Alpine
RUN apk update
RUN apk add --no-cache bash build-base npm nodejs libgcc
RUN update-ca-certificates
RUN apk upgrade

COPY --from=data /miniconda.sh .

# Install conda
ENV CONDA_DIR="/opt/conda"
RUN mkdir -p "$CONDA_DIR" 

# RUN mkdir -p "$CONDA_DIR" && \
#     wget "http://repo.continuum.io/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh" -O miniconda.sh && \
#     echo "$CONDA_MD5_CHECKSUM  miniconda.sh" | md5sum -c && \
#     bash miniconda.sh -f -b -p "$CONDA_DIR" && \
#     echo "export PATH=$CONDA_DIR/bin:\$PATH" > /etc/profile.d/conda.sh && \
#     rm miniconda.sh


# # RUN mkdir -p "$CONDA_DIR"
RUN bash miniconda.sh -f -b -p "$CONDA_DIR" && \
    echo "export PATH=$CONDA_DIR/bin:\$PATH" > /etc/profile.d/conda.sh && \
    rm miniconda.sh 
ENV PATH="$CONDA_DIR/bin:$PATH"
RUN \
    conda update conda && conda config --set auto_update_conda False && \
    rm -r "$CONDA_DIR/pkgs/" && apk del --purge .build-dependencies && mkdir -p "$CONDA_DIR/locks" && \
    chmod 777 "$CONDA_DIR/locks"


# THIRD STAGE OF BUILD

FROM alp_glibc
MAINTAINER dbye68@gmail.com

COPY --from=data /gg_sample_data .

# Conda
RUN conda config --append channels conda-forge && conda install -y numpy pandas geopandas gdal shapely rasterio fiona \
    rasterstats descartes pySAL xarray scikit-image scikit-learn folium pyproj ipython jupyterlab ipywidgets beakerx tk qgrid
RUN conda update --all && conda clean --all -f -y

RUN pip install gis-metadata-parser pycrsx

# Jupyyter listens on port 8888

EXPOSE 8888

# add user
RUN mkdir -p /home/gg/host
RUN adduser -D -g '' gg
USER gg
WORKDIR /home/gg

COPY --from=data /gg_sample_data .

# gg
RUN wget --no-check-certificate -O ggub.tar.gz https://github.com/byezy/ggub/archive/v16-dev.tar.gz && \
    tar -xzf ggub.tar.gz && rm ggub.tar.gz

# Run Jupyter notebook

# CMD ["jupyter", "lab", "--notebook-dir=/home/jovyan/work", "--ip='0.0.0.0'", "--port=8888", "--NotebookApp.token=''", "--NotebookApp.password=''", "--allow-root", "--no-browser"]
CMD ["jupyter", "lab", "--notebook-dir=/home/gg", "--ip='0.0.0.0'", "--port=8888", "--NotebookApp.token=''", "--NotebookApp.password=''", "--allow-root", "--no-browser"]
