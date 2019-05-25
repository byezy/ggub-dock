FROM frolvlad/alpine-miniconda3:latest

#ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
#ENV PATH /opt/conda/bin:$PATH

#RUN apk add bash bzip2 ca-certificates curl git grep sed tini wget

RUN conda update conda && conda config --append channels conda-forge && \
    conda install -y numpy pandas geopandas gdal rasterio ipython jupyterlab ipywidgets beakerx tk nodejs && \
    pip install git+https://github.com/pyjs/pyjs.git#egg=pyjs && conda update --all
