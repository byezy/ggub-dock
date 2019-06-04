# FIRST STAGE OF BUILD

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

# SECOND STAGE OF BUILD

FROM alpine:latest AS alpine_os

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Alpine
RUN apk update
RUN apk add--no-cache bash build-base npm nodejs libgcc git tar bzip2 ca-certificates
RUN update-ca-certificates
RUN apk upgrade

ENV CONDA_DIR="/opt/conda"
ENV PATH="$CONDA_DIR/bin:$PATH"

COPY --from=data /miniconda.sh .

# Install conda
RUN bash miniconda.sh -f -b -p "$CONDA_DIR" && echo "export PATH=$CONDA_DIR/bin:\$PATH" > /etc/profile.d/conda.sh && \
    rm miniconda.sh && \ conda update conda && conda config --set auto_update_conda False && \
    rm -r "$CONDA_DIR/pkgs/" && apk del --purge .build-dependencies && mkdir -p "$CONDA_DIR/locks" && \
    chmod 777 "$CONDA_DIR/locks"

# THIRD STAGE OF BUILD

FROM alpine_os
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
