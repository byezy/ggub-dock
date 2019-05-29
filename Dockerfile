FROM frolvlad/alpine-miniconda3:latest

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apk add bash git tar bzip2 ca-certificates tini && update-ca-certificates

# get sample Armidale spatial data

RUN wget --no-check-certificate -O sampledata.tar.gz https://github.com/NSW-OEH-EMS-KST/grid-garage-sample-data/archive/GridGarage_SampleData_v1.0.2.tar.gz && \
    tar -xzf sampledata.tar.gz && rm sampledata.tar.gz

# get sample MCASS spatial data

RUN wget --no-check-certificate -O sampledata.tar.gz https://github.com/byezy/mcassexample/archive/v1.0.tar.gz && \
    tar -xzf sampledata.tar.gz && rm sampledata.tar.gz

# get github code source

RUN wget --no-check-certificate -O ggub.tar.gz https://github.com/byezy/ggub/archive/v16-dev.tar.gz && \
    tar -xzf ggub.tar.gz && rm ggub.tar.gz

# conda

RUN conda update conda && conda config --append channels conda-forge && \
    conda install -y numpy pandas geopandas gdal rasterio ipython jupyterlab ipywidgets beakerx tk nodejs && \
    conda update --all && \
    conda config --env --add pinned_packages 'openjdk>8.0.121' && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
    jupyter labextension install beakerx-jupyterlab && \
    jupyter labextension install @jupyterlab/geojson-extension && \
    conda clean --all -f -y

RUN apk add build-base
RUN conda install jupyterhub

RUN mkdir ~/work
RUN jupyter notebook --generate-config --allow-root
#RUN echo "c.NotebookApp.password = u'sha1:6a3f528eec40:6e896b6e4828f525a6e20e5411cd1c8075d68619'" >> ~/.jupyter/jupyter_notebook_config.py
WORKDIR ~/work

# Jupyyter listens on port 8888

EXPOSE 8888

# add user
RUN adduser -D -g '' gguser
USER gguser
WORKDIR /home/gguser

# Run Jupyter notebook

CMD ["jupyter", "lab", "--ip", "0.0.0.0", "--allow-root"]
