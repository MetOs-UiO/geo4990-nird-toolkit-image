# See the value of userImage in
#
#   https://github.com/UninettSigma2/helm-charts/blob/master/repos/stable/jupyterhub/values.yaml
#
# to determine the latest base image

# The image to use as a base image
FROM quay.io/nird-toolkit/jupyterhub-singleuser:20230817-9e3b220

MAINTAINER Matvey Debolskiy <m.v.debolskiy@geo.uio.no>

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

RUN conda env update -f jupyterhub_environment.yml

RUN /opt/conda/bin/jupyter labextension install @jupyterlab/hub-extension @jupyter-widgets/jupyterlab-manager
RUN /opt/conda/bin/nbdime extensions --enable
#RUN /opt/conda/bin/jupyter labextension install jupyterlab-datawidgets nbdime-jupyterlab dask-labextension
#RUN /opt/conda/bin/jupyter labextension install @jupyter-widgets/jupyterlab-sidecar
RUN /opt/conda/bin/jupyter labextension enable jupytext
RUN /opt/conda/bin/jupyter labextension enable dask-labextension
RUN conda init bash

RUN eval $(conda shell.bash hook)

RUN echo "source activate base" > $HOME/.bashrc
ENV PATH /opt/conda/envs/env/bin:$PATH
ENV ESMFMKFILE=/opt/conda/lib/esmf.mk
#RUN git clone https://github.com/ESCOMP/CTSM.git



# fix permission problems (hub is then failing)
RUN fix-permissions $HOME

WORKDIR $HOME

RUN cd ~

# Install other packages


USER notebook

