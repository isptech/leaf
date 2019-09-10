FROM python:3


WORKDIR /src

# We add requirements first so that we can decrease the usual build time by using a cached layer.

ADD ./requirements.txt /src/
RUN pip install -r requirements.txt

# Add everything else and run the app!
ADD ./take_home.py /src/
CMD ["python", "./take_home.py"]
