FROM python:3.14-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Create non-root user
RUN useradd -m -u 1000 anonapp && \
    chown -R anonapp:anonapp /app
USER anonapp

# Expose port
EXPOSE 8000

# Run the application
CMD ["python3", "-m", "uvicorn", "core.app:app", "--host", "0.0.0.0", "--port", "8000"]
