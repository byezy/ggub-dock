# FIRST STAGE OF BUILD static data # ---------------------------------------------------------------------------------------------------

FROM busybox AS downloads

RUN wget https://github.com/byezy/sample-spatial-data/archive/v1.1.tar.gz -O data.tar.gz && \
    tar -xzf data.tar.gz  && rm data.tar.gz

ENV CONDA_VERSION="4.6.14" CONDA_MD5_CHECKSUM="718259965f234088d785cad1fbd7de03"
RUN wget "http://repo.continuum.io/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh" -O miniconda.sh && \
    echo "$CONDA_MD5_CHECKSUM  miniconda.sh" | md5sum -c

# SECOND STAGE OF BUILD conda # ---------------------------------------------------------------------------------------------------------

FROM frolvlad/alpine-glibc AS alp_glibc_conda

COPY --from=downloads miniconda.sh miniconda.sh

# install conda
ENV CONDA_DIR="/opt/conda"
ENV PATH="$CONDA_DIR/bin:$PATH"
RUN mkdir -p "$CONDA_DIR" && \
    /bin/sh miniconda.sh -f -b -p "$CONDA_DIR" && \
    echo "export PATH=$CONDA_DIR/bin:\$PATH" > /etc/profile.d/conda.sh && \
    rm miniconda.sh && rm -r "$CONDA_DIR/pkgs/" && \
    mkdir -p "$CONDA_DIR/locks" && chmod 777 "$CONDA_DIR/locks" && \
    conda update conda && conda config --set auto_update_conda False

# THIRD STAGE OF BUILD python/jupyter # -----------------------------------------------------------------------------------------------

FROM alp_glibc_conda

MAINTAINER dbye68@gmail.com

COPY --from=downloads /sample-spatial-data-1.1 /home/ggj/sample_data

RUN apk add --nocache bash

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
