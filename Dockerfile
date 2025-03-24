# See the value of userImage in
#
#   https://github.com/UninettSigma2/helm-charts/blob/master/repos/stable/jupyterhub/values.yaml
#
# to determine the latest base image

# The image to use as a base image
FROM sigma2as/jupyterhub-singleuser:20240301-21d3e39 AS sigma2

#MAINTAINER Matvey Debolskiy <m.v.debolskiy@geo.uio.no>


RUN mamba config --set channel_priority strict && \
    mamba install --quiet --yes --update-all -c conda-forge \
    'escapism==1.0.1' \
    'jupyterlab-github>=4.0.0' \
    'jupyter-server-proxy>=4.1.0' \
    'ipyparallel==6.3.0' \
    'yapf>=0.40.1' \
    'nodejs>=18.19.0' \
    'nb_conda_kernels==2.5.0' \
    'nbgitpuller' \
    'escapism==1.0.1' \
    'ipywidgets>=8.0.0'\
    'ipykernel' \
    'sidecar' \
    'dask-labextension'\
    'git'\
    'jupyter_contrib_nbextensions' \
    'jupyter-resource-usage' \
    'ipympl' && \
    mamba install -c plotly 'plotly=5.22' 'jupyter-dash' && \ 
    jupyter server extension enable jupyter_server_proxy --sys-prefix && \ 
    jupyter server extension enable nbdime --sys-prefix &&\
    jupyter lab extension enable dask-labextension &&\
    jupyter lab extension enable jupytext &&\
    mamba clean --all -f -y

RUN mamba create -n minimal -y && bash -c 'source activate minimal && conda install -y ipykernel && ipython kernel install --name=minimal --display-name="Python 3 (minimal conda)" && conda clean --all -f -y && conda deactivate'

FROM sigma2

# Install system packages
USER root
RUN apt update -y && apt install -y vim

#RUN conda install conda=23.7.4
RUN apt install -y netcdf-bin
RUN apt install -y cdo
RUN apt install -y nco

#Install requiraments for python 3
ADD jupyterhub_environment.yml jupyterhub_environment.yml

RUN set -o pipefail

RUN conda update conda --yes

ENV PANGEO_VERSION=2024.06.23

RUN mamba create -n labs \
    --file https://raw.githubusercontent.com/pangeo-data/pangeo-docker-images/${PANGEO_VERSION}/pangeo-notebook/conda-linux-64.lock  && \
    mamba clean --all -f -y

RUN mamba install -y -n labs \
    'scikit-learn' \
    'rioxarray' \
    'hypothesis' \
    'basemap' \
    'nco' \
    'python-cdo' \
    'threddsclient' \
    'plotly' \
    'geocat-viz' \
    'geocat-comp' \
    'geocat-f2py' \
    'gcc_linux-64' 'gxx_linux-64' \
    'assimulo' \
    'ipympl' \
    'xclim' && \
    mamba clean --all -f -y

RUN bash -c "mamba run -n labs python -m pip install pyet"

RUN bash -c "mamba run -n labs python -m pip install --no-deps climate-indices"

RUN mamba clean --all -f -y

RUN python -m nb_conda_kernels list

#RUN /opt/conda/bin/jupyter labextension install @jupyterlab/hub-extension @jupyter-widgets/jupyterlab-manager
#RUN /opt/conda/bin/nbdime extensions --enable
#RUN /opt/conda/bin/jupyter labextension install jupyterlab-datawidgets nbdime-jupyterlab dask-labextension
#RUN /opt/conda/bin/jupyter labextension install @jupyter-widgets/jupyterlab-sidecar
#RUN /opt/conda/bin/jupyter labextension enable jupytext
#RUN /opt/conda/bin/jupyter labextension enable dask-labextension
#RUN conda init bash

RUN eval $(conda shell.bash hook)

#RUN echo "source activate base" > $HOME/.bashrc
ENV PATH=/opt/conda/envs/env/bin:$PATH
ENV ESMFMKFILE=/opt/conda/lib/esmf.mk




RUN mkdir /opt/extras


COPY --chown=notebook:notebook dask.yaml /opt/extras/dask.yaml

COPY --chown=notebook:notebook ./nbconfig /opt/extras/nbconfig

COPY --chown=notebook:notebook jupyter_server_config.py /opt/extras/jupyter_server_config.py

# fix permission problems (hub is then failing)
RUN fix-permissions $HOME

WORKDIR $HOME

RUN cd ~

# Install other packages


USER notebook

