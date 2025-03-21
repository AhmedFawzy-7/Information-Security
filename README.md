# RESTful API with Flask and MySQL

## 📌 Project Overview
This project is a **RESTful API** built using **Flask** and **MySQL**, supporting user authentication with JWT and CRUD operations for managing users and products.

## 🚀 Features
- **User Authentication** using JWT
- **CRUD Operations** for Users & Products
- **Password Hashing** using Bcrypt
- **MySQL Database Integration**
- **Secure API Endpoints** with Token-based Authorization

---

## 🛠️ Installation Steps

### 1️⃣ **Clone the Repository**
```sh
 git clone https://github.com/your-repo.git
 cd your-repo
```

### 2️⃣ **Create a Virtual Environment** (Optional but Recommended)
```sh
python -m venv venv
source venv/bin/activate  # On macOS/Linux
venv\Scripts\activate    # On Windows
```

### 3️⃣ **Install Required Dependencies**
```sh
pip install -r requirements.txt
```

### 4️⃣ **Set Up MySQL Database**
Ensure **MySQL is running** and create the database:
```sql
CREATE DATABASE security_db;
```
Update the **database connection string** in `IS_task2.py`:
```python
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root@localhost/security_db'
```

### 5️⃣ **Run Database Migrations**
```sh
python
>>> from IS_task2 import db
>>> with app.app_context():
>>>     db.create_all()
>>> exit()
```

### 6️⃣ **Run the Flask App**
```sh
python IS_task2.py
```
The server should now be running at:
```
http://127.0.0.1:5000
```

---

## 🔑 API Endpoints

### **Authentication**
| Method | Endpoint      | Description |
|--------|--------------|-------------|
| POST   | `/signup`    | Register a new user |
| POST   | `/login`     | Authenticate user and return JWT token |

### **Product Management (Requires JWT Token)**
| Method | Endpoint        | Description |
|--------|----------------|-------------|
| POST   | `/products`     | Add a new product |
| GET    | `/products`     | Retrieve all products |
| GET    | `/products/{id}` | Retrieve a single product by ID |
| PUT    | `/products/{id}` | Update product details |
| DELETE | `/products/{id}` | Delete a product |

---

## 🎯 Usage with Postman
1️⃣ **Sign Up** (`POST /signup`)
```json
{
  "name": "Ahmed",
  "username": "ahmed123",
  "password": "mypassword"
}
```

2️⃣ **Login & Get Token** (`POST /login`)
```json
{
  "username": "ahmed123",
  "password": "mypassword"
}
```

3️⃣ **Add Product (Requires Token)**
- Add **Authorization Header**: `Bearer YOUR_ACCESS_TOKEN`
```json
{
  "pname": "Laptop",
  "description": "Gaming Laptop",
  "price": 1500.99,
  "stock": 10
}
```

---

## ❌ Troubleshooting
**Issue: `404 Not Found` in Postman?**
- Ensure the server is running: `python IS_task2.py`
- Check the correct URL (e.g., `http://127.0.0.1:5000/signup`)
- Verify route definitions in `IS_task2.py`

**Issue: Database Errors?**
- Ensure MySQL is running and database is created: `CREATE DATABASE security_db;`
- Check the connection string in `app.config['SQLALCHEMY_DATABASE_URI']`

---

## 🏆 Credits
Developed by **Ahmed** 🚀



