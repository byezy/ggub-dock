FROM frolvlad/alpine-miniconda3:latest

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# alpine

RUN apk update
RUN apk --no-cache add bash build-base npm nodejs libgcc git tar bzip2 ca-certificates
RUN update-ca-certificates
RUN apk upgrade

#conda

RUN conda update conda && conda config --append channels conda-forge
RUN conda install -y numpy pandas geopandas gdal rasterio ipython jupyterlab ipywidgets beakerx tk qgrid
RUN conda update --all && conda clean --all -f -y

# Jupyyter listens on port 8888

EXPOSE 8888

# add user
# RUN mkdir /home/gg
# RUN adduser -D -g '' gg
# USER gg
# WORKDIR /home/gg
# RUN chmod -R 777 /home/gg

# Run Jupyter notebook

CMD ["jupyter", "lab", "--notebook-dir=/home/jovyan/work", "--ip='0.0.0.0'", "--port=8888", "--NotebookApp.token=''", "--NotebookApp.password=''", "--allow-root", "--no-browser"]
