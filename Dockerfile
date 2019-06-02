FROM byezy/ggub-base:latest

# Jupyyter listens on port 8888

EXPOSE 8888

# add user
# RUN mkdir /home/gg
# RUN adduser -D -g '' gg
# USER gg
# WORKDIR /home/gg
# RUN chmod -R 777 /home/gg

# get github code source

RUN wget --no-check-certificate -O ggub.tar.gz https://github.com/byezy/ggub/archive/v16-dev.tar.gz && \
    tar -xzf ggub.tar.gz && rm ggub.tar.gz

# Run Jupyter notebook

CMD ["jupyter", "lab", "--notebook-dir=/home/gg/", "--ip='0.0.0.0'", "--port=8888", "--NotebookApp.token=''", "--NotebookApp.password=''", "--allow-root"]
