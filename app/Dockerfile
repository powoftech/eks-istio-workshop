# app/Dockerfile

# Stage 1: Use a specific, slim base image to reduce attack surface.
FROM node:22-slim AS base

# Create a dedicated, non-root user and group for the application.
# This is a critical security measure.
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 appuser

WORKDIR /home/appuser/app

# Copy only the necessary file and set correct permissions.
COPY --chown=appuser:nodejs app.js .

# Switch to the non-root user. Any subsequent commands run as this user.
USER appuser

# Expose the port the app runs on.
EXPOSE 8080

# Command to run the application.
CMD [ "node", "app.js" ]