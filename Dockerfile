FROM runpod/base:0.4.0-cuda11.8.0

# System dependencies
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY builder/requirements.txt /requirements.txt
COPY builder/requirements-late.txt /requirements-late.txt
RUN python3.11 -m pip install --upgrade pip
RUN python3.11 -m pip install --upgrade setuptools packaging wheel
RUN python3.11 -m pip install --upgrade -r /requirements.txt --no-cache-dir --no-build-isolation
RUN python3.11 -m pip install --upgrade -r /requirements-late.txt --no-cache-dir --no-build-isolation
RUN rm /requirements.txt


RUN CMAKE_ARGS="-DLLAMA_CUBLAS=on" python3.11 -m pip install llama-cpp-python 

ARG HF_TOKEN
ENV HF_TOKEN=${HF_TOKEN}
ARG BASE_MODEL=TheBloke/Mistral-7B-Instruct-v0.2-GPTQ
ENV BASE_MODEL=${BASE_MODEL}
ARG BASE_MODEL_REV=gptq-8bit-32g-actorder_True
ENV BASE_MODEL_REV=${BASE_MODEL_REV}
ARG ADAPTER_MODEL='lucaelin/llm-useful'
ENV ADAPTER_MODEL=${ADAPTER_MODEL}
ARG ADAPTER_MODEL_REV='28042ec'
ENV ADAPTER_MODEL_REV=${ADAPTER_MODEL_REV}

# model local copy
#COPY ./model.gguf ./model.gguf

# model direct download
#ENV MODEL_DOWNLOAD_URL=https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v0.3-GGUF/resolve/main/tinyllama-1.1b-chat-v0.3.Q8_0.gguf?download=true
#RUN wget -O model.gguf $MODEL_DOWNLOAD_URL

# model git download
#ENV MODEL_REPO=https://huggingface.co/TheBloke/TinyLlama-1.1B-intermediate-step-715k-1.5T-GGUF
#ENV MODEL_FILE=tinyllama-1.1b-intermediate-step-715k-1.5t.Q4_K_M.gguf

#RUN git lfs install
#RUN git archive --remote=$MODEL_REPO HEAD ${MODEL_FILE} | tar xO
#RUN mv ${MODEL_FILE} model.gguf
#RUN git archive --remote=$MODEL_REPO HEAD config.json | tar xO

#RUN git clone $MODEL_REPO model_repo
#RUN cp model_repo/${MODEL_FILE} ./model.gguf
#RUN cp model_repo/config.json ./config.json
#RUN rm -rf model_repo

# model huggingface download
RUN huggingface-cli login --token ${HF_TOKEN}
RUN huggingface-cli download --revision ${BASE_MODEL_REV} ${BASE_MODEL}
#RUN huggingface-cli download --revision ${ADAPTER_REV} ${ADAPTER_MODEL}

# serverless handler
ADD src .

CMD python3.11 -u /handlerHF.py
