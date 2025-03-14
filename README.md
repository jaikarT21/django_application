# **Django Multi-App Deployment on AWS with Docker & ALB**

## **Overview**
This guide explains how to deploy a Django project with two applications (**HelloWorld** and **MyWorld**) using Docker on AWS EC2. We will configure an **Application Load Balancer (ALB)** with path-based routing to serve the applications on the same port but different contexts.

## **Project Structure**
```
my_django_project/
|-- Dockerfile
|-- docker-compose.yml
|-- hello_world/  # Django app 1
|-- my_world/     # Django app 2
|-- manage.py
|-- requirements.txt
```

---

## **Step 1: Setup Django Applications**
### **1.1 Install Django & Create Project**
```sh
pip install django
django-admin startproject my_django_project
cd my_django_project
```
### **1.2 Create Two Django Apps**
```sh
python manage.py startapp hello_world
python manage.py startapp my_world
```

### **1.3 Configure URLs in `my_django_project/urls.py`**
```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('helloworld/', include('hello_world.urls')),
    path('myworld/', include('my_world.urls')),
]
```

### **1.4 Run Migrations & Start Server Locally**
```sh
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

---

## **Step 2: Dockerize the Django Application**

### **2.1 Create `Dockerfile`**
```dockerfile
FROM python:3.9
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
EXPOSE 8000
```


## **Step 3: Deploy to AWS EC2**

### **3.1 Launch EC2 Instance**
- Go to **AWS EC2** → Launch **Ubuntu 22.04** instance.
- Choose a **security group** that allows HTTP (80) & SSH (22).
- Security Group:
Allow port 22 (SSH) for your IP.
Allow port 8000 (HTTP) from anywhere (0.0.0.0/0) for testing.
- Connect via SSH:
  ```sh
  ssh -i my-key.pem ubuntu@your-ec2-ip
  ```

### **3.2 Install Docker on EC2**
```sh
sudo apt update && sudo apt install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
```


---

## **Step 4: Configure AWS Application Load Balancer (ALB)**

### **4.1 Create ALB & Target Groups**
- Navigate to **AWS EC2 → Load Balancers**.
- Click **Create Load Balancer** → **Application Load Balancer**.
- Choose:
  - **Listeners:** HTTP (80)
  - **Target Groups:** Create two target groups:
    - **helloworld-target-group** (for HelloWorld app)
    - **myworld-target-group** (for MyWorld app)


### **4.2 Register EC2 Instances to Target Groups**
- Go to **Target Groups**.
- Go to AWS Console → EC2 → Target Groups → Create Target Group
Configure:
Target Type: Instance
Protocol: HTTP
Port: 8000
Health Check Path: /helloworld/
Create Target Group
Register Targets
Select your EC2 instance and Register Targets.
- Select **helloworld-target-group** → Register Targets → Select EC2 instance → Save.
- Repeat for **myworld-target-group**.

### **4.3 Configure Listener Rules**
- Navigate to **AWS Load Balancer → Listeners → View/Edit Rules**.
- Add **Path-Based Routing Rules**:
-  Step 2: Add Path-Based Routing Rules
Click on "Add rule" → Insert Rule.
Click "+ Add condition" → Path.
In the Path field, enter:
/helloworld/* → This rule applies to all requests starting with /helloworld/.
Click "+ Add action" → Forward to...
Select HelloWorld Target Group.
Click Save Rule

  - If path is `/helloworld/*` → Forward to **helloworld-target-group**.
  - If path is `/myworld/*` → Forward to **myworld-target-group**.
- Save the rules.

 ### Example Listener Rule Priorities:
 ## Priority in Listener Rules (AWS Application Load Balancer)
In AWS Application Load Balancer (ALB), priority in listener rules determines the order in which rules are evaluated.

Priority	Condition (Path)	Action (Target Group)
1	/helloworld/*	Forward to HelloWorld TG
2	/myworld/*	Forward to MyWorld TG
Default	* (any other request)	Return 404 or another target

---

## **Step 5: Configure Health Checks**
- Go to **Target Groups → Health Checks**.
- Set:
  - Path: `/health/`
  - Interval: `30 sec`
  - Unhealthy threshold: `2`

  
- Ensure Django has a `/health/` endpoint:
  ```python
  from django.http import JsonResponse

  def health_check(request):
      return JsonResponse({"status": "healthy"})
  ```
  Add this view to **both apps' `urls.py`**:
  ```python
  from django.urls import path
  from .views import health_check
  urlpatterns = [
      path('health/', health_check),
  ]
  ```

---


## **Step 7: Test the Deployment**
1. Find the **ALB DNS Name** from **AWS Console → Load Balancers**.
2. Test the applications:
   - `http://your-alb-dns-name/helloworld/` → Should serve **HelloWorld** app.
   - `http://your-alb-dns-name/myworld/` → Should serve **MyWorld** app.

---

## **Troubleshooting**
- **App not loading?** Check:
  - Django is running: `docker ps`
  - ALB target groups have **healthy** instances.
  - Security group allows **port 8000** inbound.
- **Health check failing?** Ensure `/health/` endpoint is correct.

---

## **Conclusion**
successfully deployed a Django project with multiple applications on AWS using Docker, ALB, and EC2! 🚀

