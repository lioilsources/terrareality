FROM python:3.14-slim
WORKDIR /app
COPY pyproject.toml ./
COPY vision ./vision
RUN pip install --no-cache-dir .
USER nobody
EXPOSE 8001
CMD ["uvicorn", "vision.main:app", "--host", "0.0.0.0", "--port", "8001"]
