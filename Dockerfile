FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg2 \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    xvfb \
    wine \
    winetricks \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Configure Wine
RUN wine --version
ENV WINEARCH=win64
ENV WINEPREFIX=/root/.wine

# Initialize Wine
RUN winecfg

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install Node.js dependencies
RUN npm install --production

# Copy application code
COPY src/ ./src/

# Create necessary directories
RUN mkdir -p uploads compiled temp logs

# Create MetaTrader 5 directory structure
RUN mkdir -p /opt/metatrader5 /root/.wine/drive_c/Program\ Files/MetaTrader\ 5

# For production, uncomment and modify the following lines to install actual MT5:
# RUN wget -O mt5setup.exe "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe"
# RUN wine mt5setup.exe /S
# ENV MT5_PATH="/root/.wine/drive_c/Program Files/MetaTrader 5"

# For development/testing, create a mock compiler script
COPY mock-compiler.sh /opt/metatrader5/metaeditor64.exe
RUN chmod +x /opt/metatrader5/metaeditor64.exe

# Set environment variables
ENV MT5_PATH=/opt/metatrader5
ENV NODE_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Create startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Start the application
CMD ["/app/start.sh"]
