# Django Multi-App Deployment with CI/CD (Jenkins + AWS ECR + ALB)

## Overview
This project automates the deployment of a Django application with two apps (**HelloWorld** and **MyWorld**) using **Jenkins**, **Docker**, **AWS Elastic Container Registry (ECR)**, and **Application Load Balancer (ALB)** for path-based routing.

## Architecture
- **Source Code:** GitHub  
- **CI/CD Pipeline:** Jenkins  
- **Containerization:** Docker  
- **Image Registry:** AWS ECR  
- **Load Balancer:** AWS ALB (Path-based routing)  
- **Hosting:** AWS EC2  

---

## Setup & Deployment

### 1. Configure Django Application
- Create Django project and apps (`helloworld`, `myworld`).
- Define `urls.py` for path-based routing:
  ```python
  urlpatterns = [
      path('helloworld/', include('hello_world.urls')),
      path('myworld/', include('my_world.urls')),
  ]
  ```
- Create `/health/` endpoint for ALB health checks.

### 2. Dockerize the Application
- Create a `Dockerfile`:
  ```dockerfile
  FROM python:3.9
  WORKDIR /app
  COPY requirements.txt .
  RUN pip install -r requirements.txt
  COPY . .
  CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
  EXPOSE 8000
  ```
- Build & run locally:
  ```sh
  docker build -t django-app .
  docker run -p 8000:8000 django-app
  ```

### 3. CI/CD Pipeline with Jenkins
Jenkinsfile:
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
                        echo "🚀 Updating ECS Service..."
                        aws ecs update-service --cluster "$cluster" --service "$service" --force-new-deployment
                        
                        echo "⏳ Waiting for deployment to complete..."
                        aws ecs wait services-stable --cluster "$cluster" --services "$service"
                        echo "✅ Deployment successful!"
                    '''
                }
            }
        }
    }
}


```

### 4. Deploy to AWS
1. **Launch EC2 Instance:** Install Docker & Jenkins.
2. **Set up AWS ECR:** Create a repository.
3. **Run Jenkins Pipeline:** Pushes Docker image to ECR.
4. **Set Up ALB & Target Groups:**
   - `/helloworld/*` → **HelloWorld Target Group**
   - `/myworld/*` → **MyWorld Target Group**

---

## Testing
- Get ALB DNS Name from AWS Console.
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

## Troubleshooting
- **Pipeline fails?** Check Jenkins logs.
- **Image not in ECR?** Verify AWS CLI credentials.
- **App not loading?** Check ALB routing & security groups.
- **Health check failing?** Ensure `/health/` endpoint exists.

---

## Conclusion
automates Django application deployment using Jenkins, Docker, AWS ECR, and ALB with path-based routing for multiple apps. 🚀

