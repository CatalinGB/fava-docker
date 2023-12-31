FROM python:3.12.1

ENV BEANCOUNT_FILE ""
ENV FAVA_OPTIONS "-H 0.0.0.0 -p 5000"

RUN apt update\
    && apt install -y ghostscript libgl1-mesa-glx git vim tmux cron

COPY requirements.txt .

RUN pip install -r requirements.txt

RUN touch /var/log/cron.log
# Setup cron job
RUN (crontab -l ; echo "10 23 * * * /bin/bash /myData/cron.daily > /myData/cron.log 2>&1") | crontab

# Default fava port number
EXPOSE 5000

CMD fava $FAVA_OPTIONS $BEANCOUNT_FILE
