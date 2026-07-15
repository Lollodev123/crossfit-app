#!/usr/bin/env python3
from flask import Flask, request, jsonify
import json, os

app = Flask(__name__)

DATA_FILE = '/var/www/crossfit/data.json'
API_KEY   = 'CF_SECRET_KEY_PLACEHOLDER'   # replaced by setup.sh

def auth():
    return request.headers.get('X-Key') == API_KEY

@app.route('/api/data', methods=['GET'])
def get_data():
    if not auth():
        return jsonify({'error': 'Unauthorized'}), 401
    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE, 'r') as f:
                return jsonify(json.load(f))
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    return jsonify({'logs': [], 'notes': [], 'plan': {}})

@app.route('/api/data', methods=['POST'])
def save_data():
    if not auth():
        return jsonify({'error': 'Unauthorized'}), 401
    try:
        data = request.get_json(force=True)
        with open(DATA_FILE, 'w') as f:
            json.dump(data, f, indent=2)
        return jsonify({'ok': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/ping', methods=['GET'])
def ping():
    return jsonify({'ok': True})

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=3847, debug=False)
