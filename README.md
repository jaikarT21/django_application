# **Django Multi-App Deployment with AWS VPC, Bastion Host, and CI/CD (Jenkins + AWS ECR + ALB)**

## **Overview**
This project automates the deployment of a Django application with two apps (**HelloWorld** and **MyWorld**) using **Jenkins, Docker, AWS Elastic Container Registry (ECR), and Application Load Balancer (ALB)** for path-based routing. Additionally, it incorporates **AWS VPC, a Bastion Host, and Auto Scaling** to ensure a **secure, scalable, and highly available infrastructure**.

## **Architecture**
- **Source Code**: GitHub
- **CI/CD Pipeline**: Jenkins
- **Containerization**: Docker
- **Image Registry**: AWS ECR
- **Load Balancer**: AWS ALB (Path-based routing)
- **Hosting**: AWS ECS (Fargate or EC2)
- **Networking & Security**: AWS VPC, Public & Private Subnets, NAT Gateway, Bastion Host, Security Groups

---
## **Setup & Deployment**

### **1. Configure AWS VPC & Networking**
- Create a **VPC** with **CIDR block (e.g., 10.0.0.0/16)**.
- Create **Public and Private Subnets** across two **Availability Zones**.
- Attach an **Internet Gateway (IGW)** to allow public internet access.
- Deploy a **NAT Gateway** in the public subnet to allow private subnet instances to access the internet.
- Deploy a **Bastion Host in a public subnet** to provide secure SSH access to private EC2 instances.
- Set up **Route Tables**:
  - **Public Subnet** → Internet Gateway
  - **Private Subnet** → NAT Gateway

### **2. Deploy Django Multi-App Application**
#### **Django Project Setup**
- Create a Django project with two apps:
  ```python
  urlpatterns = [
      path('helloworld/', include('hello_world.urls')),
      path('myworld/', include('my_world.urls')),
  ]
  ```
- Implement a **/health/** endpoint for ALB health checks.

#### **Dockerize the Application**
Create a **Dockerfile**:
```dockerfile
FROM python:3.9
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
EXPOSE 8000
```
Build & run locally:
```sh
docker build -t django-app .
docker run -p 8000:8000 django-app
```

---

### **3. CI/CD Pipeline with Jenkins**
#### **Jenkinsfile**
```groovy
pipeline {
    agent any

    environment {
        registryCredentials = 'ecr:us-east-1:awscreds'
        appRegistryName = '302263057737.dkr.ecr.us-east-1.amazonaws.com/djangoimg'
        djangoimgRegistry = '302263057737.dkr.ecr.us-east-1.amazonaws.com'
        cluster = "django-cluster"
        service = "djangosvc"
    }

    stages {
        stage("Fetch the Code") {
            steps {
                git branch: 'main',
                    credentialsId: 'githubid',
                    url: 'https://github.com/jaikarT21/django_application.git'
            }
        }

        stage("Build the Image") {
            steps {
                script {
                    dockerImage = docker.build("${appRegistryName}:$BUILD_NUMBER", ".")
                }
            }
        }

        stage("Push the Image to ECR") {
            steps {
                script {
                    withDockerRegistry([credentialsId: registryCredentials, url: "https://${djangoimgRegistry}"]) {
                        dockerImage.push("$BUILD_NUMBER")
                        dockerImage.push("latest")
                    }
                }
            }
        }

        stage("Remove Local Docker Images") {
            steps {
                sh 'docker rmi -f $(docker images -q) || true'
            }
        }

        stage('Deploy to AWS ECS') {
            steps {
                withAWS(credentials: 'awscreds', region: 'us-east-1') {
                    sh '''
                        set -e
                        echo " Updating ECS Service..."
                        aws ecs update-service --cluster "$cluster" --service "$service" --force-new-deployment
                        echo " Waiting for deployment to complete..."
                        aws ecs wait services-stable --cluster "$cluster" --services "$service"
                        echo " Deployment successful!"
                    '''
                }
            }
        }
    }
}
```

---
### **4. Deploy to AWS**
#### **Infrastructure Setup**
1. **Launch EC2 Instance**:
   - Install **Docker, Jenkins, and AWS CLI**.
   - Configure Jenkins with **GitHub Webhooks** for CI/CD.
2. **Set up AWS ECR**:
   - Create a **Docker repository**.
3. **Run Jenkins Pipeline**:
   - Jenkins will push Docker images to **AWS ECR**.
4. **Set Up ALB & Target Groups**:
   - `/helloworld/*` → **HelloWorld Target Group**
   - `/myworld/*` → **MyWorld Target Group**
5. **Enable Path-Based Routing in ALB**:
   - Route requests based on URL paths.

---

## **Testing**
- **Retrieve ALB DNS Name** from AWS Console.
- Access applications:
  ```
  http://<ALB-DNS>/helloworld/
  http://<ALB-DNS>/myworld/
  ```
- Verify health checks:
  ```
  http://<ALB-DNS>/helloworld/health/
  http://<ALB-DNS>/myworld/health/
  ```

---

## **Security Considerations**
- **Restrict SSH access** using **Bastion Host**.
- **Use IAM roles** for secure access to AWS services.
- **Enable ALB health checks** for monitoring application health.
- **Restrict ALB to public access** while keeping ECS instances private.

---
## **Troubleshooting**
| Issue | Solution |
|--------|-----------|
| Pipeline fails? | Check Jenkins logs. |
| Image not in ECR? | Verify AWS CLI credentials. |
| App not loading? | Check ALB routing & security groups. |
| Health check failing? | Ensure `/health/` endpoint exists. |

---

## **Conclusion**
This project **automates Django multi-app deployment** using **Jenkins, Docker, AWS ECR, and ALB** with path-based routing. The **AWS VPC with Bastion Host** ensures **security and scalability**, while **Auto Scaling and ECS** manage application availability.
