from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root@localhost/security_db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = os.getenv("SECRET_KEY", "mysecretkey")

# Database setup
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
jwt = JWTManager(app)

# Models
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    username = db.Column(db.String(100), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)

class Product(db.Model):
    pid = db.Column(db.Integer, primary_key=True)
    pname = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    price = db.Column(db.Float, nullable=False)
    stock = db.Column(db.Integer, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

with app.app_context():
    db.create_all()

# Routes
@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    hashed_password = bcrypt.generate_password_hash(data['password']).decode('utf-8')
    new_user = User(name=data['name'], username=data['username'], password=hashed_password)
    db.session.add(new_user)
    db.session.commit()
    return jsonify({'message': 'User registered successfully'}), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    user = User.query.filter_by(username=data['username']).first()
    if user and bcrypt.check_password_hash(user.password, data['password']):
        token = create_access_token(identity=user.username, expires_delta=timedelta(minutes=10))
        return jsonify({'access_token': token}), 200
    return jsonify({'message': 'Invalid credentials'}), 401

@app.route('/products', methods=['POST'])
@jwt_required()
def add_product():
    data = request.get_json()
    new_product = Product(**data)
    db.session.add(new_product)
    db.session.commit()
    return jsonify({'message': 'Product added successfully'}), 201

@app.route('/products', methods=['GET'])
def get_products():
    products = Product.query.all()
    return jsonify([{
        'pid': p.pid,
        'pname': p.pname,
        'description': p.description,
        'price': p.price,
        'stock': p.stock,
        'created_at': p.created_at
    } for p in products]), 200

@app.route('/products/<int:pid>', methods=['GET'])
def get_product(pid):
    product = Product.query.get(pid)
    if not product:
        return jsonify({'message': 'Product not found'}), 404
    return jsonify({
        'pid': product.pid,
        'pname': product.pname,
        'description': product.description,
        'price': product.price,
        'stock': product.stock,
        'created_at': product.created_at
    }), 200

@app.route('/products/<int:pid>', methods=['PUT'])
@jwt_required()
def update_product(pid):
    data = request.get_json()
    product = Product.query.get(pid)
    if not product:
        return jsonify({'message': 'Product not found'}), 404
    for key, value in data.items():
        setattr(product, key, value)
    db.session.commit()
    return jsonify({'message': 'Product updated successfully'}), 200

@app.route('/products/<int:pid>', methods=['DELETE'])
@jwt_required()
def delete_product(pid):
    product = Product.query.get(pid)
    if not product:
        return jsonify({'message': 'Product not found'}), 404
    db.session.delete(product)
    db.session.commit()
    return jsonify({'message': 'Product deleted successfully'}), 200

if __name__ == '__main__':
    app.run(debug=True)
