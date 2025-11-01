# Use a small, optimized base image
FROM python:3.10-slim

# Disable bytecode generation and buffering for cleaner logs
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install minimal system dependencies (for Whisper, ffmpeg, etc.)
RUN apt-get update && apt-get install -y \
    ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy only dependency files first for layer caching
COPY requirements.txt .

# Install dependencies without cache to keep image size small
RUN pip install --no-cache-dir -r requirements.txt

# Download small language/model resources ahead of time (optional)
# This prevents runtime downloads during deployment
RUN python -m spacy download en_core_web_sm || true

# Copy the rest of the app
COPY . .

# Environment variable for Railway or Render
ENV PORT=8080

# Expose port (helps for local Docker testing)
EXPOSE 8080

# Default command (you can adjust if entrypoint file differs)
CMD ["python", "main.py"]
