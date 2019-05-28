FROM frolvlad/alpine-miniconda3:latest

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

#RUN apk add bash bzip2 ca-certificates curl git grep sed tini wget
#RUN apk add bash git
#bzip2 ca-certificates curl git tar tini wget

RUN conda update conda && conda config --append channels conda-forge && \
    conda install -y numpy pandas geopandas gdal rasterio ipython jupyterlab ipywidgets beakerx tk nodejs && \
    conda update --all
    #pip install git+https://github.com/pyjs/pyjs.git#egg=pyjs && conda update --all
    
RUN conda config --env --add pinned_packages 'openjdk>8.0.121' && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
    jupyter labextension install beakerx-jupyterlab && \
    jupyter labextension install @jupyterlab/geojson-extension && \
    conda clean --all -f -y
    
RUN mkdir ~/work
#RUN jupyter notebook --generate-config --allow-root
#RUN echo "c.NotebookApp.password = u'sha1:6a3f528eec40:6e896b6e4828f525a6e20e5411cd1c8075d68619'" >> /home/ggubu/.jupyter/jupyter_notebook_config.py
WORKDIR ~/work

# Jupyter listens on port 8888

EXPOSE 8888

# get sample Armidale spatial data

RUN wget --no-check-certificate --content-disposition -O sampledata.tar.gz https://github.com/NSW-OEH-EMS-KST/grid-garage-sample-data/archive/GridGarage_SampleData_v1.0.2.tar.gz
RUN tar -xzf sampledata.tar.gz && rm sampledata.tar.gz

# get sample MCASS spatial data

RUN wget --no-check-certificate --content-disposition -O sampledata.tar.gz https://github.com/byezy/mcassexample/archive/v1.0.tar.gz
RUN tar -xzf sampledata.tar.gz && rm sampledata.tar.gz

# get git code source to ggubu

RUN wget --no-check-certificate --content-disposition -O ggub.tar.gz https://github.com/byezy/ggub/archive/v16-dev.tar.gz
RUN tar -xzf ggub.tar.gz && rm ggub.tar.gz

# Run Jupyter notebook

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["jupyter", "lab", "--notebook-dir=/home/ggubu/", "--ip='0.0.0.0'", "--port=8888", "--no-browser", "--NotebookApp.token=''", "--NotebookApp.password=''"]
