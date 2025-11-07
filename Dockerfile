FROM rayproject/ray:2.9.0-py310

# Set working directory
WORKDIR /app

# Copy training script
COPY train.py /app/train.py

# Install additional dependencies
RUN pip install --no-cache-dir \
    torch==2.1.0 \
    torchvision==0.16.0

# The training script will be executed by the RayJob
CMD ["python", "/app/train.py"]
