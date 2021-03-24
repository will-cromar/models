# Creates environment to run unit tests with current nightly image.
FROM tensorflow/tensorflow:nightly-gpu

RUN pip install portpicker

ADD official /tensorflow/models/official
RUN pip install -r /tensorflow/models/official/requirements.txt

ENV PYTHONPATH=/tensorflow/models
WORKDIR /tensorflow/models
