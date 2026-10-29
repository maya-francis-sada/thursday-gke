import os
import pymysql
from flask import Flask, request, render_template_string

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST")
DB_USER = os.environ.get("DB_USER", "thursday_user")
DB_PASS = os.environ.get("DB_PASS")
DB_NAME = os.environ.get("DB_NAME", "thursday_db")

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
        connect_timeout=5
    )

# Health check endpoints for GKE Internal Load Balancer
@app.route("/")
@app.route("/healthz")
def health():
    return "OK", 200

@app.route("/thursday", methods=["GET", "POST"])
def thursday():
    name_to_write = request.args.get("name", "Maya")
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS entries (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(100) NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            cursor.execute("INSERT INTO entries (name) VALUES (%s);", (name_to_write,))
            conn.commit()

            cursor.execute("SELECT id, name, created_at FROM entries ORDER BY id DESC LIMIT 20;")
            rows = cursor.fetchall()
        conn.close()

        html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Thursday Cloud SQL App</title>
            <style>
                body { font-family: sans-serif; margin: 40px; background: #f8fafc; color: #0f172a; }
                .card { background: white; padding: 24px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); max-width: 600px; }
                table { width: 100%; border-collapse: collapse; margin-top: 16px; }
                th, td { text-align: left; padding: 8px; border-bottom: 1px solid #e2e8f0; }
                .badge { background: #dcfce7; color: #166534; padding: 4px 8px; border-radius: 4px; font-weight: bold; }
            </style>
        </head>
        <body>
            <div class="card">
                <h2>🚀 Thursday App — Connected to Cloud SQL!</h2>
                <p><span class="badge">Success</span> Wrote <b>{{ name }}</b> to Cloud SQL (<code>{{ db_host }}</code>)</p>
                <h3>Recent Database Entries:</h3>
                <table>
                    <tr><th>ID</th><th>Name</th><th>Timestamp (UTC)</th></tr>
                    {% for row in rows %}
                    <tr><td>{{ row.id }}</td><td>{{ row.name }}</td><td>{{ row.created_at }}</td></tr>
                    {% endfor %}
                </table>
            </div>
        </body>
        </html>
        """
        return render_template_string(html, name=name_to_write, db_host=DB_HOST, rows=rows), 200
    except Exception as e:
        return f"Database connection error: {str(e)}", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)