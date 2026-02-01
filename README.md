# Kevin Williams - Portfolio Website

[![AWS](https://img.shields.io/badge/AWS-Solutions%20Architect-orange)](https://www.credly.com/badges/ff8b622f-b953-4311-ab2b-b1a28bea249f/public_url)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-purple)](https://www.terraform.io/)

A cloud-native portfolio website showcasing DevOps projects, deployed on AWS using Infrastructure as Code.

## 🏗️ Architecture

- **Static Site Hosting**: S3 + CloudFront CDN
- **SSL/TLS**: AWS Certificate Manager (ACM)
- **DNS**: Route 53 (optional)
- **CI/CD**: GitHub Actions
- **Infrastructure**: Terraform

## 🚀 Deployment

### Prerequisites
- AWS Account with configured credentials
- Terraform >= 1.4.0
- AWS CLI

### Deploy Infrastructure

```bash
cd infrastructure
terraform init
terraform plan -var="bucket_name=your-unique-bucket-name"
terraform apply -var="bucket_name=your-unique-bucket-name"
```

### Manual Deployment
```bash
aws s3 sync website/ s3://your-bucket-name/ \
  --exclude ".git/*" \
  --exclude "src/*" \
  --exclude "README.md"
```

### Automated Deployment
Push to `main` branch triggers automatic deployment via GitHub Actions.

## 📂 Project Structure

```
.
├── infrastructure/          # Terraform IaC
│   ├── main.tf             # Core AWS resources (S3, CloudFront)
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Output values
│   └── terraform.tf        # Provider configuration
├── website/                # Static website files
│   ├── index.html          # Main portfolio page
│   ├── assets/             # CSS, JS, fonts
│   ├── images/             # Portfolio images
│   └── public/             # Resume and downloads
└── .github/
    └── workflows/          # CI/CD pipeline
```

## 🛠️ Technologies

- **Cloud**: AWS (S3, CloudFront, ACM, Route 53)
- **IaC**: Terraform
- **CI/CD**: GitHub Actions
- **Frontend**: HTML5, CSS3, JavaScript

## 📝 License

Design template by [HTML5 UP](https://html5up.net) under CCA 3.0 license.

## 📧 Contact

Kevin Williams - [kevin.williams2218@gmail.com](mailto:kevin.williams2218@gmail.com)

Portfolio: [\[Live Site URL\]](https://d2hp309s7roz8n.cloudfront.net)
