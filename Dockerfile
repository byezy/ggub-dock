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

# BeakerX
RUN wget --no-check-certificate -O beakerx.tar.gz https://github.com/twosigma/beakerx/archive/1.4.1.tar.gz && \
    tar -xzf beakerx.tar.gz && rm beakerx.tar.gz

# SECOND STAGE OF BUILD

FROM frolvlad/alpine-miniconda3:latest
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
MAINTAINER dbye68@gmail.com

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Alpine
RUN apk update
RUN apk --no-cache add bash build-base npm nodejs libgcc git tar bzip2 ca-certificates
RUN update-ca-certificates
RUN apk upgrade

# Conda
RUN conda update conda && conda config --append channels conda-forge
RUN conda install -y numpy pandas geopandas gdal rasterio ipython jupyterlab ipywidgets beakerx tk qgrid
RUN conda update --all && conda clean --all -f -y

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
