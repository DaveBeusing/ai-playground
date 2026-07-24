## Setup a TensorRT-LLM enviroment
check if the base system is set up correctly
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv

# Install dependencies
sudo apt install -y ninja-build python3 python3-dev python3-pip python3-venv pkg-config

# Set up paths
mkdir -p ~/ai/{src,venv,models,engines,cache,configs,logs,scripts,benchmarks}

# Set up Python virtual enviroment
python3 -m venv ~/ai/venv/trtllm

# Activate the Python venv
source ~/ai/venv/trtllm/bin/activate

# Update Python pip
pip install --upgrade pip wheel setuptools build packaging

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

# Prepare TensorRT-LLM install
cd ~/ai/scripts
wget https://raw.githubusercontent.com/DaveBeusing/ai-playground/refs/heads/main/scripts/system-versions.sh
chmod +x ~/ai/scripts/system-versions.sh
~/ai/scripts/system-versions.sh | tee ~/ai/logs/system-versions.txt


# Check if build essentials are installed
sudo apt install -y \
  build-essential \
  gcc \
  g++ \
  git \
  git-lfs \
  cmake \
  ninja-build \
  ccache \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv \
  pkg-config \
  libopenmpi-dev \
  openmpi-bin \
  libnuma-dev \
  patchelf

sudo apt install -y \
  build-essential \
  cmake \
  ninja-build \
  ccache \
  git \
  git-lfs \
  pkg-config \
  patchelf \
  python3-dev \
  python3-venv \
  libopenmpi-dev \
  openmpi-bin \
  libnuma-dev \
  libssl-dev \
  libffi-dev \
  zlib1g-dev

sudo apt install -y libucx0 libucx-dev ucx-utils

sudo apt install -y \
  libnccl2=2.30.7-1+cuda13.3 \
  libnccl-dev=2.30.7-1+cuda13.3

sudo ldconfig

git lfs install

# Set up Build venv
python3 -m venv ~/ai/venv/tensorrt-llm

# Activate Build venv
source ~/ai/venv/tensorrt-llm/bin/activate

# Set CUDA paths for venv
cat >> ~/ai/venv/tensorrt-llm/bin/activate <<'EOF'
export CUDA_HOME=/usr/local/cuda
export CUDACXX="$CUDA_HOME/bin/nvcc"
export PATH="$CUDA_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$CUDA_HOME/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export HF_HOME="$HOME/ai/cache/huggingface"
export TRANSFORMERS_CACHE="$HF_HOME"
export CCACHE_DIR="$HOME/ai/cache/ccache"
EOF

# Reload the venv
deactivate
source ~/ai/venv/tensorrt-llm/bin/activate

# Clone TensorRT-LLM
cd ~/ai/src
git clone https://github.com/NVIDIA/TensorRT-LLM.git
cd ~/ai/src/TensorRT-LLM
git submodule update --init --recursive
git lfs pull

# Don't build on main check for last release
git fetch --tags
git tag --sort=-version:refname | head -20
git describe --tags --always
>> v1.3.0rc21-263-ga8b540912c
git checkout v1.3.0rc21-263-ga8b540912c
git submodule update --init --recursive
git lfs pull

# Install TensorRT
python -m pip install --extra-index-url https://pypi.nvidia.com tensorrt==11.1.0.106

# Check TensorRT install
python - <<'PY'
import tensorrt as trt
print("TensorRT:", trt.__version__)
PY
>>TensorRT: 11.1.0.106

# Get recommended PyTorch version
grep -R \
  -E '"torch|torch[<>=~!]' \
  pyproject.toml \
  setup.py \
  setup.cfg \
  requirements* \
  2>/dev/null | head -100
>>requirements.txt:torch>=2.11.0,<=2.13.0a0

# pinpoint Repo state
git status
git rev-parse HEAD
git submodule status
git rev-parse HEAD > ~/ai/logs/tensorrt-llm-build-commit.txt
git submodule status > ~/ai/logs/tensorrt-llm-build-submodules.txt

# check which PyTorch pip would like to install
python -m pip install --dry-run -r requirements.txt 2>&1 | tee ~/ai/logs/requirements-dry-run.log
grep -Ei 'torch|cuda|nvidia-' ~/ai/logs/requirements-dry-run.log

# Install requierements
python -m pip install -r requirements.txt 2>&1 | tee ~/ai/logs/requirements-install.log

# Check PyTorch install
python - <<'PY'
import sys
import torch

print("Python:", sys.version)
print("PyTorch:", torch.__version__)
print("PyTorch CUDA Runtime:", torch.version.cuda)
print("CUDA verfügbar:", torch.cuda.is_available())
print("CXX11 ABI:", torch.compiled_with_cxx11_abi())

if not torch.cuda.is_available():
    raise SystemExit("FEHLER: PyTorch erkennt die GPU nicht.")

print("GPU:", torch.cuda.get_device_name(0))
print("Compute Capability:", torch.cuda.get_device_capability(0))
print("CUDA-Geräte:", torch.cuda.device_count())

x = torch.randn(4096, 4096, device="cuda", dtype=torch.float16)
y = x @ x
torch.cuda.synchronize()

print("GPU-Matrixtest:", y.shape)
print("GPU-Matrixtest erfolgreich")
PY

python - <<'PY' > ~/ai/logs/pytorch-abi.txt
import torch
print(int(torch.compiled_with_cxx11_abi()))
PY

python -m pip freeze > ~/ai/logs/python-packages-before-build.txt

# Configure ccache
mkdir -p ~/ai/cache/ccache
export CCACHE_DIR="$HOME/ai/cache/ccache"
export CCACHE_MAXSIZE=50G
ccache --set-config=max_size=50G
ccache --set-config=compression=true
ccache --zero-stats

# Start the source build
python scripts/build_wheel.py --clean --build_type Release --use_ccache --cuda_architectures "120-real" --extra-cmake-vars "ENABLE_UCX=OFF" -j 24 2>&1 | tee ~/ai/logs/tensorrt-llm-build.log

### Various patches!!! to be documented


### After Build actions ###

# find and document build artefacts
find . -type f \( -name 'tensorrt_llm-*.whl' -o -name '*.so' \) -printf '%TY-%Tm-%Td %TH:%TM  %p\n' | sort

find ~/ai/src/TensorRT-LLM -type f -name 'tensorrt_llm-*.whl' -printf '%p\n'


TRTLLM_WHEEL="$(
  find ~/ai/src/TensorRT-LLM \
    -type f \
    -name 'tensorrt_llm-*.whl' \
    -printf '%T@ %p\n' \
  | sort -nr \
  | head -1 \
  | cut -d' ' -f2-
)"

printf 'Wheel: %s\n' "$TRTLLM_WHEEL"
test -f "$TRTLLM_WHEEL"

# save metadata
mkdir -p ~/ai/artifacts/tensorrt-llm
cp -av "$TRTLLM_WHEEL" ~/ai/artifacts/tensorrt-llm/
sha256sum "$TRTLLM_WHEEL" | tee ~/ai/artifacts/tensorrt-llm/SHA256SUMS

# document repository state
cd ~/ai/src/TensorRT-LLM
git rev-parse HEAD | tee ~/ai/artifacts/tensorrt-llm/COMMIT
git status --short | tee ~/ai/artifacts/tensorrt-llm/GIT_STATUS.txt
git diff > ~/ai/artifacts/tensorrt-llm/local-build-fixes.patch

# document current Python state
python --version
python -m pip --version
python -m pip freeze > ~/ai/artifacts/tensorrt-llm/requirements-before-wheel.txt

python - <<'PY'
import sys

print("Python executable:", sys.executable)
print("Python version:", sys.version)
PY


# Built Wheel test install without dependencies (--no-deps)
python -m pip install --no-deps --force-reinstall "$TRTLLM_WHEEL"
python -m pip show tensorrt-llm
python -m pip freeze > ~/ai/artifacts/tensorrt-llm/requirements-after-wheel.txt


# Check dependency konsistenz
python -m pip check

python - <<'PY'
from importlib.metadata import PackageNotFoundError, version

for package in ("tensorrt-llm", "nvidia-modelopt", "torch", "tensorrt"):
    try:
        print(f"{package}: {version(package)}")
    except PackageNotFoundError:
        print(f"{package}: nicht installiert")
PY


# Import TensorRT-LLM
python - <<'PY'
import sys
import tensorrt_llm

print("TensorRT-LLM import successful")
print("Python:", sys.version)
print("TensorRT-LLM module:", tensorrt_llm.__file__)
print("TensorRT-LLM version:", getattr(tensorrt_llm, "__version__", "unknown"))
PY

# Check Torch CUDA Blackwell
python - <<'PY'
import torch

print("Torch:", torch.__version__)
print("Torch CUDA:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())
print("GPU count:", torch.cuda.device_count())

if torch.cuda.is_available():
    index = torch.cuda.current_device()
    properties = torch.cuda.get_device_properties(index)

    print("Current device:", index)
    print("GPU:", properties.name)
    print("Compute capability:", f"{properties.major}.{properties.minor}")
    print("VRAM GiB:", round(properties.total_memory / 1024**3, 2))
PY

python - <<'PY'
import torch

assert torch.cuda.is_available(), "CUDA ist nicht verfügbar"

a = torch.randn((4096, 4096), device="cuda", dtype=torch.float16)
b = torch.randn((4096, 4096), device="cuda", dtype=torch.float16)

torch.cuda.synchronize()
c = a @ b
torch.cuda.synchronize()

print("CUDA matrix multiplication successful")
print("Shape:", tuple(c.shape))
print("Device:", c.device)
print("Dtype:", c.dtype)
print("Finite:", bool(torch.isfinite(c).all()))
PY

# Check TensorRT Python bindings
python - <<'PY'
import tensorrt as trt

print("TensorRT:", trt.__version__)
print("TensorRT module:", trt.__file__)

logger = trt.Logger(trt.Logger.WARNING)
builder = trt.Builder(logger)

print("TensorRT Builder created:", builder is not None)
PY

# Check native TensorRT-LLM libraries
TRTLLM_PACKAGE_DIR="$(
  python - <<'PY'
from pathlib import Path
import tensorrt_llm

print(Path(tensorrt_llm.__file__).resolve().parent)
PY
)"

echo "$TRTLLM_PACKAGE_DIR"

find "$TRTLLM_PACKAGE_DIR" -type f -name '*.so' -print

while IFS= read -r library; do
  echo
  echo "===== $library ====="
  ldd "$library" | grep 'not found' || true
done < <(
  find "$TRTLLM_PACKAGE_DIR" \
    -type f \
    -name '*.so'
)

find "$TRTLLM_PACKAGE_DIR" -type f -name '*.so' -exec ldd {} \; | grep 'not found'


# Check TensorRT-LLM-CLI
command -v trtllm-build || true
command -v trtllm-serve || true
command -v trtllm-bench || true

trtllm-build --help | head -40
trtllm-serve --help | head -60
trtllm-bench --help | head -60


# Create persistant TensorRT-LLM import test script
mkdir -p ~/ai/scripts

cat > ~/ai/scripts/validate_trtllm.py <<'PY'
#!/usr/bin/env python3

from __future__ import annotations

import sys
from importlib.metadata import PackageNotFoundError, version

import torch
import tensorrt as trt
import tensorrt_llm


def package_version(name: str) -> str:
    try:
        return version(name)
    except PackageNotFoundError:
        return "not installed"


def main() -> int:
    print("=== Python ===")
    print("Executable:", sys.executable)
    print("Version:", sys.version.replace("\n", " "))

    print("\n=== Packages ===")
    for package in (
        "tensorrt-llm",
        "tensorrt",
        "torch",
        "nvidia-modelopt",
    ):
        print(f"{package}: {package_version(package)}")

    print("\n=== Modules ===")
    print("TensorRT-LLM:", tensorrt_llm.__file__)
    print("TensorRT:", trt.__file__)
    print("Torch:", torch.__file__)

    print("\n=== CUDA ===")
    print("Torch CUDA:", torch.version.cuda)
    print("CUDA available:", torch.cuda.is_available())

    if not torch.cuda.is_available():
        print("ERROR: CUDA is unavailable")
        return 1

    device = torch.cuda.current_device()
    properties = torch.cuda.get_device_properties(device)

    print("Device index:", device)
    print("Device name:", properties.name)
    print(
        "Compute capability:",
        f"{properties.major}.{properties.minor}",
    )
    print(
        "VRAM:",
        f"{properties.total_memory / 1024**3:.2f} GiB",
    )

    if (properties.major, properties.minor) != (12, 0):
        print("WARNING: Expected compute capability 12.0")

    print("\n=== CUDA calculation ===")
    left = torch.randn(
        (2048, 2048),
        device="cuda",
        dtype=torch.float16,
    )
    right = torch.randn(
        (2048, 2048),
        device="cuda",
        dtype=torch.float16,
    )

    result = left @ right
    torch.cuda.synchronize()

    if not torch.isfinite(result).all():
        print("ERROR: CUDA result contains invalid values")
        return 1

    print("CUDA calculation successful")
    print("\nTensorRT-LLM environment validation successful")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY

chmod +x ~/ai/scripts/validate_trtllm.py

source ~/ai/venv/tensorrt-llm/bin/activate
~/ai/scripts/validate_trtllm.py 2>&1 | tee ~/ai/artifacts/tensorrt-llm/validation.txt



# Save local patches
cd ~/ai/src/TensorRT-LLM
mkdir -p ~/ai/patches
git diff > ~/ai/patches/tensorrt-llm-local-build-fixes.patch

TORCH_LIST_HEADER="$HOME/ai/venv/tensorrt-llm/lib/python3.13/site-packages/torch/include/ATen/core/List_inl.h"
diff -u "${TORCH_LIST_HEADER}.bak" "$TORCH_LIST_HEADER" > ~/ai/patches/pytorch-list-inl-nvcc13.patch || true
ls -lh ~/ai/patches
cat ~/ai/patches/pytorch-list-inl-nvcc13.patch


# Create Build report
cat > ~/ai/artifacts/tensorrt-llm/BUILD_INFO.txt <<EOF
TensorRT-LLM native build
=========================

Date:
$(date --iso-8601=seconds)

Repository:
$(realpath ~/ai/src/TensorRT-LLM)

Commit:
$(git -C ~/ai/src/TensorRT-LLM rev-parse HEAD)

Git status:
$(git -C ~/ai/src/TensorRT-LLM status --short)

Python:
$(python --version 2>&1)

Python executable:
$(which python)

CUDA compiler:
$(nvcc --version | tail -1)

NVIDIA driver:
$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)

GPU:
$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)

Wheel:
$TRTLLM_WHEEL

Wheel SHA256:
$(sha256sum "$TRTLLM_WHEEL")

Build options:
CMAKE_BUILD_TYPE=Release
CMAKE_CUDA_ARCHITECTURES=120-real
ENABLE_UCX=OFF
NVTX_DISABLE=ON
BUILD_PYT=ON
BUILD_DEEP_EP=ON
BUILD_DEEP_GEMM=ON
BUILD_FLASH_MLA=ON
EOF

cat ~/ai/artifacts/tensorrt-llm/BUILD_INFO.txt


# LAst checks
python -m pip check

# Fix missing dependencies
python -m pip install --upgrade-strategy only-if-needed jupyter-server mistune notebook

python -m pip install --upgrade --force-reinstall --no-deps "torchao>=0.14,<0.16" --index-url https://download.pytorch.org/whl/cu130


### TinyLlama-1.1B as working test

# activate and check venv
source ~/ai/venv/tensorrt-llm/bin/activate
cd /tmp
python -m pip check
command -v trtllm-serve
command -v trtllm-build
command -v trtllm-bench

# set HF cache
mkdir -p ~/ai/models/huggingface
export HF_HOME=~/ai/models/huggingface
export HUGGINGFACE_HUB_CACHE="$HF_HOME/hub"
cat >> ~/.bashrc <<'EOF'
export HF_HOME="$HOME/ai/models/huggingface"
export HUGGINGFACE_HUB_CACHE="$HF_HOME/hub"
EOF


# check if Python api is present
python - <<'PY'
from tensorrt_llm import LLM, SamplingParams

print("LLM API import successful")
print("LLM:", LLM)
print("SamplingParams:", SamplingParams)
PY

# create tests
mkdir -p ~/ai/scripts

cat > ~/ai/scripts/test_tinyllama.py <<'PY'
#!/usr/bin/env python3

from __future__ import annotations

import gc
import sys

import torch
from tensorrt_llm import LLM, SamplingParams


MODEL_NAME = "TinyLlama/TinyLlama-1.1B-Chat-v1.0"


def main() -> int:
    if not torch.cuda.is_available():
        print("ERROR: CUDA is not available", file=sys.stderr)
        return 1

    print("=== Environment ===")
    print("Torch:", torch.__version__)
    print("CUDA runtime:", torch.version.cuda)
    print("GPU:", torch.cuda.get_device_name(0))
    print("Compute capability:", torch.cuda.get_device_capability(0))
    print("TensorRT-LLM model:", MODEL_NAME)

    prompts = [
        "Explain in two sentences what TensorRT-LLM does.",
        "Write a short greeting from a server in Bonn.",
    ]

    sampling_params = SamplingParams(
        temperature=0.7,
        top_p=0.9,
        max_tokens=96,
    )

    llm = None

    try:
        print("\n=== Loading model ===")
        llm = LLM(
            model=MODEL_NAME,
        )

        print("\n=== Generating ===")
        outputs = llm.generate(
            prompts,
            sampling_params,
        )

        print("\n=== Results ===")

        for index, output in enumerate(outputs, start=1):
            print(f"\n--- Prompt {index} ---")
            print(output.prompt)

            for candidate_index, candidate in enumerate(
                output.outputs,
                start=1,
            ):
                print(f"\n--- Output {index}.{candidate_index} ---")
                print(candidate.text)

        return 0

    finally:
        if llm is not None:
            del llm

        gc.collect()

        if torch.cuda.is_available():
            torch.cuda.empty_cache()


if __name__ == "__main__":
    raise SystemExit(main())
PY

chmod +x ~/ai/scripts/test_tinyllama.py

~/ai/scripts/test_tinyllama.py 2>&1 | tee ~/ai/logs/tinyllama-first-run.log

# Download model
python -m pip install --upgrade-strategy only-if-needed huggingface-hub
mkdir -p ~/ai/models/TinyLlama-1.1B-Chat-v1.0
hf download TinyLlama/TinyLlama-1.1B-Chat-v1.0 --local-dir ~/ai/models/TinyLlama-1.1B-Chat-v1.0


# persistant start script
cat > ~/ai/scripts/start-trtllm-tinyllama.sh <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

source "$HOME/ai/venv/tensorrt-llm/bin/activate"

mkdir -p "$HOME/ai/logs"
mkdir -p "$HOME/ai/models/huggingface"

export HF_HOME="$HOME/ai/models/huggingface"
export HUGGINGFACE_HUB_CACHE="$HF_HOME/hub"

# Open MPI 5.0.7 workaround:
# Restrict TCP BTL to loopback on this single-node server.
export OMPI_MCA_pml=ob1
export OMPI_MCA_btl=self,sm,tcp
export OMPI_MCA_btl_tcp_if_include=lo

echo "Open MPI: $(ompi_info --version | head -1)"
echo "MPI transports: $OMPI_MCA_btl"
echo "MPI TCP interface: $OMPI_MCA_btl_tcp_if_include"

exec trtllm-serve \
  TinyLlama/TinyLlama-1.1B-Chat-v1.0 \
  --host 127.0.0.1 \
  --port 8000
EOF

chmod +x ~/ai/scripts/start-trtllm-tinyllama.sh

~/ai/scripts/start-trtllm-tinyllama.sh 2>&1 | tee ~/ai/logs/trtllm-serve-tinyllama.log











