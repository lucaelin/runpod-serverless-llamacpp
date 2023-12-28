FROM ghcr.io/ggerganov/llama.cpp:full-cuda as llama
#FROM ghcr.io/ggerganov/llama.cpp:full as llama

FROM runpod/base:0.4.0-cuda11.8.0

# System dependencies
COPY builder/setup.sh /setup.sh
RUN /bin/bash /setup.sh && \
    rm /setup.sh

# Python dependencies
COPY builder/requirements.txt /requirements.txt
RUN python3.11 -m pip install --upgrade pip && \
    python3.11 -m pip install --upgrade -r /requirements.txt --no-cache-dir && \
    rm /requirements.txt

# llama server
COPY --from=llama /app/server ./llama

# model local copy
COPY ./model.gguf ./model.gguf

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

# serverless handler
ADD src .

CMD python3.11 -u /handler.py
