FROM python:3.10-slim

# Install dependencies
RUN pip install --no-cache-dir \
    flair==0.15.1 \
    fastapi==0.115.0 \
    uvicorn==0.32.0 \
    pydantic==2.10.0

# Pre-download German and English NER models
RUN python -c "from flair.models import SequenceTagger; \
    SequenceTagger.load('de-ner-large'); \
    SequenceTagger.load('ner-large')"

# Copy API application
COPY api.py /app/

WORKDIR /app

# Expose port
EXPOSE 8000

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health').raise_for_status()" || exit 1

# Run the API
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]
