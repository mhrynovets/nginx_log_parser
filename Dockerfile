FROM python:3.11-alpine

# Install necessary utils
RUN apk add --no-cache git openssh-client

WORKDIR /app

# Copy scripts
COPY parser.py .
COPY entrypoint.sh .

# Mark entry script executable
RUN chmod +x /app/entrypoint.sh

# Define an entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]