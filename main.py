import os
import json
import hashlib
from flask import Flask, render_template, request, jsonify, redirect, url_for
import cloudinary
import cloudinary.uploader

app = Flask(__name__)

CLOUD_NAME = os.environ.get("CLOUDINARY_CLOUD_NAME", "kjt9ntgh")
API_KEY = os.environ.get("CLOUDINARY_API_KEY", "326313483419766")
API_SECRET = os.environ.get("CLOUDINARY_API_SECRET", "Wpf3m1CGVItwZPQVyn-0AaGEl10")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "809047")

cloudinary.config(
    cloud_name=CLOUD_NAME,
    api_key=API_KEY,
    api_secret=API_SECRET,
    secure=True
)

DATA_FILE = 'data.json'

def load_data():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r') as f:
            return json.load(f)
    return {"images": [], "bg_image": None}

def save_data(data):
    with open(DATA_FILE, 'w') as f:
        json.dump(data, f, indent=4)

def calculate_hash(file_bytes):
    return hashlib.md5(file_bytes).hexdigest()

@app.route('/')
def index():
    data = load_data()
    page = int(request.args.get('page', 1))
    per_page = 25

    images = data.get("images", [])
    total_images = len(images)
    total_pages = (total_images + per_page - 1) // per_page if total_images > 0 else 1

    start = (page - 1) * per_page
    end = start + per_page
    paginated_images = images[start:end]

    return render_template('index.html', 
                           images=paginated_images, 
                           all_images=images,
                           page=page, 
                           total_pages=total_pages,
                           bg_image=data.get("bg_image"))

@app.route('/api/upload', methods=['POST'])
def upload():
    password = request.form.get('password')
    if password != ADMIN_PASSWORD:
        return jsonify({"success": False, "message": "Incorrect Admin Password!"}), 401

    name = request.form.get('name', 'Untitled').strip()
    is_bg = request.form.get('is_bg', 'false') == 'true'
    file = request.files.get('file')

    if not file:
        return jsonify({"success": False, "message": "No image selected!"}), 400

    file_bytes = file.read()
    file_hash = calculate_hash(file_bytes)

    data = load_data()

    for img in data["images"]:
        if img.get("hash") == file_hash:
            return jsonify({"success": False, "message": "Duplicate image! Ye photo pehle se uploaded hai."}), 400

    file.seek(0)

    try:
        response = cloudinary.uploader.upload(
            file,
            folder="profile_viewer_gallery",
            resource_type="image"
        )

        img_url = response.get('secure_url')

        if is_bg:
            data["bg_image"] = img_url
            save_data(data)
            return jsonify({"success": True, "message": "Background image updated successfully!", "url": img_url})
        else:
            new_entry = {
                "id": response.get('public_id'),
                "name": name,
                "url": img_url,
                "hash": file_hash
            }
            data["images"].insert(0, new_entry)
            save_data(data)
            return jsonify({"success": True, "message": "Photo uploaded successfully!", "data": new_entry})

    except Exception as e:
        return jsonify({"success": False, "message": f"Upload error: {str(e)}"}), 500

@app.route('/api/remove_bg', methods=['POST'])
def remove_bg():
    password = request.form.get('password')
    if password != ADMIN_PASSWORD:
        return jsonify({"success": False, "message": "Incorrect Password!"}), 401

    data = load_data()
    data["bg_image"] = None
    save_data(data)
    return jsonify({"success": True, "message": "Background image removed!"})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
