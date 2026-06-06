# Build stage
FROM oven/bun:1-alpine AS builder
WORKDIR /app

# Copy package files
COPY package*.json bun.lock* ./

# Install build dependencies for native modules
RUN apk add --no-cache libc6-compat

# Install dependencies with bun
RUN bun install --frozen-lockfile --production

# Production stage
FROM oven/bun:1-alpine

# Add labels
LABEL maintainer="Fajri Rinaldi Chan <fajri@gariskode.com>"
LABEL description="Chatery WhatsApp API - Multi-session WhatsApp API"
LABEL version="1.0.0"

# Install runtime compatibility library
RUN apk add --no-cache libc6-compat

# Create non-root user for security
RUN addgroup -g 1001 -S chatery && \
    adduser -S -D -H -u 1001 -G chatery chatery

WORKDIR /app

# Copy dependencies from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy application files
COPY . .

# Create directories for sessions and media with proper permissions
RUN mkdir -p /app/sessions /app/public/media /app/store && \
    chown -R chatery:chatery /app

# Switch to non-root user
USER chatery

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Start the application
CMD ["bun", "run", "index.js"]