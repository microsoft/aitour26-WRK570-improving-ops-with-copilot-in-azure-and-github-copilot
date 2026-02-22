# Use the official Python image as the base image - builder stage
FROM python:3.12.7-alpine AS builder

# Set the working directory to /app
WORKDIR /app

# Set the build argument for the app version number
ARG APP_VERSION=0.1.0

# Copy the requirements file into the container
COPY requirements.txt .

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.12.7-alpine

# Add labels for security and metadata
LABEL org.opencontainers.image.title="AI Service"
LABEL org.opencontainers.image.description="FastAPI microservice for AI operations"
LABEL security.scan="true"

# Create a non-root user to run the application
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set the working directory to /app
WORKDIR /app

# Copy dependencies from builder stage
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy the application code with correct permissions
COPY --chown=appuser:appgroup . .

# Set the build argument for the app version number
ARG APP_VERSION=0.1.0

# Set the environment variable for the app version number
ENV APP_VERSION=$APP_VERSION

# Switch to non-root user
USER appuser

# Expose port 5001 for the FastAPI application
EXPOSE 5001

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5001/health').read()" || exit 1

# Start the FastAPI application
CMD ["uvicorn", "main:app", "--host", "127.0.0.1", "--port", "5001"]