echo "===== BETRIEBSSYSTEM ====="
cat /etc/os-release
echo
uname -a
echo
dpkg --print-architecture

echo
echo "===== CPU UND RAM ====="
lscpu | grep -E \
  'Model name|Architecture|CPU\(s\)|Thread|Core|Socket|Vendor'
free -h
nproc

echo
echo "===== GPU ====="
nvidia-smi
echo
nvidia-smi --query-gpu=index,name,uuid,driver_version,memory.total \
  --format=csv,noheader
echo
nvidia-smi -q | grep -E \
  'Product Name|CUDA Version|VBIOS Version|GSP Firmware Version'

echo
echo "===== CUDA TOOLKIT ====="
command -v nvcc || true
nvcc --version 2>/dev/null || true
readlink -f /usr/local/cuda 2>/dev/null || true
ls -ld /usr/local/cuda* 2>/dev/null || true

echo
echo "===== CUDA LIBRARIES ====="
ldconfig -p | grep -E \
  'libcuda\.so|libcudart\.so|libcublas\.so|libnvrtc\.so' \
  | head -30

echo
echo "===== COMPILER ====="
gcc --version | head -1
g++ --version | head -1
ld --version | head -1

echo
echo "===== BUILD-WERKZEUGE ====="
cmake --version 2>/dev/null | head -1 || true
ninja --version 2>/dev/null || true
make --version 2>/dev/null | head -1 || true
git --version 2>/dev/null || true
git-lfs version 2>/dev/null || true

echo
echo "===== PYTHON ====="
python3 --version
python3 -m pip --version 2>/dev/null || true

echo
echo "===== TENSORRT ====="
dpkg -l | grep -E \
  'tensorrt|libnvinfer|libnvonnxparsers|libnvinfer-plugin' \
  || true

command -v trtexec || true
trtexec --version 2>/dev/null || true

python3 - <<'PY'
try:
    import tensorrt as trt
    print("TensorRT Python:", trt.__version__)
except Exception as exc:
    print("TensorRT Python: nicht installiert")
    print("Hinweis:", exc)
PY

echo
echo "===== PYTORCH ====="
python3 - <<'PY'
try:
    import torch
    print("PyTorch:", torch.__version__)
    print("PyTorch CUDA:", torch.version.cuda)
    print("CXX11 ABI:", torch.compiled_with_cxx11_abi())
    print("CUDA verfügbar:", torch.cuda.is_available())
    if torch.cuda.is_available():
        print("GPU:", torch.cuda.get_device_name(0))
        print("Compute Capability:", torch.cuda.get_device_capability(0))
except Exception as exc:
    print("PyTorch: nicht installiert")
    print("Hinweis:", exc)
PY