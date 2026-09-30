#!/bin/bash
echo "🚀 Setting up your Ultra-Smooth Profile Viewer & Gallery Website..."

# Dependencies Install
pkg update -y && pkg install python git -y
pip install flask cloudinary requests hashlib-python Pillow

# Project Structure
mkdir -p templates static/css static/js uploads

# 1. requirements.txt
cat << 'REQ' > requirements.txt
Flask==3.0.2
cloudinary==1.38.0
requests==2.31.0
Pillow==10.2.0
gunicorn==21.2.0
REQ

# 2. .env Configuration
cat << 'ENV' > .env
CLOUDINARY_CLOUD_NAME=kjt9ntgh
CLOUDINARY_API_KEY=326313483419766
CLOUDINARY_API_SECRET=Wpf3m1CGVItwZPQVyn-0AaGEl10
ADMIN_PASSWORD=809047
ENV

# 3. main.py (Flask Backend)
cat << 'PY' > main.py
import os
import json
import hashlib
from flask import Flask, render_template, request, jsonify, redirect, url_for, send_file
import cloudinary
import cloudinary.uploader
import cloudinary.api

app = Flask(__name__)

# Cloudinary Config
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
    
    # Check duplicate hash
    for img in data["images"]:
        if img.get("hash") == file_hash:
            return jsonify({"success": False, "message": "Duplicate image! Ye photo pehle se uploaded hai."}), 400

    file.seek(0)
    
    try:
        # Direct Cloudinary Upload
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
    app.run(host='0.0.0.0', port=port, debug=True)
PY

# 4. templates/index.html (Ultra Smooth Mobile UI & Features)
cat << 'HTML' > templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Profile Viewer & Cloud Gallery</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Poppins', sans-serif; -webkit-tap-highlight-color: transparent; }
        body {
            background: #090d16;
            color: #e6edf3;
            min-height: 100vh;
            padding-bottom: 30px;
            overflow-x: hidden;
            background-size: cover;
            background-position: center;
            background-attachment: fixed;
            transition: background 0.5s ease-in-out;
        }
        
        .overlay {
            background: rgba(9, 13, 22, 0.88);
            backdrop-filter: blur(8px);
            min-height: 100vh;
            padding: 15px 12px;
        }

        /* Top Bar & Search */
        .header {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 20px;
            position: sticky;
            top: 10px;
            z-index: 100;
        }

        .search-container {
            flex: 1;
            position: relative;
        }

        .search-container input {
            width: 100%;
            padding: 12px 15px 12px 42px;
            background: rgba(22, 27, 34, 0.85);
            border: 1px solid rgba(255, 255, 255, 0.15);
            border-radius: 25px;
            color: #fff;
            font-size: 14px;
            outline: none;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
            transition: all 0.3s ease;
        }

        .search-container input:focus {
            border-color: #58a6ff;
            box-shadow: 0 0 15px rgba(88, 166, 255, 0.4);
        }

        .search-container i {
            position: absolute;
            left: 15px;
            top: 50%;
            transform: translateY(-50%);
            color: #8b949e;
        }

        .admin-btn {
            width: 45px;
            height: 45px;
            border-radius: 50%;
            background: linear-gradient(135deg, #238636, #2ea043);
            border: 2px solid rgba(255, 255, 255, 0.2);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            box-shadow: 0 4px 15px rgba(35, 134, 54, 0.4);
            transition: transform 0.2s active, box-shadow 0.2s;
        }

        .admin-btn:active { transform: scale(0.92); }

        /* Profile Header Card */
        .profile-card {
            background: rgba(22, 27, 34, 0.75);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 16px;
            padding: 18px;
            text-align: center;
            margin-bottom: 22px;
            backdrop-filter: blur(12px);
            box-shadow: 0 10px 30px rgba(0,0,0,0.4);
            animation: fadeInDown 0.6s ease;
        }

        .profile-avatar {
            width: 85px;
            height: 85px;
            border-radius: 50%;
            margin: 0 auto 12px;
            border: 3px solid #58a6ff;
            box-shadow: 0 0 20px rgba(88, 166, 255, 0.5);
            object-fit: cover;
        }

        .profile-card h2 { font-size: 20px; font-weight: 600; color: #fff; }
        .profile-card p { font-size: 13px; color: #8b949e; }

        /* 2 Column Image Grid */
        .gallery-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 12px;
            margin-bottom: 25px;
        }

        .image-card {
            background: rgba(22, 27, 34, 0.8);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 14px;
            overflow: hidden;
            backdrop-filter: blur(10px);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            animation: fadeInUp 0.5s ease;
            cursor: pointer;
            position: relative;
        }

        .image-card:active { transform: scale(0.96); }

        .image-card img {
            width: 100%;
            height: 155px;
            object-fit: cover;
            display: block;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
        }

        .image-card .info {
            padding: 10px 8px;
            text-align: center;
        }

        .image-card .name {
            font-size: 13px;
            font-weight: 500;
            color: #f0f6fc;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        /* Pagination */
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 8px;
            margin-top: 15px;
        }

        .page-btn {
            padding: 8px 14px;
            background: rgba(22, 27, 34, 0.8);
            border: 1px solid rgba(255, 255, 255, 0.15);
            border-radius: 8px;
            color: #58a6ff;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            transition: 0.2s;
        }

        .page-btn.active {
            background: #238636;
            color: white;
            border-color: #2e9e43;
        }

        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0, 0, 0, 0.85);
            backdrop-filter: blur(12px);
            z-index: 1000;
            align-items: center;
            justify-content: center;
            padding: 20px;
            animation: fadeIn 0.3s ease;
        }

        .modal-content {
            background: #161b22;
            border: 1px solid rgba(255, 255, 255, 0.15);
            border-radius: 20px;
            width: 100%;
            max-width: 420px;
            padding: 22px;
            position: relative;
            box-shadow: 0 15px 40px rgba(0,0,0,0.6);
        }

        .close-btn {
            position: absolute;
            top: 15px; right: 18px;
            font-size: 20px;
            color: #8b949e;
            cursor: pointer;
        }

        .modal h3 { margin-bottom: 15px; color: #58a6ff; font-size: 18px; }

        .input-group {
            margin-bottom: 14px;
        }

        .input-group label {
            display: block;
            font-size: 12px;
            color: #8b949e;
            margin-bottom: 5px;
        }

        .input-group input {
            width: 100%;
            padding: 10px 14px;
            background: #0d1117;
            border: 1px solid #30363d;
            border-radius: 8px;
            color: white;
            font-size: 14px;
            outline: none;
        }

        .submit-btn {
            width: 100%;
            padding: 12px;
            background: linear-gradient(135deg, #238636, #2ea043);
            border: none;
            border-radius: 10px;
            color: white;
            font-weight: 600;
            font-size: 14px;
            cursor: pointer;
            margin-top: 8px;
        }

        .green-bg-btn {
            background: #1f6feb !important;
            margin-top: 10px;
        }

        .red-remove-btn {
            background: #da3633 !important;
            margin-top: 8px;
        }

        /* Realtime Mediafire Upload Progress */
        .progress-bar-container {
            display: none;
            width: 100%;
            background: #0d1117;
            height: 12px;
            border-radius: 10px;
            overflow: hidden;
            margin-top: 15px;
            border: 1px solid #30363d;
        }

        .progress-bar {
            width: 0%;
            height: 100%;
            background: linear-gradient(90deg, #238636, #58a6ff);
            transition: width 0.3s ease;
        }

        /* Full Image View Modal */
        .preview-img {
            width: 100%;
            max-height: 350px;
            object-fit: contain;
            border-radius: 12px;
            margin-bottom: 15px;
        }

        .download-btn {
            display: block;
            width: 100%;
            text-align: center;
            background: #238636;
            color: white;
            padding: 12px;
            border-radius: 10px;
            text-decoration: none;
            font-weight: 600;
        }

        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes fadeInUp { from { opacity: 0; transform: translateY(15px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeInDown { from { opacity: 0; transform: translateY(-15px); } to { opacity: 1; transform: translateY(0); } }
    </style>
</head>
<body style="{% if bg_image %}background-image: url('{{ bg_image }}');{% endif %}">

<div class="overlay">
    <!-- Header with Search and Admin Button -->
    <div class="header">
        <div class="search-container">
            <i class="fa-solid fa-magnifying-glass"></i>
            <input type="text" id="searchInput" placeholder="Search photos..." onkeyup="searchPhotos()">
        </div>
        <div class="admin-btn" onclick="openAdminModal()">
            <i class="fa-solid fa-user-gear"></i>
        </div>
    </div>

    <!-- Profile Intro Card -->
    <div class="profile-card">
        <img src="https://res.cloudinary.com/kjt9ntgh/image/upload/v1/profile_viewer_gallery/default_avatar" onerror="this.src='https://ui-avatars.com/api/?name=Atif+Khan&background=58a6ff&color=fff&size=128'" class="profile-avatar" alt="Atif Khan">
        <h2>Atif Khan</h2>
        <p>@itsmeatifkhan809047-oss</p>
    </div>

    <!-- 2 Column Image Grid -->
    <div class="gallery-grid" id="galleryGrid">
        {% for img in images %}
        <div class="image-card" onclick="openPreview('{{ img.url }}', '{{ img.name }}')">
            <img src="{{ img.url }}" alt="{{ img.name }}" loading="lazy">
            <div class="info">
                <div class="name">{{ img.name }}</div>
            </div>
        </div>
        {% else %}
        <p style="grid-column: span 2; text-align: center; color: #8b949e; padding: 30px 0;">No photos uploaded yet!</p>
        {% endfor %}
    </div>

    <!-- Pagination -->
    {% if total_pages > 1 %}
    <div class="pagination">
        {% for p in range(1, total_pages + 1) %}
        <a href="/?page={{ p }}" class="page-btn {% if p == page %}active{% endif %}">{{ p }}</a>
        {% endfor %}
    </div>
    {% endif %}
</div>

<!-- Admin Modal -->
<div class="modal" id="adminModal">
    <div class="modal-content">
        <span class="close-btn" onclick="closeAdminModal()">&times;</span>
        <h3><i class="fa-solid fa-cloud-arrow-up"></i> Admin Upload Panel</h3>
        
        <form id="uploadForm" onsubmit="handleUpload(event)">
            <div class="input-group">
                <label>Photo Title / Name</label>
                <input type="text" id="imgName" placeholder="Enter image name..." required>
            </div>

            <div class="input-group">
                <label>Select Photo</label>
                <input type="file" id="imgFile" accept="image/*" required>
            </div>

            <div class="input-group">
                <label>Admin Password</label>
                <input type="password" id="adminPass" placeholder="Enter password" required>
            </div>

            <div class="progress-bar-container" id="progressContainer">
                <div class="progress-bar" id="progressBar"></div>
            </div>

            <button type="submit" class="submit-btn"><i class="fa-solid fa-upload"></i> Upload to Gallery</button>
            <button type="button" class="submit-btn green-bg-btn" onclick="handleBgUpload()"><i class="fa-solid fa-image"></i> Set as Website Background</button>
            <button type="button" class="submit-btn red-remove-btn" onclick="handleRemoveBg()"><i class="fa-solid fa-trash"></i> Remove Background Image</button>
        </form>
    </div>
</div>

<!-- Image Preview & Download Modal -->
<div class="modal" id="previewModal">
    <div class="modal-content" style="text-align: center;">
        <span class="close-btn" onclick="closePreviewModal()">&times;</span>
        <h3 id="previewTitle" style="margin-bottom: 12px; color: #fff;"></h3>
        <img id="previewImg" class="preview-img" src="" alt="Preview">
        <a id="downloadBtn" href="" download target="_blank" class="download-btn"><i class="fa-solid fa-download"></i> Download Image</a>
    </div>
</div>

<script>
    const allImagesData = {{ all_images | tojson }};

    function openAdminModal() { document.getElementById('adminModal').style.display = 'flex'; }
    function closeAdminModal() { document.getElementById('adminModal').style.display = 'none'; }
    function closePreviewModal() { document.getElementById('previewModal').style.display = 'none'; }

    function openPreview(url, name) {
        document.getElementById('previewTitle').innerText = name;
        document.getElementById('previewImg').src = url;
        document.getElementById('downloadBtn').href = url;
        document.getElementById('previewModal').style.display = 'flex';
    }

    // Fuzzy Search Algorithm (Matches partial/misspelled queries)
    function searchPhotos() {
        const query = document.getElementById('searchInput').value.toLowerCase().trim();
        const grid = document.getElementById('galleryGrid');
        grid.innerHTML = '';

        if (!query) {
            window.location.reload();
            return;
        }

        const filtered = allImagesData.filter(img => {
            const name = img.name.toLowerCase();
            return name.includes(query) || fuzzyMatch(query, name);
        });

        if (filtered.length === 0) {
            grid.innerHTML = '<p style="grid-column: span 2; text-align: center; color: #8b949e; padding: 20px;">No matching photos found!</p>';
            return;
        }

        filtered.forEach(img => {
            const card = document.createElement('div');
            card.className = 'image-card';
            card.onclick = () => openPreview(img.url, img.name);
            card.innerHTML = `
                <img src="${img.url}" alt="${img.name}" loading="lazy">
                <div class="info"><div class="name">${img.name}</div></div>
            `;
            grid.appendChild(card);
        });
    }

    function fuzzyMatch(pattern, str) {
        pattern = pattern.toLowerCase();
        str = str.toLowerCase();
        let patternIdx = 0;
        let strIdx = 0;
        while (patternIdx < pattern.length && strIdx < str.length) {
            if (pattern[patternIdx] === str[strIdx]) { patternIdx++; }
            strIdx++;
        }
        return patternIdx === pattern.length;
    }

    // Mediafire-Style Realtime Upload
    function handleUpload(e) {
        e.preventDefault();
        uploadProcess(false);
    }

    function handleBgUpload() {
        uploadProcess(true);
    }

    function uploadProcess(isBg) {
        const name = document.getElementById('imgName').value;
        const fileInput = document.getElementById('imgFile');
        const pass = document.getElementById('adminPass').value;

        if (!fileInput.files[0]) { alert('Please select a photo!'); return; }
        if (!pass) { alert('Please enter admin password!'); return; }

        const formData = new FormData();
        formData.append('name', name);
        formData.append('file', fileInput.files[0]);
        formData.append('password', pass);
        formData.append('is_bg', isBg);

        const progressContainer = document.getElementById('progressContainer');
        const progressBar = document.getElementById('progressBar');
        progressContainer.style.display = 'block';
        progressBar.style.width = '20%';

        const xhr = new XMLHttpRequest();
        xhr.open('POST', '/api/upload', true);

        xhr.upload.onprogress = function(e) {
            if (e.lengthComputable) {
                const percent = Math.round((e.loaded / e.total) * 100);
                progressBar.style.width = percent + '%';
            }
        };

        xhr.onload = function() {
            progressContainer.style.display = 'none';
            progressBar.style.width = '0%';
            const res = JSON.parse(xhr.responseText);
            alert(res.message);
            if (res.success) { window.location.reload(); }
        };

        xhr.onerror = function() {
            progressContainer.style.display = 'none';
            alert('Upload failed due to connection error!');
        };

        xhr.send(formData);
    }

    function handleRemoveBg() {
        const pass = document.getElementById('adminPass').value;
        if (!pass) { alert('Please enter admin password!'); return; }

        const formData = new FormData();
        formData.append('password', pass);

        fetch('/api/remove_bg', { method: 'POST', body: formData })
        .then(res => res.json())
        .then(data => {
            alert(data.message);
            if (data.success) { window.location.reload(); }
        });
    }
</script>
</body>
</html>
HTML

chmod +x setup.sh
./setup.sh
echo "🎉 Setup complete! Running Flask Server..."
python main.py
