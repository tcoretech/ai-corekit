FROM python:3.11-slim@sha256:e88e9763f943ec1834f992a4b51e0f24500486803e8bc534e5767af9ea65f6ce

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
