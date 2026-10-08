FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    WORKERS=4

EXPOSE 8080

USER 1000

# Shell form (with exec, so uvicorn stays PID 1 and receives signals directly)
# is required here so ${WORKERS} is substituted at container start.
CMD exec uvicorn main:app --host 0.0.0.0 --port 8080 --workers ${WORKERS}
