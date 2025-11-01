# Lightweight Python image
FROM python:3.10-slim

# Prevent cache clutter & improve logs
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system deps only once
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /app

# Copy requirements first for layer caching
COPY requirements.txt .

# Install deps but skip heavy spaCy model
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    python -m spacy validate || true

# Copy the rest of the app
COPY . .

# Don't download spacy model during build (too slow for Railway)
# Download it dynamically when container starts if not found
RUN echo '#!/bin/bash\n\
if ! python -m spacy validate 2>/dev/null | grep -q "en_core_web_sm"; then\n\
  echo "Downloading spaCy model..."\n\
  python -m spacy download en_core_web_sm\n\
fi\n\
exec python main.py' > /app/start.sh && chmod +x /app/start.sh

# Use Railway's port variable
ENV PORT=8080
EXPOSE 8080

# Run through the start script
CMD ["bash", "start.sh"]
