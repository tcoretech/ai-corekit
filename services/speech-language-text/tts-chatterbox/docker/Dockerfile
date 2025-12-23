FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    libsndfile1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN pip install --no-cache-dir -e .
RUN pip install --no-cache-dir gradio

EXPOSE 7860

CMD ["python", "gradio_tts_app.py"]
