FROM python:3.9

RUN apt-get update && apt-get install -y netcat-openbsd

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["python", "app.py"]