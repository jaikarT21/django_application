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
- Set up **Rout
