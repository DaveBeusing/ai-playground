## Setup a TensorRT-LLM enviroment
check if the base system is set up correctly
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv

# Install dependencies
sudo apt install -y ninja-build python3 python3-dev python3-pip python3-venv pkg-config

# Set up paths
mkdir -p ~/ai
cd ~/ai
mkdir src venv models engines cache configs logs scripts benchmarks

# Set up Python virtual enviroment
python3 -m venv ~/ai/venv/trtllm

# Activate the Python venv
source ~/ai/venv/trtllm/bin/activate

# Update Python pip
pip install --upgrade pip wheel setuptools

# Set up CUDA vars
nano ~/.bashrc

at the end should be already
># NVIDIA CUDA
>export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
>export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
add
export CUDA_HOME=/usr/local/cuda
export HF_HOME=$HOME/ai/cache

source ~/.bashrc