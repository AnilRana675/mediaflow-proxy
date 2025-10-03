FROM python:3.13.5-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE="1"
ENV PYTHONUNBUFFERED="1"
ENV PORT="8888"
ENV PIP_NO_PROXY="*"
ENV HTTP_PROXY=""
ENV HTTPS_PROXY=""
ENV http_proxy=""
ENV https_proxy=""
ENV no_proxy="*"
ENV NO_PROXY="*"

# Set work directory
WORKDIR /mediaflow_proxy

# Create a non-root user
RUN useradd -m mediaflow_proxy
RUN chown -R mediaflow_proxy:mediaflow_proxy /mediaflow_proxy

# Set up the PATH to include the user's local bin
ENV PATH="/home/mediaflow_proxy/.local/bin:$PATH"

# Switch to non-root user
USER mediaflow_proxy

# Copy project files first
COPY --chown=mediaflow_proxy:mediaflow_proxy . /mediaflow_proxy

# Create requirements.txt from pyproject.toml and install dependencies directly
RUN unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy && \
    export PIP_NO_PROXY="*" && \
    pip install --user --no-cache-dir --index-url https://pypi.org/simple/ \
    fastapi==0.115.12 \
    httpx[socks,zstd]==0.28.1 \
    tenacity==9.1.2 \
    xmltodict==0.14.2 \
    pydantic-settings==2.9.1 \
    gunicorn==23.0.0 \
    pycryptodome==3.22.0 \
    uvicorn==0.34.2 \
    tqdm==4.67.1 \
    aiofiles==24.1.0 \
    beautifulsoup4==4.13.4 \
    lxml==5.4.0 \
    psutil==6.1.0

# Expose the port the app runs on
EXPOSE 8888

# Run the application with Gunicorn
CMD ["sh", "-c", "exec python -m gunicorn mediaflow_proxy.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8888 --timeout 120 --max-requests 500 --max-requests-jitter 200 --access-logfile - --error-logfile - --log-level info --forwarded-allow-ips \"${FORWARDED_ALLOW_IPS:-127.0.0.1}\""]
