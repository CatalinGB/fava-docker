ARG BEANCOUNT_VERSION=2.3.5
ARG FAVA_VERSION=v1.24

ARG NODE_BUILD_IMAGE=16-bullseye
FROM node:${NODE_BUILD_IMAGE} as node_build_env
ARG FAVA_VERSION

WORKDIR /tmp/build
RUN git clone https://github.com/beancount/fava

RUN apt-get update
RUN apt-get install -y build-essential libxml2-dev libxslt-dev curl \
        python3 python3-babel libpython3-dev python3-pip git python3-venv tig git nano build-essential gcc poppler-utils wget git bash vim cron

WORKDIR /tmp/build/fava
RUN git checkout ${FAVA_VERSION}
RUN make
RUN rm -rf .*cache && \
    rm -rf .eggs && \
    rm -rf .tox && \
    rm -rf build && \
    rm -rf dist && \
    rm -rf frontend/node_modules && \
    find . -type f -name '*.py[c0]' -delete && \
    find . -type d -name "__pycache__" -delete

FROM debian:bullseye as build_env
ARG BEANCOUNT_VERSION

RUN apt-get update
RUN apt-get install -y build-essential libxml2-dev libxslt-dev curl \
        python3 libpython3-dev python3-pip git python3-venv coreutils


ENV PATH "/app/bin:$PATH"
RUN python3 -mvenv /app
COPY --from=node_build_env /tmp/build/fava /tmp/build/fava

WORKDIR /tmp/build
RUN git clone https://github.com/beancount/beancount

WORKDIR /tmp/build/beancount
RUN git checkout ${BEANCOUNT_VERSION}

RUN CFLAGS=-s pip3 install -U /tmp/build/beancount
RUN pip3 install -U /tmp/build/fava

#RUN python3 -mpip install pytest
#RUN pip3 install -U pip setuptools
#RUN python3 -mpip install babel
#RUN python3 -mpip install smart_importer 
#RUN python3 -mpip install beancount_portfolio_allocation
#RUN python3 -mpip install beancount-plugins-metadata-spray
#RUN python3 -mpip install beancount-interpolate
#RUN python3 -mpip install iexfinance
#RUN python3 -mpip install black
#RUN python3 -mpip install argh
#RUN python3 -mpip install argcomplete
#RUN python3 -mpip install pre-commit
#RUN python3 -mpip install git+https://github.com/beancount/beanprice.git
#RUN python3 -mpip install tariochbctools
#RUN python3 -mpip install flake8
#RUN python3 -mpip install beancount-import
RUN python3 -mpip install git+https://github.com/redstreet/fava_investor
#RUN python3 -mpip install git+https://github.com/andreasgerstmayr/fava-income-reports.git
RUN python3 -mpip install nordigen
RUN python3 -mpip install thefuzz

RUN touch /var/log/cron.log
# Setup cron job
#RUN (crontab -l ; echo "10 23 * * * /bin/bash /myData/cron.daily > /myData/cron.log 2>&1") | crontab

RUN pip3 uninstall -y pip

RUN find /app -name __pycache__ -exec rm -rf -v {} +

FROM gcr.io/distroless/python3-debian11
COPY --from=build_env /app /app

# Default fava port number
EXPOSE 5000

ENV BEANCOUNT_FILE ""
ENV FAVA_OPTIONS ""

ENV PYTHONPATH "${PYTHONPATH}:/bean/importers"

# Required by Click library.
# See https://click.palletsprojects.com/en/7.x/python3/
ENV LC_ALL "C.UTF-8"
ENV LANG "C.UTF-8"
ENV FAVA_HOST "0.0.0.0"
ENV PATH "/app/bin:$PATH"

WORKDIR /bean

#USER root
COPY entrypoint.sh /bean/entrypoint.sh
#RUN chmod a+x /bean/entrypoint.sh
#USER 1001

ENTRYPOINT ["/bean/entrypoint.sh"]