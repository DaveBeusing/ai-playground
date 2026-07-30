TensorRT-LLM runs on Python 3.13, Open WebUI recommends Python 3.11

```
cd ~
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.local/bin/env
uv --version
```


create WebUI venv
```
mkdir -p ~/ai/services/open-webui
mkdir -p ~/ai/data/open-webui
mkdir -p ~/ai/logs
```

run the service
```
DATA_DIR="$HOME/ai/services/open-webui" \
HOST=0.0.0.0 \
PORT=8080 \
OPENAI_API_BASE_URL="http://127.0.0.1:8000/v1" \
OPENAI_API_KEY="tensorrt_llm" \
uvx --python 3.11 open-webui@latest serve
```



















































