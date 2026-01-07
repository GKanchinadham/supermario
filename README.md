# 🍄 Super Mario Task Tracker

A fun, Mario-themed task tracker built with Python Flask and containerized with Docker.

![Python](https://img.shields.io/badge/Python-3.12-blue)
![Flask](https://img.shields.io/badge/Flask-3.0-green)
![Docker](https://img.shields.io/badge/Docker-Ready-blue)

## Features

- ✅ Create, complete, and delete tasks
- 🎮 Beautiful Mario-themed UI with animations
- 🐳 Fully dockerized for easy deployment
- 🏥 Health check endpoint included
- 🔒 Runs as non-root user in container

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Build and run the application
docker-compose up --build

# Run in detached mode
docker-compose up -d --build
```

The app will be available at: **http://localhost:5000**

### Using Docker Directly

```bash
# Build the image
docker build -t supermario-app .

# Run the container
docker run -p 5000:5000 supermario-app
```

### Development Mode

```bash
# Run with hot reload enabled
docker-compose --profile dev up supermario-dev
```

Development server runs at: **http://localhost:5001**

### Running Locally (Without Docker)

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the app
python app.py
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Main UI |
| GET | `/api/tasks` | Get all tasks |
| POST | `/api/tasks` | Create a new task |
| PUT | `/api/tasks/<id>` | Toggle task completion |
| DELETE | `/api/tasks/<id>` | Delete a task |
| GET | `/health` | Health check |

## Project Structure

```
supermario/
├── app.py              # Flask application
├── templates/
│   └── index.html      # Frontend UI
├── requirements.txt    # Python dependencies
├── Dockerfile          # Container configuration
├── docker-compose.yml  # Multi-container setup
├── .dockerignore       # Docker build exclusions
├── .env.example        # Environment template
└── README.md           # Documentation
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 5000 | Application port |
| FLASK_DEBUG | false | Enable debug mode |

## License

MIT License - Feel free to use and modify!

---

*Let's-a go! 🍄*



