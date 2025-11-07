# Ray Train on Kubernetes with KubeRay

This project demonstrates how to run distributed PyTorch training using Ray Train on Kubernetes via the KubeRay operator.

## Overview

The example trains a CNN on the Fashion MNIST dataset using distributed training across multiple Ray workers.

### Components

- `train.py` - Python script implementing distributed training with Ray Train
- `Dockerfile` - Container image for the training workload
- `rayjob-train.yaml` - Kubernetes manifest for deploying the RayJob

## Prerequisites

- Kubernetes cluster (with kubectl configured)
- KubeRay operator installed on the cluster
- Docker (if building custom images)

## Quick Start

### Option 1: Deploy Using ConfigMap (Easiest)

This option embeds the training script in a ConfigMap, so you don't need to build or push a Docker image.

```bash
# Deploy the RayJob
kubectl apply -f rayjob-train.yaml

# Monitor the job status
kubectl get rayjob raytrain-fashion-mnist -w

# Check the logs
kubectl logs -l ray.io/node-type=head -c ray-head --follow

# View job details
kubectl describe rayjob raytrain-fashion-mnist
```

### Option 2: Build and Use Custom Image

If you want to customize the image or add dependencies:

```bash
# Build the Docker image
docker build -t your-registry/raytrain:latest .

# Push to your container registry
docker push your-registry/raytrain:latest

# Update the image in rayjob-train.yaml
# Replace 'rayproject/ray:2.9.0-py310' with 'your-registry/raytrain:latest'

# Deploy
kubectl apply -f rayjob-train.yaml
```

## Monitoring the Training Job

### Check Job Status

```bash
# Get RayJob status
kubectl get rayjob raytrain-fashion-mnist

# Expected output shows status: RUNNING, then SUCCEEDED
```

### View Training Logs

```bash
# Head node logs (main training output)
kubectl logs -l ray.io/node-type=head -c ray-head --follow

# Worker node logs
kubectl logs -l ray.io/node-type=worker -c ray-worker --follow

# All pods in the cluster
kubectl get pods -l ray.io/cluster=raytrain-fashion-mnist
```

### Access Ray Dashboard (Optional)

```bash
# Port-forward to access the Ray dashboard
kubectl port-forward svc/raytrain-fashion-mnist-head-svc 8265:8265

# Open browser to http://localhost:8265
```

## Configuration Options

### Adjusting Training Parameters

Edit `train.py` or the `train_loop_config` in the script:

```python
train_loop_config={
    "batch_size": 64,      # Batch size per worker
    "lr": 0.001,           # Learning rate
    "epochs": 5            # Number of epochs
}
```

### Scaling Workers

Edit `rayjob-train.yaml` to change the number of workers:

```yaml
workerGroupSpecs:
- replicas: 2          # Number of worker nodes
  minReplicas: 1       # Minimum for autoscaling
  maxReplicas: 4       # Maximum for autoscaling
```

### Resource Allocation

Adjust CPU/Memory resources in `rayjob-train.yaml`:

```yaml
resources:
  limits:
    cpu: "2"
    memory: "4Gi"
  requests:
    cpu: "1"
    memory: "2Gi"
```

### GPU Support

To enable GPU training:

1. Update the ScalingConfig in `train.py`:
```python
scaling_config = ScalingConfig(
    num_workers=2,
    use_gpu=True,
    resources_per_worker={
        "CPU": 2,
        "GPU": 1
    }
)
```

2. Update resources in `rayjob-train.yaml`:
```yaml
resources:
  limits:
    nvidia.com/gpu: "1"
    cpu: "4"
    memory: "8Gi"
  requests:
    nvidia.com/gpu: "1"
    cpu: "2"
    memory: "4Gi"
```

## Cleanup

```bash
# Delete the RayJob (also deletes the Ray cluster)
kubectl delete -f rayjob-train.yaml

# Verify cleanup
kubectl get rayjob
kubectl get pods
```

## Troubleshooting

### Job Stuck in PENDING

```bash
# Check pod status
kubectl get pods -l ray.io/cluster=raytrain-fashion-mnist

# Check events
kubectl describe rayjob raytrain-fashion-mnist

# Common issues:
# - Insufficient cluster resources
# - Image pull errors
# - RBAC permissions
```

### Check Pod Events

```bash
kubectl describe pod <pod-name>
```

### View All Logs

```bash
# Get all pods
kubectl get pods -l ray.io/cluster=raytrain-fashion-mnist

# View logs for specific pod
kubectl logs <pod-name> -c ray-head
```

### Job Failed

```bash
# Check job status and failure reason
kubectl describe rayjob raytrain-fashion-mnist

# View head node logs for errors
kubectl logs -l ray.io/node-type=head -c ray-head --tail=100
```

## Architecture

The RayJob creates:

1. **Head Node**: Orchestrates the Ray cluster and runs the training script
2. **Worker Nodes**: Execute distributed training tasks
3. **ConfigMap**: Contains the training code
4. **Service**: Exposes Ray dashboard and client ports

## Next Steps

- Modify the neural network architecture in `train.py`
- Experiment with different datasets
- Add hyperparameter tuning with Ray Tune
- Implement distributed data loading
- Set up persistent storage for checkpoints using PersistentVolumeClaims

## Additional Resources

- [Ray Train Documentation](https://docs.ray.io/en/latest/train/train.html)
- [KubeRay Documentation](https://ray-project.github.io/kuberay/)
- [Ray Dashboard Guide](https://docs.ray.io/en/latest/ray-observability/getting-started.html)
