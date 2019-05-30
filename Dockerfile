FROM byezy/ggub-base:latest

# alpine

RUN apk add bash build-base npm nodejs libgcc

# conda

RUN conda update conda && conda config --append channels conda-forge
RUN conda install -y numpy pandas geopandas gdal rasterio ipython jupyterlab ipywidgets beakerx tk pamela
RUN conda update --all && conda clean --all -f -y

RUN conda install -y qgrid
#RUN npm i beakerx-jupyterlab

#RUN conda config --env --add pinned_packages 'openjdk>8.0.121' && \
#    jupyter labextension install @jupyterlab/geojson-extension
#    jupyter labextension install beakerx-jupyterlab && \
#    jupyter labextension install @jupyter-widgets/jupyterlab-manager && \

#RUN conda install -y jupyterhub
#RUN conda install -y sqlalchemy tornado jinja2 traitlets requests pycurl

#RUN mkdir ~/work
#RUN jupyter labextension install @jupyterlab/hub-extension --debug

#RUN mkdir -p /etc/jupyter
##RUN jupyter notebook --generate-config --allow-root
#WORKDIR /etc/jupyter
#RUN jupyterhub --generate-config
##RUN echo "c.NotebookApp.password = u'sha1:6a3f528eec40:6e896b6e4828f525a6e20e5411cd1c8075d68619'" >> ~/.jupyter/jupyter_notebook_config.py
#RUN echo "c.Spawner.default_url = '/lab'" >> /etc/jupyter/jupyterhub_config.py
#RUN find -name jupyterhub_config.py -print
#WORKDIR ~/work

# Jupyyter listens on port 8888

#EXPOSE 8888

# add user
#RUN adduser -D -g '' gguser
#USER gguser
#WORKDIR /home/gguser

# Run Jupyter notebook

#CMD ["jupyter", "lab", "--ip", "0.0.0.0", "--allow-root"]
#
#ADD . /src/jupyterhub
#WORKDIR /src/jupyterhub
#
#RUN pip install . && rm -rf $PWD ~/.cache ~/.npm
#
#RUN mkdir -p /srv/jupyterhub/
#WORKDIR /srv/jupyterhub/
#EXPOSE 8000
#LABEL org.jupyter.service="jupyterhub"

# add user
RUN adduser -D -g '' gg
USER gg
WORKDIR /home/gg

# get github code source

RUN wget --no-check-certificate -O ggub.tar.gz https://github.com/byezy/ggub/archive/v16-dev.tar.gz && \
    tar -xzf ggub.tar.gz && rm ggub.tar.gz

CMD ["jupyter", "lab", "--notebook-dir=/home/gg/", "--ip='0.0.0.0'", "--port=8888", "--NotebookApp.token=''", "--NotebookApp.password=''"]
