"""
Super Mario Task Tracker - A fun Flask application
"""
from flask import Flask, render_template, request, jsonify
from datetime import datetime
import os

app = Flask(__name__)

# In-memory storage for tasks (in production, use a database)
tasks = [
    {"id": 1, "title": "Collect 100 coins", "completed": False, "created_at": "2026-01-04"},
    {"id": 2, "title": "Save Princess Peach", "completed": False, "created_at": "2026-01-04"},
    {"id": 3, "title": "Defeat Bowser", "completed": False, "created_at": "2026-01-04"},
]
task_counter = 3


@app.route("/")
def index():
    """Render the main page"""
    return render_template("index.html")


@app.route("/api/tasks", methods=["GET"])
def get_tasks():
    """Get all tasks"""
    return jsonify(tasks)


@app.route("/api/tasks", methods=["POST"])
def create_task():
    """Create a new task"""
    global task_counter
    data = request.get_json()
    
    if not data or not data.get("title"):
        return jsonify({"error": "Title is required"}), 400
    
    task_counter += 1
    new_task = {
        "id": task_counter,
        "title": data["title"],
        "completed": False,
        "created_at": datetime.now().strftime("%Y-%m-%d")
    }
    tasks.append(new_task)
    return jsonify(new_task), 201


@app.route("/api/tasks/<int:task_id>", methods=["PUT"])
def update_task(task_id):
    """Toggle task completion status"""
    for task in tasks:
        if task["id"] == task_id:
            task["completed"] = not task["completed"]
            return jsonify(task)
    return jsonify({"error": "Task not found"}), 404


@app.route("/api/tasks/<int:task_id>", methods=["DELETE"])
def delete_task(task_id):
    """Delete a task"""
    global tasks
    tasks = [t for t in tasks if t["id"] != task_id]
    return jsonify({"message": "Task deleted"}), 200


@app.route("/health")
def health():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "supermario-app"})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    debug = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
    app.run(host="0.0.0.0", port=port, debug=debug)



