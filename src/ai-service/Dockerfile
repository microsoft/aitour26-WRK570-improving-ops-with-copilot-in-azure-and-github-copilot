# Use the official Python image as the base image
FROM python:3.12.7-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
	PYTHONUNBUFFERED=1 \
	PIP_NO_CACHE_DIR=1 \
	PIP_DISABLE_PIP_VERSION_CHECK=1

# Set the working directory to /app
WORKDIR /app

# Set the build argument for the app version number
ARG APP_VERSION=0.1.0

# Create a non-root user for running the application
RUN addgroup -S app && adduser -S -G app -u 10001 app

# Copy the requirements file into the container
COPY requirements.txt .

# Install the dependencies
RUN python -m pip install -r requirements.txt

# Copy only the application code needed at runtime
COPY --chown=app:app main.py ./
COPY --chown=app:app routers ./routers

# Expose port 5001 for the FastAPI application
EXPOSE 5001

# Set the environment variable for the app version number
ENV APP_VERSION=$APP_VERSION

# Run the application as a non-root user
USER app

# Start the FastAPI application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5001"]